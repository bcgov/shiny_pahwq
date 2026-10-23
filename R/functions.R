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

# The marine area containing the location, as a one-row data frame, or NULL.
# With `nearest = TRUE`, the nearest area within 25 km is used instead, as
# pahwq does for the Kd model.
marine_area_at <- function(lat, lon, nearest = FALSE) {
  if (length(c(lat, lon)) != 2 || anyNA(c(lat, lon))) {
    return(NULL)
  }
  pt <- sf::st_sfc(sf::st_point(c(lon, lat)), crs = 4326)
  areas <- marine_areas()
  idx <- sf::st_intersects(pt, areas)[[1]]
  if (!length(idx) && nearest) {
    idx <- sf::st_nearest_feature(pt, areas)
    if (as.numeric(sf::st_distance(pt, areas[idx, ])) > 25000) {
      idx <- integer()
    }
  }
  if (!length(idx)) {
    return(NULL)
  }
  sf::st_drop_geometry(areas[idx[1], ])
}

# Nearshore (turbid) marine water defaults to 1 cm; offshore (clear) marine
# water has no default (#33)
default_depth <- function(aq_env, water_type) {
  if (aq_env != "marine") {
    return(0.25)
  }
  if (identical(water_type, "turbid")) 0.01 else NA_real_
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

marine_areas_pal <- function() {
  leaflet::colorFactor(c("#2c7fb8", "#a6611a"), levels = c("clear", "turbid"))
}

add_marine_areas <- function(map, group) {
  pal <- marine_areas_pal()
  leaflet::addPolygons(
    map,
    data = marine_areas(),
    group = group,
    color = ~ pal(water_type),
    weight = 1,
    fillOpacity = 0.2,
    label = ~ paste0(ecoregion, " (", water_type, " water)")
  )
}

add_marine_legend <- function(map, group, layerId) {
  leaflet::addLegend(
    map,
    pal = marine_areas_pal(),
    values = c("clear", "turbid"),
    title = "Marine water type",
    position = "bottomright",
    group = group,
    layerId = layerId
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
