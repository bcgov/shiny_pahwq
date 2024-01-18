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

library(shiny)
library(pahwq)
library(leaflet)

function(input, output, session) {

  tuv_inputs <- reactiveValues(
    doc = NULL,
    kd_ref = NULL,
    kd_wvl = NULL,
    o3_tc = NULL,
    tauaer = NULL
  )

  observeEvent(input$doc, {
    tuv_inputs$doc <- if (!isTruthy(input$doc)) NULL else input$doc
  })

  observeEvent(input$kd_ref, {
    tuv_inputs$kd_ref <- if (!isTruthy(input$kd_ref)) NULL else input$kd_ref
  })

  observeEvent(input$kd_wvl, {
    tuv_inputs$kd_wvl <- if (!isTruthy(input$kd_wvl)) NULL else input$kd_wvl
  })

  observeEvent(input$o3_tc, {
    tuv_inputs$o3_tc <- if (!isTruthy(input$o3_tc)) NULL else input$o3_tc
  })

  observeEvent(input$tauaer, {
    tuv_inputs$tauaer <- if (!isTruthy(input$tauaer)) NULL else input$tauaer
  })

  irrad <- reactive({
    tuv(
      depth_m = req(input$depth_m),
      lat = req(input$lat),
      lon = req(input$lon),
      elev_km = req(input$elev_km),
      date = req(input$date),
      tzone = req(input$tzone),
      DOC = tuv_inputs$doc,
      Kd_ref = tuv_inputs$kd_ref,
      Kd_wvl = tuv_inputs$kd_wvl,
      tstart = input$tstart,
      tstop = input$tstop,
      tsteps = input$tsteps,
      wvl_start = input$wvl_start,
      wvl_end = input$wvl_end,
      o3_tc = tuv_inputs$o3_tc,
      tauaer = tuv_inputs$tauaer,
      quiet = TRUE
    )
  })

  output$tuv_params <- renderUI({
    params <- tuv_run_params(irrad())
    HTML(paste(
      paste0("<b>", names(params), "</b>"),
      params, sep = ": ", collapse = "<br/>"))
  })

  pabs <- reactive(p_abs(irrad(), req(input$chemical)))

  output$irrad_tbl <- renderTable(irrad())

  output$pabs <- renderText(round(pabs(), 2))

  output$nlc50 <- renderText({
    round(nlc50(req(input$chemical)), 2)
  })

  output$plc50 <- renderText({
    round(plc50(pabs(), pah = req(input$chemical)), 2)
  })

  output$map <- renderLeaflet({
    leaflet() |>
      addTiles()
  })

  # This updates the lat and lon input fields if the user clicks on the map
  observeEvent(input$map_click, {
    updateNumericInput(inputId = "lat", value = input$map_click$lat)
    updateNumericInput(inputId = "lon", value = input$map_click$lng)
  })

  # A default value of zoom, and then store the new value when the user changes it.
  # This is then used to maintain the zoom level when the user updates the location
  # either by clicking on the map or updating the lat and lon input fields
  zoom <- reactiveVal(5)
  observeEvent(input$map_zoom, zoom(input$map_zoom))

  # Update the map when the lat and lon change
  observe({
    lng <- req(input$lon)
    lat <- req(input$lat)

    # isolate zoom so that it doesn't update the reactive scope when it's changed
    # i.e., it doesn't make this observer keep reacting when it's changed - within
    # this context it's read-only
    zoomed <- isolate(zoom())

    leafletProxy("map") |>
      clearMarkers() |>
      addMarkers(lng = lng, lat = lat) |>
      setView(lng = lng, lat = lat, zoom = zoomed)
  })

  #### Testing area

}
