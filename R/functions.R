# Homologue groups that combine two parents (e.g. C1-Phenanthrenes/Anthracenes)
# have one row per parent with identical properties and spectra, so the first
# is used for the group.
chemical_list <- function() {
  pacs <- pac_list(app_only = TRUE)
  pacs <- pacs[!duplicated(pacs$pac_name), ]
  pacs <- pacs[order(tolower(pacs$pac_name)), ]
  stats::setNames(pacs$pac_id, pacs$pac_name)
}

multi_tox_table <- function(tuv_res, time_multiplier) {
  chems <- chemical_list()
  ret <- pb_multi(tuv_res, unname(chems), time_multiplier = time_multiplier)
  ret$pac_id <- names(chems)[match(ret$pac_id, chems)]
  names(ret)[names(ret) == "pac_id"] <- "pac"
  ret
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
# pacwq does for the Kd model.
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

site_elevation <- function(lat, lon, marine) {
  if (marine) {
    return(0)
  }
  if (length(c(lat, lon)) != 2 || anyNA(c(lat, lon))) {
    return(NA_real_)
  }
  # The lookup can be replaced (e.g., in tests) with the option
  # `pacwq.shiny.elevation`, a function of `lon` and `lat`
  lookup <- getOption("pacwq.shiny.elevation", get_elevation)
  tryCatch(
    lookup(lon, lat),
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

# TUs and HIs for concentrations in `chemical_list()` order. PACs with no
# concentration (NA) are left out, while a concentration of 0 is kept.
tu_hi_sample <- function(concentrations, tuv_res, time_multiplier) {
  tu_hi(
    data.frame(
      pac = names(chemical_list()),
      concentration_ug_L = concentrations
    )[!is.na(concentrations), ],
    tuv_res,
    time_multiplier = time_multiplier
  )
}

# Settings from `advanced_settings()`, with the values used in the TUV run for
# those left blank and looked up or calculated by pacwq. `params` is from
# `tuv_run_params()`.
settings_used <- function(settings, params) {
  param <- function(name) params[[grep(name, names(params))[1]]]
  kd <- as.numeric(strsplit(trimws(param("^a,b,c")), " +")[[1]])
  settings$Kd_ref <- kd[1]
  settings$Sk <- kd[2]
  settings$Kd_wvl <- kd[3]
  settings$o3_tc <- as.numeric(param("^o3_tc"))
  settings$tauaer <- as.numeric(param("^tauaer"))
  settings
}

# One row per PAC in the results and a `Total` row, with the settings (from
# `settings_used()`) and marine Kd model, if any, as constant columns
tu_hi_export <- function(results, settings, kd_model = NULL) {
  pacs <- attr(results, "pacs")
  # `read_concentrations()` needs `pac`, so that the file can be uploaded again
  names(pacs)[names(pacs) == "pac_name"] <- "pac"
  total <- pacs[1, ]
  total[] <- NA
  total$pac <- "Total"
  total[names(results)] <- as.list(as.data.frame(results))
  out <- rbind(pacs, total)

  settings$date <- format(settings$date)
  settings[lengths(settings) == 0] <- NA
  out <- cbind(out, settings, row.names = NULL)

  if (is.null(kd_model)) {
    return(out)
  }
  kd_model$area <- NULL
  names(kd_model) <- paste0("marine_kd_model_", names(kd_model))
  cbind(out, kd_model, row.names = NULL)
}

concentrations_template <- function() {
  data.frame(pac = names(chemical_list()), concentration_ug_L = NA_real_)
}

# Reads a CSV of concentrations for the TU/HI tab. Returns a list with `values`
# (in `chemical_list()` order, or NULL if the file can't be used), and `errors`
# and `notices` to show the user.
read_concentrations <- function(path) {
  rejected <- function(...) {
    list(values = NULL, errors = c(...), notices = character())
  }

  # A warning can mean that rows were lost, such as with an unclosed quote
  dat <- tryCatch(
    utils::read.csv(
      # Without skipNul, a line is cut off at a null byte
      text = readLines(path, warn = FALSE, skipNul = TRUE),
      colClasses = "character",
      check.names = FALSE,
      blank.lines.skip = FALSE
    ),
    error = function(e) NULL,
    warning = function(w) NULL
  )
  if (is.null(dat)) {
    return(rejected("The file could not be read as a CSV file."))
  }

  missing_cols <- setdiff(c("pac", "concentration_ug_L"), names(dat))
  if (length(missing_cols)) {
    return(rejected(paste0(
      "The file is missing these columns: ",
      paste(missing_cols, collapse = ", "),
      "."
    )))
  }

  if (!all(validUTF8(c(dat$pac, dat$concentration_ug_L)))) {
    return(rejected("The file could not be read as a CSV file."))
  }

  file_row <- seq_len(nrow(dat)) + 1
  name <- trimws(dat$pac)
  conc <- trimws(dat$concentration_ug_L)
  blank <- is.na(conc) | conc == ""
  value <- suppressWarnings(as.numeric(conc))
  pac <- match_pac(name)

  list_rows <- function(rows) {
    paste0("row ", file_row[rows], " (", conc[rows], ")", collapse = ", ")
  }
  repeated <- !is.na(pac) & (duplicated(pac) | duplicated(pac, fromLast = TRUE))
  errors <- c(
    if (any(!blank & is.na(value))) {
      paste0(
        "Concentrations must be numbers: ",
        list_rows(!blank & is.na(value)),
        "."
      )
    },
    if (any(!blank & !is.na(value) & value < 0)) {
      paste0(
        "Concentrations can't be negative: ",
        list_rows(!blank & !is.na(value) & value < 0),
        "."
      )
    },
    if (any(repeated)) {
      paste0(
        "Each PAC or homologue group can only be included once: ",
        paste(unique(pac[repeated]), collapse = ", "),
        ". If its compounds were reported separately, add their concentrations together and enter the total."
      )
    }
  )
  if (length(errors)) {
    return(rejected(errors))
  }

  pacs <- names(chemical_list())
  has_value <- !is.na(value)
  unknown <- is.na(pac) & has_value
  not_shown <- !is.na(pac) & !pac %in% pacs & has_value
  values <- value[match(pacs, pac)]
  no_name <- is.na(name) | name == ""
  name[no_name] <- paste0("row ", file_row[no_name], " (no name)")
  if (all(is.na(values)) && !any(unknown | not_shown)) {
    return(rejected("The file has no concentrations."))
  }

  list(
    values = values,
    errors = character(),
    notices = c(
      if (any(unknown)) {
        paste0(
          "These names weren't recognized, so their concentrations aren't counted: ",
          paste(name[unknown], collapse = ", "),
          "."
        )
      },
      if (any(not_shown)) {
        paste0(
          "These PACs aren't included in this calculator, so their concentrations aren't counted: ",
          paste(pac[not_shown], collapse = ", "),
          "."
        )
      }
    )
  )
}

local_tuv_dir <- function(env = parent.frame()) {
  tdir <- file.path(
    withr::local_tempdir(.local_envir = env),
    "pacwq",
    "tuv_data"
  )
  withr::local_options("pacwq.tuv_data_dir" = tdir, .local_envir = env)
  pacwq:::setup_tuv_dir()
}
