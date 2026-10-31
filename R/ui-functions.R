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

kd_model_card <- function(kd_model, kd_ref_set = FALSE) {
  notes <- c(
    if (kd_ref_set) {
      "K<sub>d</sub>(ref) was set by the user, overriding the model."
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
