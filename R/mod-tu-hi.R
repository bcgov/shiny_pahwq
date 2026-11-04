# Copyright 2026 Province of British Columbia
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

tu_hi_tab <- "Toxic Units (TUs) / Hazard Index (HI)"

tu_hi_ui <- function(id) {
  ns <- NS(id)
  pacs <- names(chemical_list())
  layout_sidebar(
    fillable = FALSE,
    sidebar = sidebar(
      width = 380,
      h2(class = "h5", "Monitoring concentrations (µg/L)"),
      div(
        actionButton(ns("calculate"), "Calculate", class = "btn-primary"),
        actionButton(ns("clear"), "Clear")
      ),
      fileInput(ns("upload"), "Upload a CSV file", accept = ".csv"),
      downloadLink(ns("template"), "Download a template"),
      uiOutput(ns("upload_status")),
      div(
        class = "tu-hi-concentrations",
        lapply(seq_along(pacs), function(i) {
          numericInput(
            ns(paste0("conc_", i)),
            pacs[i],
            value = NA_real_,
            min = 0,
            width = "100%"
          )
        })
      )
    ),
    card(
      fill = FALSE,
      card_header("Settings in use"),
      card_body(
        uiOutput(ns("settings")),
        p(
          "Set these to match the sample. The location, aquatic environment and
          DOC can be changed on the Simple or Advanced tab, and all other
          settings on the Advanced tab. Settings not shown here are at their
          default values or don't apply."
        ),
        p(
          actionLink(ns("edit_settings"), "Edit settings in Advanced")
        )
      )
    ),
    uiOutput(ns("stale_notice")),
    uiOutput(ns("results"))
  )
}

# Returns a reactive for the link to edit the settings
tu_hi_server <- function(id, irrad, multiplier, settings) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    conc_ids <- paste0("conc_", seq_along(chemical_list()))

    output$settings <- renderUI(
      tu_hi_settings_list(tu_hi_settings_items(settings()))
    )

    set_concentrations <- function(values) {
      for (i in seq_along(conc_ids)) {
        updateNumericInput(inputId = conc_ids[i], value = values[i])
      }
    }

    upload_status <- reactiveVal()
    output$upload_status <- renderUI(upload_status())

    observeEvent(input$upload, {
      res <- read_concentrations(input$upload$datapath)
      if (!is.null(res$values)) {
        set_concentrations(res$values)
      }
      upload_status(tagList(
        lapply(res$errors, \(x) div(class = "alert alert-danger", x)),
        lapply(res$notices, \(x) div(class = "alert alert-warning", x)),
        if (!is.null(res$values)) {
          p(
            class = "small",
            "Concentrations loaded from '",
            input$upload$name,
            "'. Check them, then press Calculate."
          )
        }
      ))
      session$sendCustomMessage(
        "reset-file-input",
        list(id = ns("upload"), clear = FALSE)
      )
    })

    observeEvent(input$clear, {
      set_concentrations(rep(NA_real_, length(conc_ids)))
      upload_status(NULL)
      session$sendCustomMessage(
        "reset-file-input",
        list(id = ns("upload"), clear = TRUE)
      )
    })

    results <- eventReactive(input$calculate, {
      values <- vapply(
        conc_ids,
        \(id) as.numeric(input[[id]] %||% NA_real_),
        numeric(1)
      )
      validate(need(
        !any(values < 0, na.rm = TRUE),
        "Concentrations can't be negative."
      ))
      validate(need(
        !all(is.na(values)),
        "Enter at least one concentration."
      ))
      saved <- settings()
      validate(need(
        !is.null(saved$lat) && !is.null(saved$lon),
        "Set a location on the Simple or Advanced tab to calculate results."
      ))
      tuv_res <- irrad()
      list(
        results = tu_hi_sample(unname(values), tuv_res, req(multiplier())),
        settings = saved,
        settings_used = settings_used(saved, tuv_run_params(tuv_res)),
        kd_model = attr(tuv_res, "kd_model")
      )
    })

    output$stale_notice <- renderUI({
      # Errors from results() are shown by output$results
      res <- tryCatch(results(), error = \(e) NULL)
      req(res, !identical(res$settings, settings()))
      div(
        class = "alert alert-warning",
        "The settings have changed since these results were calculated. Press
        Calculate to update them."
      )
    })

    output$results <- renderUI({
      res <- results()
      box <- function(title, column) {
        value_box(title = title, value = format_sum(res$results[[column]]))
      }
      tagList(
        h4("TU/HI Results"),
        layout_columns(
          fill = FALSE,
          col_widths = breakpoints(sm = 6, xxl = 3),
          box("Narcotic TUs", "tu_narcotic"),
          box("Phototoxic TUs", "tu_phototoxic"),
          box("Narcotic HI", "hi_narcotic"),
          box("Phototoxic HI", "hi_phototoxic")
        ),
        downloadButton(
          ns("results_download"),
          "Download results to csv",
          class = "btn-primary mb-2"
        ),
        DT::DTOutput(ns("results_tbl"))
      )
    })

    output$results_tbl <- DT::renderDT(
      tu_hi_results_table(attr(results()$results, "pacs"))
    )

    output$results_download <- downloadHandler(
      filename = function() paste0("tu-hi-results_", Sys.Date(), ".csv"),
      content = function(file) {
        res <- results()
        utils::write.csv(
          tu_hi_export(res$results, res$settings_used, res$kd_model),
          file,
          row.names = FALSE,
          na = ""
        )
      }
    )

    output$template <- downloadHandler(
      filename = "tu-hi-concentrations-template.csv",
      content = function(file) {
        utils::write.csv(
          concentrations_template(),
          file,
          row.names = FALSE,
          na = ""
        )
      }
    )

    reactive(input$edit_settings)
  })
}
