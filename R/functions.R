chemical_list <- function() {
  ma_chems <- tolower(sort(unique(pahwq:::molar_absorption$chemical)))
  narc_bench_chems <- tolower(sort(unique(pahwq:::nlc50_lookup$chemical)))
  tools::toTitleCase(intersect(ma_chems, narc_bench_chems))
}

marine_areas <- local({
  areas <- NULL
  function() {
    if (is.null(areas)) {
      areas <<- marine_kd_areas()
    }
    areas
  }
})

in_marine_area <- function(lat, lon) {
  pt <- sf::st_sfc(sf::st_point(c(lon, lat)), crs = 4326)
  lengths(sf::st_intersects(pt, marine_areas())) > 0
}

site_elevation <- function(lat, lon, marine) {
  if (marine) {
    return(0)
  }
  if (length(c(lat, lon)) != 2 || anyNA(c(lat, lon))) {
    return(NA_real_)
  }
  tryCatch(
    get_elevation(lon, lat),
    error = function(e) {
      return(NA_real_)
    }
  )
}

# Add the marine Kd model, if any, as constant columns
tuv_results_export <- function(x) {
  kd_model <- attr(x, "kd_model")
  x <- as.data.frame(x)
  if (is.null(kd_model)) {
    return(x)
  }
  kd_model$area <- NULL
  names(kd_model) <- paste0("marine_kd_model_", names(kd_model))
  cbind(x, kd_model, row.names = NULL)
}

local_tuv_dir <- function(env = parent.frame()) {
  tdir <- file.path(
    withr::local_tempdir(.local_envir = env),
    "pahwq",
    "tuv_data"
  )
  withr::local_options("pahwq.tuv_data_dir" = tdir, .local_envir = env)
  pahwq:::setup_tuv_dir()
}
