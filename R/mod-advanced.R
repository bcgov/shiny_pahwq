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

advanced_ui <- function(id) {
  ns <- NS(id)
  layout_sidebar(
    sidebar = sidebar(
      accordion(
        accordion_panel(
          "Location and Date",
          em(
            "Get Latitude and Longitude by clicking on the map, or enter here"
          ),
          br(),
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
          numericInput(
            ns("elev_m"),
            input_tooltip(
              "Elevation (m)",
              "Elevation in Canada and the USA is looked up based on latitude
                and longitude, but can be entered manually here."
            ),
            value = NA_real_,
            min = -100,
            max = 10000
          ),
          dateInput(
            ns("date"),
            "Date",
            value = simple_date()
          ),
          numericInput(
            ns("tzone"),
            input_tooltip(
              "Timezone (hrs)",
              "timezone offset from UTC, in hours. Default 0"
            ),
            value = 0,
            min = -14,
            max = 12
          )
        ),
        accordion_panel(
          "Water Parameters",
          uiOutput(ns("water_params_note")),
          doc_input(ns("doc")),
          depth_input(ns("depth_m"))
        ),
        accordion_panel(
          "Other TUV parameters",
          kd_input(ns("kd_ref")),
          numericInput(
            ns("kd_wvl"),
            input_tooltip(
              HTML("K<sub>d</sub>(ref) wavelength (nm)"),
              "The reference wavelength at which Kd(ref) was obtained, in nm.
                Default 305 in freshwater and 375 in marine water. Only used if
                Kd(ref) is set."
            ),
            value = 305
          ),
          numericInput(
            ns("tstart"),
            input_tooltip(
              "Start time (h)",
              "Start time of the calculation, in hours (between 0 and 24)"
            ),
            value = 0,
            min = 0,
            max = 23
          ),
          numericInput(
            ns("tstop"),
            input_tooltip(
              "Stop time (h)",
              "Stop time of the calculation, in hours (between 0 and 24)"
            ),
            value = 23,
            min = 0,
            max = 23
          ),
          sliderInput(
            ns("tsteps"),
            input_tooltip(
              "Time steps",
              "Number of time intervals between Start time and Stop time at
                which irradiance is calculated."
            ),
            min = 1,
            max = 24,
            value = 24,
            step = 1
          ),
          sliderInput(
            ns("multiplier"),
            input_tooltip(
              "TUV results multiplier",
              "Multiplier for calculating Pabs from TUV results. The standard
                is for a 48 exposure, so for a 24 hour TUV run, multiply
                the calculated irradiance by 2. This is the default."
            ),
            min = 1,
            max = 10,
            value = 2,
            step = 1
          ),
          numericInput(
            ns("wvl_start"),
            input_tooltip(
              "Start Wavelength (nm)",
              "Shortest wavelength at which to calculate irradiance"
            ),
            value = 280,
            min = 0,
            max = 800
          ),
          numericInput(
            ns("wvl_end"),
            input_tooltip(
              "End Wavelength (nm)",
              "Longest wavelength at which to calculate irradiance"
            ),
            value = 500,
            min = 0,
            max = 800
          ),
          em(
            "Ozone column and aerosol optical depth are calculated from
            climatology, but can be entered manually here"
          ),
          br(),
          numericInput(
            ns("o3_tc"),
            input_tooltip(
              "Ozone Column (DU)",
              "The ozone column, in Dobson Units. If empty, it is looked up
                based on latitude and month, based on historic climatology. If
                there is no historic value for the given month and location, a
                default value of 300 is used."
            ),
            value = NULL
          ),
          numericInput(
            ns("tauaer"),
            input_tooltip(
              "Aerosol Optical Depth",
              "The aerosol optical depth (tau) at 550 nm. If empty, it is
                looked up based on latitude, longitude, and month, based on historic
                climatology. If there is no historic value for the given month and
                location, a default value of 0.235 is used."
            ),
            value = NULL,
            min = 0.1,
            max = 1
          )
        ),
        open = c("Location and Date", "Water Parameters")
      ),
      resizable = FALSE
    ),
    result_boxes(ns),
    uiOutput(ns("kd_model_card")),
    navset_tab(
      nav_panel(
        "Map",
        br(),
        p(
          "Click the map to select the location, or set Latitude, Longitude and elevation in the left panel"
        ),
        card(card_body(map_ui(ns("map"))))
      ),
      nav_panel(
        "TUV Results",
        uiOutput(ns("tuv_download_btn")),
        card(tableOutput(ns("irrad_tbl")))
      ),
      nav_panel(
        "TUV Run Parameters",
        br(),
        card(htmlOutput(ns("tuv_params")))
      ),
      multi_tox_panel(ns),
      nav_panel(
        "DOC and Depth Sensitivity",
        br(),
        p(
          "Select a chemical above, and a location using the Map tab or the Latitude/Longitude/Elevation fields on the left."
        ),
        p(
          "Choose a range of depths and DOC or Kd(ref), and click 'Run'. All other TUV parameters (e.g., Ozone Column and Aerosol Optical Depth) will be used as set in the left sidebar."
        ),
        layout_columns(
          card(
            card_body(
              numericInput(
                ns("sens_year"),
                "Year",
                value = as.integer(format(Sys.Date(), "%Y")),
                min = 1900,
                max = as.integer(format(Sys.Date(), "%Y"))
              ),
              selectInput(
                ns("sens_months"),
                "Months",
                choices = month.name,
                multiple = TRUE
              ),
              sliderInput(
                ns("sens_depth"),
                "Depth Range (m)",
                min = 0.01,
                max = 2,
                value = c(0.01, 0.51),
                step = 0.01
              ),
              sliderInput(
                ns("depth_steps"),
                "Number of depth increments",
                min = 1,
                max = 10,
                value = 6
              ),
              radioButtons(
                ns("doc_or_kd"),
                "Choose Y axis variable",
                choices = c("DOC" = "doc", "Kd(ref)" = "kd"),
                selected = "doc"
              ),
              uiOutput(ns("attenuation_selector")),
            )
          ),
          card(
            actionButton(ns("run_sens_button"), "Run"),
            shinycssloaders::withSpinner(
              ggiraph::girafeOutput(
                ns("sens_plot"),
                width = "90%",
                height = "90%"
              ),
              type = 5,
              color = "darkgray"
            )
          ),
          col_widths = c(3, 9)
        )
      )
    )
  )
}

