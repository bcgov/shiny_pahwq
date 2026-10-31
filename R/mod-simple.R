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

simple_ui <- function(id) {
  ns <- NS(id)
  layout_sidebar(
    sidebar = sidebar(
      em(
        "Get Latitude and Longitude by clicking on the map, or enter here"
      ),
      numericInput(
        ns("lat"),
        "Latitude (decimal degrees)",
        value = NA_real_,
        min = -70,
        max = 70
      ),
      numericInput(
        ns("lon"),
        "Longitude (decimal degrees)",
        value = NA_real_,
        min = -180,
        max = 180
      ),
      uiOutput(ns("water_params_note")),
      doc_input(ns("doc")),
      p(
        class = "small",
        "Guidelines are calculated for June 21 at a depth of 1 cm. Use the
        Advanced tab to change these and other settings."
      ),
      resizable = FALSE
    ),
    result_boxes(ns),
    navset_tab(
      nav_panel(
        "Map",
        br(),
        p(
          "Click the map to select the location, or set Latitude and Longitude in the left panel"
        ),
        card(card_body(map_ui(ns("map"))))
      ),
      multi_tox_panel(ns)
    )
  )
}

simple_server <- function(id, shared, active) {
  moduleServer(id, function(input, output, session) {
    location_area <- reactive(marine_area_at(input$lat, input$lon))

    elev_m <- reactive(
      site_elevation(input$lat, input$lon, input$aq_env == "marine")
    )

    irrad <- reactive({
      local_tuv_dir()
      marine <- input$aq_env == "marine"
      req(input$lat, input$lon, marine || isTruthy(input$doc))

      run_tuv(
        lat = input$lat,
        lon = input$lon,
        elev_m = x_or_null(elev_m()),
        date = simple_date(),
        DOC = if (!marine) input$doc,
        aq_env = input$aq_env
      )
    })

    result_outputs(input, output, session, irrad, multiplier = reactive(2))

    observeEvent(input$aq_env, {
      session$sendCustomMessage(
        "set-disabled",
        list(id = session$ns("doc"), disabled = input$aq_env == "marine")
      )
    })

    output$water_params_note <- renderUI({
      if (input$aq_env == "marine") {
        em(
          "DOC is not used in marine water. Light attenuation is calculated
          from the ecoregion model for the location."
        )
      }
    })

    map_click <- map_server(
      "map",
      lat = reactive(input$lat),
      lon = reactive(input$lon),
      aq_env = reactive(input$aq_env)
    )

    observeEvent(map_click(), {
      updateNumericInput(inputId = "lat", value = map_click()$lat)
      updateNumericInput(inputId = "lon", value = map_click()$lng)
    })

    share_inputs(input, shared, active)

    # Choose the aquatic environment from the location, unless the location
    # came from the Advanced tab with its environment
    observeEvent(
      c(input$lat, input$lon),
      {
        if (
          isTruthy(input$lat) &&
            isTruthy(input$lon) &&
            !from_shared(input, shared)
        ) {
          select_aq_env(input, location_area())
        }
      },
      priority = 1
    )
  })
}
