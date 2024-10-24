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

    if (input$aq_env == "marine") {
      doc_reactive <- reactive(NULL)
      kd_reactive <- reactive(NULL)
      kd_wvl_reactive <- reactive(NULL)
      showNotification(
        "DOC, Kd, and Kd wavelength are ignored for marine calculations",
        duration = 10,
        type = "warning"
      )
    } else {
      req(isTruthy(doc_reactive()) || isTruthy(kd_reactive()))

      if (isTruthy(doc_reactive()) && isTruthy(kd_reactive())) {
        validate("Only one of DOC or Kd(ref) may be chosen")
      }
    }

    tuv(
      depth_m = req(input$depth_m),
      lat = req(input$lat),
      lon = req(input$lon),
      elev_m = req(input$elev_m),
      date = req(input$date),
      tzone = req(input$tzone),
      DOC = doc_reactive(),
      aq_env = req(input$aq_env),
      Kd_ref = kd_reactive(),
      Kd_wvl = kd_wvl_reactive(),
      tstart = req(input$tstart),
      tstop = req(input$tstop),
      tsteps = req(input$tsteps),
      wvl_start = req(input$wvl_start),
      wvl_end = req(input$wvl_end),
      o3_tc = o3_tc_reactive(),
      tauaer = tauaer_reactive(),
      quiet = TRUE
    )
  })

  output$tuv_params <- renderUI({
    params <- tuv_run_params(irrad())
    HTML(paste(
      paste0("<b>", names(params), "</b>"),
      params,
      sep = ": ", collapse = "<br/>"
    ))
  })

  pabs <- reactive(
    p_abs(
      irrad(),
      req(input$chemical),
      time_multiplier = req(input$multiplier)
    )
  )

  output$irrad_tbl <- renderTable(irrad())

  output$pabs <- renderText({
    paste(
      "<p>",
      round(pabs(), 2),
      '</br><span class="small">mol photons/mol PAH</span></p>'
    )
  })

  output$narc_bench_title <- renderText({
    glue::glue(
      "<p><em>{aq_env}</em> short-term NLC50<sub>(5)</sub></p>",
      aq_env = tools::toTitleCase(input$aq_env)
    )
  })

  output$narc_bench <- renderText({
    glue::glue(
      "<p>{narc_bench} &mu;g/L</p>",
      narc_bench = round(narcotic_benchmark(req(input$chemical)), 2)
    )
  })

  output$photo_bench_title <- renderText({
    glue::glue(
      "<p><em>{aq_env}</em> short-term PLC50<sub>(5)</sub></p>",
      aq_env = tools::toTitleCase(input$aq_env)
    )
  })

  output$photo_bench <- renderText({
    glue::glue(
      "<p>{photo_bench} &mu;g/L</p>",
      photo_bench = round(phototoxic_benchmark(pabs(), pah = req(input$chemical)), 2)
    )
  })

  output$map <- leaflet::renderLeaflet({
    leaflet::leaflet(options = leaflet::leafletOptions(zoomControl = FALSE)) |>
      leaflet::addProviderTiles(
        leaflet::providers$OpenStreetMap,
        group = "OpenStreetMap"
      ) |>
      leaflet::addProviderTiles(
        leaflet::providers$OpenTopoMap,
        group = "OpenTopoMap"
      ) |>
      leaflet::addProviderTiles(
        leaflet::providers$Esri.WorldImagery,
        group = "ESRI Imagery"
      ) |>
      leaflet::addLayersControl(
        baseGroups = c("OpenStreetMap", "OpenTopoMap", "ESRI Imagery"),
        position = "bottomleft"
      ) |>
      leaflet::setView(lng = -125.8178, lat = 54.1585, zoom = 5) |>
      htmlwidgets::onRender(
        "function(el, x) {
          L.control.zoom({position:'topright'}).addTo(this);
        }"
      )
  })

  # This updates the lat and lon input fields if the user clicks on the map
  observeEvent(input$map_click, {
    updateNumericInput(inputId = "lat", value = input$map_click$lat)
    updateNumericInput(inputId = "lon", value = input$map_click$lng)
  })

  observeEvent(
    c(input$lat, input$lon),
    {
      elev_val <- tryCatch(
        get_elevation(req(input$lon), req(input$lat)),
        error = function(e) {
          return(NA_real_)
        }
      )
      updateNumericInput(
        inputId = "elev_m",
        value = elev_val
      )
    }
  )

  # A default value of zoom, and then store the new value when the user changes
  # it. This is then used to maintain the zoom level when the user updates the
  # location either by clicking on the map or updating the lat and lon input
  # fields
  zoom <- reactiveVal(5)
  observeEvent(input$map_zoom, zoom(input$map_zoom))

  # Update the map when the lat and lon change
  observe({
    lng <- req(input$lon)
    lat <- req(input$lat)

    # isolate zoom so that it doesn't update the reactive scope when it's
    # changed i.e., it doesn't make this observer keep reacting when it's
    # changed - within this context it's read-only
    zoomed <- isolate(zoom())

    leaflet::leafletProxy("map") |>
      leaflet::clearMarkers() |>
      leaflet::addMarkers(lng = lng, lat = lat) |>
      leaflet::setView(lng = lng, lat = lat, zoom = zoomed)
  })

  output$tuv_download_btn <- renderUI({
    req(irrad())
    downloadButton(
      "tuv_download",
      "Download TUV results to csv",
      class = "btn-primary m-2"
    )
  })

  output$tuv_download <- downloadHandler(
    filename = function() {
      paste0("tuv-results_", Sys.Date(), ".csv")
    },
    content = function(file) {
      utils::write.csv(irrad(), file, row.names = FALSE, na = "")
    }
  )

  multi_tox <- reactive({
    tuv_res <- req(irrad())
    chems <- chemical_list()
    pb_multi(tuv_res, chems, time_multiplier = req(input$multiplier))
  })

  output$multi_tox <- DT::renderDT({
    DT::datatable(req(multi_tox())) |>
      DT::formatRound(columns = c("narcotic_benchmark", "phototoxic_benchmark"), digits = 3) |>
      DT::formatRound(columns = "pabs", digits = 5)
  })

  output$multi_tox_download_btn <- renderUI({
    req(multi_tox())
    downloadButton(
      "multi_tox_download",
      "Download results to csv",
      class = "btn-primary m-2"
    )
  })

  output$multi_tox_download <- downloadHandler(
    filename = function() {
      paste0("phototoxic-benchmark-multi-results-", input$aq_env, "_", Sys.Date(), ".csv")
    },
    content = function(file) {
      utils::write.csv(multi_tox(), file, row.names = FALSE, na = "")
    }
  )

  output$attenuation_selector <- renderUI({
    if (input$doc_or_kd == "doc") {
      tagList(
        sliderInput(
          "sens_doc",
          HTML("DOC Range (g/m<sup>3</sup>)"),
          min = 0.2,
          max = 23,
          value = c(5, 10)
        ),
        sliderInput(
          "doc_steps",
          "Number of DOC increments",
          min = 1, max = 10,
          value = 5
        )
      )
    } else {
      tagList(
        sliderInput(
          "sens_kd",
          "Kd(305) Range",
          min = 0,
          max = 150,
          value = c(5, 50)
        ),
        sliderInput(
          "kd_steps",
          "Number of Kd increments",
          min = 1, max = 10,
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
}
