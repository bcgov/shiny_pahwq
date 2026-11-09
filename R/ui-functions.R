chem_input <- function(id) {
  selectInput(
    id,
    "Select a chemical:",
    choices = c(
      "Choose a chemical" = "",
      chemical_list()
    ),
    width = "100%"
  )
}

aq_env_input <- function(id) {
  radioButtons(
    id,
    "Aquatic environment:",
    choices = c("Freshwater" = "freshwater", "Marine" = "marine"),
    inline = TRUE
  )
}

doc_input <- function(id, label_prefix = NULL) {
  numericInput(
    id,
    HTML(add_prefix("DOC (g/m<sup>3</sup>)", label_prefix)),
    value = NA_real_,
    min = doc_range()[1],
    max = doc_range()[2]
  )
}

depth_input <- function(id, label_prefix = NULL) {
  numericInput(
    id,
    input_tooltip(
      add_prefix("Water Depth (m)", label_prefix),
      "Depth at which light exposure is calculated. Defaults to 0.01 m."
    ),
    value = 0.01
  )
}

kd_input <- function(id, label_prefix = NULL) {
  numericInput(
    id,
    input_tooltip(
      HTML(add_prefix("K<sub>d</sub>(ref) (m<sup>-1</sup>)", label_prefix)),
      "Light attenuation coefficient at reference wavelength. In freshwater, it can be set directly, or calculated from DOC. In marine water, it is calculated from the ecoregion model for the location and date, unless set here."
    ),
    value = NA_real_
  )
}

kd_model_card <- function(kd_model, kd_ref_set = FALSE, sk_set = FALSE) {
  notes <- c(
    if (kd_ref_set) {
      "K<sub>d</sub>(ref) was set by the user, overriding the model."
    },
    if (sk_set) {
      "S<sub>k</sub> was set by the user, overriding the model."
    },
    if (kd_model$dist_km > 0) {
      sprintf(
        "The location is outside the marine model areas, so the nearest area (%s km away) is used.",
        round(kd_model$dist_km, 1)
      )
    },
    if (kd_model$vpf_area || kd_model$vpf_time) {
      sprintf(
        "Low confidence: the model was derived from data with fewer than 10%% valid pixels %s.",
        paste(
          c(
            "across the area"[kd_model$vpf_area],
            "over time"[kd_model$vpf_time]
          ),
          collapse = " and "
        )
      )
    }
  )

  card(
    fill = FALSE,
    # Otherwise it shrinks to nothing in the page's fillable main area
    class = "flex-shrink-0",
    card_header("Marine light attenuation model"),
    card_body(
      p(HTML(sprintf(
        "<b>%s</b> ecoregion, %s water, %s. K<sub>d</sub>(%s) = %s m<sup>-1</sup>, S<sub>k</sub> = %s nm<sup>-1</sup>, R<sup>2</sup> = %s.",
        kd_model$ecoregion,
        kd_model$water_type,
        kd_model$season,
        kd_model$Kd_wvl,
        signif(kd_model$Kd_ref, 4),
        signif(kd_model$Sk, 3),
        round(kd_model$r2, 2)
      ))),
      if (length(notes)) {
        tags$ul(lapply(notes, \(x) tags$li(HTML(x))))
      }
    )
  )
}

add_prefix <- function(x, prefix) {
  glue::glue(paste0("{prefix}", x), .transformer = null_transformer())
}

null_transformer <- function(str = "") {
  function(text, envir) {
    out <- glue::identity_transformer(text, envir)
    if (is.null(out)) {
      return(str)
    }
    paste0(out, " ")
  }
}

input_tooltip <- function(label, tooltip) {
  shiny::span(
    label,
    bslib::tooltip(
      bsicons::bs_icon("question-circle"),
      tooltip,
      placement = "right"
    )
  )
}

# The chemical, aquatic environment and guideline boxes of a calculator module
result_boxes <- function(ns) {
  tagList(
    layout_columns(
      fill = FALSE,
      card(
        chem_input(ns("chemical")),
        aq_env_input(ns("aq_env")),
        class = "select-overflowable",
        wrapper = function(...) card_body(..., class = "select-overflowable")
      ),
      value_box(
        title = htmlOutput(ns("narc_bench_title")),
        value = htmlOutput(ns("narc_bench")),
        showcase = tooltip(
          bsicons::bs_icon("bug-fill"),
          "You must select a chemical"
        )
      ),
      value_box(
        title = htmlOutput(ns("narc_cwqg_title")),
        value = htmlOutput(ns("narc_cwqg")),
        showcase = tooltip(
          bsicons::bs_icon("bug-fill"),
          "You must select a chemical"
        )
      ),
    ),
    layout_columns(
      fill = FALSE,
      value_box(
        title = p(HTML("P<sub>abs</sub>")),
        value = htmlOutput(ns("pabs")),
        showcase = tooltip(
          bsicons::bs_icon("sun"),
          "You must select a chemical and fill in the necessary parameters on the left to run the TUV model"
        )
      ),
      value_box(
        title = htmlOutput(ns("photo_bench_title")),
        value = htmlOutput(ns("photo_bench")),
        showcase = tooltip(
          bsicons::bs_icon("bug"),
          "You must select a chemical and fill in the necessary parameters on the left to run the TUV model"
        )
      ),
      value_box(
        title = htmlOutput(ns("photo_cwqg_title")),
        value = htmlOutput(ns("photo_cwqg")),
        showcase = tooltip(
          bsicons::bs_icon("bug"),
          "You must select a chemical and fill in the necessary parameters on the left to run the TUV model"
        )
      )
    )
  )
}

