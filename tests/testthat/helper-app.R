local_app <- function(..., auth = FALSE, env = parent.frame()) {
  app <- shinytest2::AppDriver$new(
    function() {
      Sys.setenv(PACWQ_USER = "user", PACWQ_PASSWORD = "password")
      library(pacwq.shiny)
      # shinytest2 sets warn = 2 when testing a dev package from its own
      # directory, which turns pahwq's warnings into fatal app errors
      options(warn = 1)
      # As in deployed apps, which hide unhandled error messages
      options(shiny.sanitize.errors = TRUE)
      # Instead of the elevation web service: the freshwater test site's
      # elevation (the app runs in its own process, so `sites` isn't available)
      options(pacwq.shiny.elevation = function(lon, lat) 515)
      pacwq.shiny:::run_app(auth = auth)
    },
    timeout = 30000,
    load_timeout = 60000,
    ...
  )
  withr::defer(app$stop(), envir = env)
  app
}

sites <- list(
  freshwater = list(lat = 52.60453, lon = -105.28278, elev_m = 515),
  marine = list(lat = 49.15085, lon = -125.91427, elev_m = 0),
  # Just outside the Strait of Georgia marine Kd area
  nearshore = list(lat = 49.28, lon = -123.12, elev_m = 0),
  # No marine Kd model data in winter
  arctic_basin = list(lat = 78.135, lon = -126.252, elev_m = 0),
  # Low-confidence (VPFTIME) marine Kd model in winter
  labrador_shelf = list(lat = 53.673, lon = -56.187, elev_m = 0)
)

# Setting lat/lon triggers an elevation lookup, so wait for it to finish before
# overwriting elevation with a known value.
set_site <- function(app, site = c("freshwater", "marine")) {
  site <- sites[[match.arg(site)]]
  app$set_inputs(lat = site$lat, lon = site$lon, wait_ = FALSE)
  app$wait_for_idle()
  app$set_inputs(elev_m = site$elev_m, date = "2024-06-21", wait_ = FALSE)
  app$wait_for_idle()
  invisible(app)
}

show_tab <- function(app, name) {
  app$click(selector = sprintf("a[data-value='%s']", name))
  app$wait_for_idle()
  invisible(app)
}

output_number <- function(app, id) {
  out <- app$get_value(output = id)
  as.numeric(regmatches(out, regexpr("-?[0-9.]+(e-?[0-9]+)?", out)))
}

output_error <- function(app, id) {
  out <- app$get_value(output = id)
  if (is.list(out)) out$message else NULL
}

# Independent calculation with pahwq, using the app's default TUV settings
expected_results <- function(
  chemical,
  site = c("freshwater", "marine"),
  depth_m = 0.01,
  DOC = NULL,
  Kd_ref = NULL,
  Kd_wvl = NULL,
  multiplier = 2
) {
  aq_env <- match.arg(site)
  if (!is.null(Kd_ref)) {
    Kd_wvl <- Kd_wvl %||% if (aq_env == "marine") 375 else 305
  }
  site <- sites[[aq_env]]
  local_tuv_dir()
  irrad <- pahwq::tuv(
    depth_m = depth_m,
    lat = site$lat,
    lon = site$lon,
    elev_m = site$elev_m,
    date = as.Date("2024-06-21"),
    tzone = -8,
    DOC = DOC,
    aq_env = aq_env,
    Kd_ref = Kd_ref,
    Kd_wvl = Kd_wvl,
    tstart = 0,
    tstop = 23,
    tsteps = 24,
    wvl_start = 280,
    wvl_end = 500,
    quiet = TRUE
  )
  pabs <- pahwq::p_abs(irrad, chemical, time_multiplier = multiplier)
  list(
    irrad = irrad,
    pabs = round(pabs, 3),
    photo_bench = round(pahwq::phototoxic_benchmark(pabs, pah = chemical), 3),
    photo_cwqg = round(pahwq::phototoxic_cwqg(pabs, pah = chemical), 3)
  )
}
