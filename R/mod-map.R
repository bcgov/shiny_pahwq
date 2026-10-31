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

map_ui <- function(id) {
  leaflet::leafletOutput(NS(id, "leaflet"), height = 600, width = 600)
}

# Shows the location and, in marine water, the marine areas. Returns a
# reactive with the location (lat and lng) the user last clicked.
map_server <- function(id, lat, lon, aq_env) {
  moduleServer(id, function(input, output, session) {
    output$leaflet <- leaflet::renderLeaflet({
      leaflet::leaflet(
        options = leaflet::leafletOptions(zoomControl = FALSE)
      ) |>
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
        add_marine_areas(group = "Marine areas") |>
        leaflet::hideGroup("Marine areas") |>
        leaflet::addLayersControl(
          baseGroups = c("OpenStreetMap", "OpenTopoMap", "ESRI Imagery"),
          overlayGroups = "Marine areas",
          position = "bottomleft"
        ) |>
        leaflet::setView(lng = -125.8178, lat = 54.1585, zoom = 5) |>
        htmlwidgets::onRender(
          "function(el, x) {
            L.control.zoom({position:'topright'}).addTo(this);
          }"
        )
    })

    observeEvent(aq_env(), {
      map <- leaflet::leafletProxy("leaflet")
      if (aq_env() == "marine") {
        map |>
          leaflet::showGroup("Marine areas") |>
          add_marine_legend("Marine areas", layerId = "marine_legend")
      } else {
        map |>
          leaflet::hideGroup("Marine areas") |>
          leaflet::removeControl("marine_legend")
      }
    })

    # Keep the user's zoom level when the location changes
    zoom <- reactiveVal(5)
    observeEvent(input$leaflet_zoom, zoom(input$leaflet_zoom))

    observe({
      lng <- req(lon())
      lat <- req(lat())

      leaflet::leafletProxy("leaflet") |>
        leaflet::clearMarkers() |>
        leaflet::addMarkers(lng = lng, lat = lat) |>
        leaflet::setView(lng = lng, lat = lat, zoom = isolate(zoom()))
    })

    # Clicks on the marine area polygons are reported as shape clicks
    clicked <- reactiveVal()
    observeEvent(input$leaflet_click, clicked(input$leaflet_click))
    observeEvent(input$leaflet_shape_click, clicked(input$leaflet_shape_click))
    reactive(clicked())
  })
}