advanced_server <- function(id, shared, active) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    doc_reactive <- reactive(x_or_null(input$doc))

    kd_reactive <- reactive({
      if (!isTruthy(input$kd_ref)) {
        NULL
      } else {
        validate(
          need(input$kd_wvl, label = "Kd_wvl")
        )
        input$kd_ref
      }
    })

    kd_wvl_reactive <- reactive(x_or_null(input$kd_wvl))

    o3_tc_reactive <- reactive(x_or_null(input$o3_tc))

    tauaer_reactive <- reactive(x_or_null(input$tauaer))

    irrad <- reactive({
      local_tuv_dir()

      kd_ref <- kd_reactive()

      # In marine water Kd comes from the ecoregion model unless Kd(ref) is set
      if (input$aq_env == "marine") {
        doc <- NULL
      } else {
        doc <- doc_reactive()
        req(isTruthy(doc) || isTruthy(kd_ref))

        if (isTruthy(doc) && isTruthy(kd_ref)) {
          validate("Only one of DOC or Kd(ref) may be chosen")
        }
      }

      req(input$lat, input$lon)
      validate(need(input$depth_m, "Enter a water depth"))

      run_tuv(
        depth_m = input$depth_m,
        lat = req(input$lat),
        lon = req(input$lon),
        elev_m = req(input$elev_m),
        date = req(input$date),
        tzone = req(input$tzone),
        DOC = doc,
        aq_env = req(input$aq_env),
        Kd_ref = kd_ref,
        Kd_wvl = if (is.null(kd_ref)) NULL else kd_wvl_reactive(),
        tstart = req(input$tstart),
        tstop = req(input$tstop),
        tsteps = req(input$tsteps),
        wvl_start = req(input$wvl_start),
        wvl_end = req(input$wvl_end),
        o3_tc = o3_tc_reactive(),
        tauaer = tauaer_reactive()
      )
    })

    result_outputs(
      input,
      output,
      session,
      irrad,
      multiplier = reactive(input$multiplier)
    )

    observeEvent(
      input$aq_env,
      {
        marine <- input$aq_env == "marine"
        session$sendCustomMessage(
          "set-disabled",
          list(id = ns("doc"), disabled = marine)
        )
        updateNumericInput(
          inputId = "kd_wvl",
          value = if (marine) 375 else 305
        )
        update_elevation(input, marine)
      },
      priority = 1
    )

    # The marine area at the location, looked up once per location change
    location_area <- reactive(marine_area_at(input$lat, input$lon))

    output$water_params_note <- renderUI({
      if (input$aq_env == "marine") {
        em(HTML(
          "DOC is not used in marine water. Light attenuation is calculated
          from the ecoregion model for the location and date, unless
          K<sub>d</sub>(ref) is set in the TUV parameters section below."
        ))
      } else {
        em("Input DOC here or Kd(ref) in the TUV parameters section below")
      }
    })

    output$tuv_params <- renderUI({
      params <- tuv_run_params(irrad())
      tags$table(
        class = "table table-sm",
        tags$tbody(Map(
          \(name, value) tags$tr(tags$th(name), tags$td(value)),
          names(params),
          params
        ))
      )
    })

    output$irrad_tbl <- renderTable(irrad())

    output$kd_model_card <- renderUI({
      req(input$aq_env == "marine")
      kd_model_card(
        req(attr(irrad(), "kd_model")),
        kd_ref_set = isTruthy(input$kd_ref)
      )
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
    # came from the Simple tab with its environment. If it changes, the aq_env
    # observer sets the elevation. Higher priority than the outputs, and inputs
    # are frozen while they are updated, so results aren't calculated with the
    # previous environment or elevation.
    observeEvent(
      c(input$lat, input$lon),
      {
        if (
          !isTruthy(input$lat) ||
            !isTruthy(input$lon) ||
            from_shared(input, shared) ||
            !select_aq_env(input, location_area())
        ) {
          update_elevation(input, input$aq_env == "marine")
        }
      },
      priority = 1
    )

    output$tuv_download_btn <- renderUI({
      req(irrad())
      downloadButton(
        ns("tuv_download"),
        "Download TUV results to csv",
        class = "btn-primary m-2"
      )
    })

    output$tuv_download <- downloadHandler(
      filename = function() {
        paste0("tuv-results_", Sys.Date(), ".csv")
      },
      content = function(file) {
        utils::write.csv(
          tuv_results_export(irrad()),
          file,
          row.names = FALSE,
          na = ""
        )
      }
    )

    output$attenuation_selector <- renderUI({
      if (input$doc_or_kd == "doc") {
        tagList(
          sliderInput(
            ns("sens_doc"),
            HTML("DOC Range (g/m<sup>3</sup>)"),
            min = doc_range()[1],
            max = doc_range()[2],
            value = c(5, 10)
          ),
          sliderInput(
            ns("doc_steps"),
            "Number of DOC increments",
            min = 1,
            max = 10,
            value = 5
          )
        )
      } else {
        tagList(
          sliderInput(
            ns("sens_kd"),
            "Kd(305) Range",
            min = 0,
            max = 150,
            value = c(5, 50)
          ),
          sliderInput(
            ns("kd_steps"),
            "Number of Kd increments",
            min = 1,
            max = 10,
            value = 5
          )
        )
      }
    })

    sens <- eventReactive(input$run_sens_button, {
      run_sens(input)
    })

    output$sens_plot <- ggiraph::renderGirafe({
      sens()
    })
  })
}
