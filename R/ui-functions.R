chem_input <- function(id) {
  selectInput(
    id,
    "Select a chemical:",
    choices = c(
      "Choose a chemical" = "",
      chemical_list()
    )
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
    min = suppressWarnings(pahwq:::doc_valid_range(-Inf)),
    max = suppressWarnings(pahwq:::doc_valid_range(Inf))
  )
}

depth_input <- function(id, label_prefix = NULL) {
  numericInput(
    id,
    input_tooltip(
      add_prefix("Water Depth (m)", label_prefix),
      "Set depth to 0.01m for marine environments"
    ),
    value = 0.25
  )
}

kd_input <- function(id, label_prefix = NULL) {
  numericInput(
    id,
    input_tooltip(
      HTML(add_prefix("K<sub>d</sub>(ref) (m<sup>-1</sup>)", label_prefix)),
      "Light attenuation coefficient at reference wavelength. Can be set directly, or calculated from DOC."
    ),
    value = NA_real_
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
