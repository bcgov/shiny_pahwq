# Copyright 2024 Province of British Columbia
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

server <- function(input, output, session) {
  # The location, aquatic environment, DOC and chemical, shared by the
  # calculators
  shared <- reactiveValues()
  simple_server(
    "simple",
    shared,
    active = reactive(identical(input$nav, "Simple"))
  )
  # The TU/HI tab uses Advanced's inputs, so they have to be up to date when it
  # is selected too
  advanced <- advanced_server(
    "advanced",
    shared,
    active = reactive(isTRUE(input$nav %in% c("Advanced", tu_hi_tab)))
  )
  edit_settings <- tu_hi_server(
    "tu_hi",
    irrad = advanced$irrad,
    multiplier = advanced$multiplier,
    settings = advanced$settings
  )
  observeEvent(edit_settings(), nav_select("nav", "Advanced"))
  observeEvent(advanced$back_to_tu_hi(), nav_select("nav", tu_hi_tab))

  multi_doc_pah_fw_csv <- reactive(
    system.file(
      "doc-guideline-lookup/PAC-DOC_freshwater-guidelines.csv",
      package = "pacwq"
    )
  )

  output$multi_doc_pah_fw_dl <- downloadHandler(
    filename = "PAC-DOC_freshwater-guidelines.csv",
    content = function(file) file.copy(req(multi_doc_pah_fw_csv()), file)
  )

  multi_pah_marine_csv <- reactive(
    system.file(
      "doc-guideline-lookup/PAC_marine-guidelines.csv",
      package = "pacwq"
    )
  )

  output$multi_pah_marine_dl <- downloadHandler(
    filename = basename(req(multi_pah_marine_csv())),
    content = function(file) file.copy(req(multi_pah_marine_csv()), file)
  )

  output$multi_doc_pah_fw <- DT::renderDT({
    DT::datatable(
      req(utils::read.csv(multi_doc_pah_fw_csv())),
      filter = "top"
    ) |>
      DT::formatRound(
        columns = c(
          "narcotic_benchmark",
          "narcotic_cwqg",
          "phototoxic_benchmark",
          "phototoxic_cwqg"
        ),
        digits = 3
      ) |>
      DT::formatRound(columns = "pabs", digits = 5)
  })

  output$multi_pah_marine <- DT::renderDT({
    DT::datatable(
      req(utils::read.csv(multi_pah_marine_csv())),
      filter = "top"
    ) |>
      DT::formatRound(
        columns = c(
          "narcotic_benchmark",
          "narcotic_cwqg",
          "phototoxic_benchmark",
          "phototoxic_cwqg"
        ),
        digits = 3
      ) |>
      DT::formatRound(columns = "pabs", digits = 5)
  })
}