multi_tox_panel <- function(ns) {
  nav_panel(
    "Multi-Chemical Toxicity",
    uiOutput(ns("multi_tox_download_btn")),
    DT::DTOutput(ns("multi_tox"))
  )
}

# Name, label and default of the settings shown on the TU/HI tab when they differ
# from their defaults. Those with a NULL default are looked up by pacwq if blank,
# and the rest are required.
tu_hi_default_settings <- list(
  list("time_multiplier", "TUV results multiplier", 2),
  list("tzone", "Timezone (hrs)", 0),
  list("Sk", "S<sub>k</sub> (nm<sup>-1</sup>)", NULL),
  list("tstart", "Start time (h)", 0),
  list("tstop", "Stop time (h)", 23),
  list("tsteps", "Time steps", 24),
  list("wvl_start", "Start wavelength (nm)", 280),
  list("wvl_end", "End wavelength (nm)", 500),
  list("o3_tc", "Ozone column (DU)", NULL),
  list("tauaer", "Aerosol optical depth", NULL)
)

# Labels (which can contain HTML) and values for the settings in use on the TU/HI
# tab, from `advanced_settings()`. Anything required but missing is "Not set",
# and other settings are only included if they differ from their defaults.
tu_hi_settings_items <- function(settings) {
  value <- function(x, unit = "") {
    if (is.null(x)) "Not set" else paste0(format(x), unit)
  }
  location <- if (!is.null(settings$lat) && !is.null(settings$lon)) {
    paste0(round(settings$lat, 4), ", ", round(settings$lon, 4))
  }
  marine <- identical(settings$aq_env, "marine")
  kd_ref <- !is.null(settings$Kd_ref)

  items <- c(
    list(
      "Location (latitude, longitude)" = value(location),
      "Elevation" = value(settings$elev_m, " m"),
      "Aquatic environment" = tools::toTitleCase(settings$aq_env),
      "Date" = value(settings$date),
      "Water depth" = value(settings$depth_m, " m")
    ),
    if (marine && !kd_ref) {
      list("Light attenuation" = "Marine ecoregion model")
    },
    if (!marine && (!kd_ref || !is.null(settings$DOC))) {
      list("DOC (g/m<sup>3</sup>)" = value(settings$DOC))
    },
    if (kd_ref) {
      list(
        "K<sub>d</sub>(ref) (m<sup>-1</sup>)" = value(settings$Kd_ref),
        "K<sub>d</sub>(ref) wavelength" = value(settings$Kd_wvl, " nm")
      )
    }
  )

  for (x in tu_hi_default_settings) {
    if (!identical(as.numeric(settings[[x[[1]]]]), as.numeric(x[[3]]))) {
      items[[x[[2]]]] <- value(settings[[x[[1]]]])
    }
  }
  items
}

# Labels of the required settings left blank, from `advanced_settings()`. This
# excludes those with their own message when the TUV run is started.
missing_tu_hi_settings <- function(settings) {
  required <- Filter(\(x) !is.null(x[[3]]), tu_hi_default_settings)
  blank <- Filter(\(x) is.null(settings[[x[[1]]]]), required)
  c(
    if (is.null(settings$date)) "Date",
    vapply(blank, \(x) x[[2]], character(1))
  )
}

tu_hi_settings_list <- function(items) {
  tags$dl(
    class = "tu-hi-settings",
    unname(Map(
      \(label, value) div(tags$dt(HTML(label)), tags$dd(value)),
      names(items),
      items
    ))
  )
}

# A sum on the TU/HI tab, to 3 significant figures without scientific notation
format_sum <- function(x) {
  format(signif(x, 3), scientific = FALSE, drop0trailing = TRUE, trim = TRUE)
}

tu_hi_results_table <- function(pacs) {
  labels <- c(
    pac_name = "PAC",
    concentration_ug_L = "Concentration (\u00b5g/L)",
    narcotic_benchmark = "Short-term narcotic guideline (\u00b5g/L)",
    narcotic_cwqg = "Long-term narcotic guideline (\u00b5g/L)",
    pabs = "Pabs",
    phototoxic_benchmark = "Short-term phototoxic guideline (\u00b5g/L)",
    phototoxic_cwqg = "Long-term phototoxic guideline (\u00b5g/L)",
    tu_narcotic = "Narcotic TU",
    tu_phototoxic = "Phototoxic TU",
    hi_narcotic = "Narcotic HI",
    hi_phototoxic = "Phototoxic HI"
  )
  pacs <- pacs[names(labels)]
  names(pacs) <- labels
  DT::datatable(
    pacs,
    rownames = FALSE,
    options = list(
      paging = FALSE,
      searching = FALSE,
      info = FALSE,
      scrollX = TRUE
    )
  ) |>
    DT::formatSignif(columns = unname(labels[-1]), digits = 3)
}

# A table of representative guidelines, from a CSV in pacwq's
# `doc-guideline-lookup` directory
guideline_table <- function(path) {
  DT::datatable(utils::read.csv(path), filter = "top") |>
    DT::formatRound(
      columns = c(
        "short_term_narcotic_guideline",
        "long_term_narcotic_guideline",
        "short_term_phototoxic_guideline",
        "long_term_phototoxic_guideline"
      ),
      digits = 3
    ) |>
    DT::formatRound(columns = "pabs", digits = 5)
}

version_info <- function() {
  tags$p(
    class = "text-muted",
    paste0("Calculator version: ", utils::packageVersion("pacwq.shiny")),
    tags$br(),
    paste0("pacwq package version: ", utils::packageVersion("pacwq"))
  )
}
