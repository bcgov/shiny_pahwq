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

ui <- function() {
  page_sidebar(
    tags$head(tags$style("
    .select-overflowable {
      overflow: visible !important;
    }
  ")),
  theme = bs_theme(version = 5, bootswatch = "cerulean"),
  # Test TUV
  title = "Water Quality Calculator for Photoxic PAHs",

  # Sidebar with a slider input for DOC
  sidebar = sidebar(
    accordion(
      accordion_panel(
        "Location and Date",
        em("Get Latitude and Longitude by clicking on the map, or enter here"),
        br(),
        numericInput(
          "lat",
          "Latitude (decimal degrees)",
          value = NA_real_,
          min = -70,
          max = 70
        ),
        numericInput(
          "lon",
          "Longitude (decimal degrees)",
          value = NA_real_,
          min = -180,
          max = 180
        ),
        numericInput(
          "elev_m",
          label = tooltip(
            trigger = list("Elevation (m)", bsicons::bs_icon("info-circle")),
            "Elevation in Canada and the USA is looked up based on latitude
              and longitude, but can be entered manually here."
          ),
          value = NA_real_,
          min = -100,
          max = 10000
        ),
        dateInput(
          "date",
          "Date"
        ),
        numericInput(
          "tzone",
          "Timezone (hrs)",
          value = -8,
          min = -14,
          max = 12
        )
      ),
      accordion_panel(
        "Water Parameters",
        em("Input DOC here or Kd(ref) in the TUV parameters section below"),
        br(),
        doc_input("doc"),
        depth_input("depth_m")
      ),
      accordion_panel(
        "Other TUV parameters",
        kd_input("kd_ref"),
        numericInput(
          "kd_wvl",
          HTML("K<sub>d</sub>(ref) wavelength (nm)"),
          value = 305
        ),
        numericInput(
          "tstart",
          "Start time (h)",
          value = 0,
          min = 0,
          max = 23
        ),
        numericInput(
          "tstop",
          "Stop time (h)",
          value = 23,
          min = 0,
          max = 23
        ),
        numericInput(
          "tsteps",
          "Time steps",
          value = 24
        ),
        numericInput(
          "wvl_start",
          "Start Wavelength (nm)",
          value = 280,
          min = 0,
          max = 700
        ),
        numericInput(
          "wvl_end",
          "End Wavelength (nm)",
          value = 420,
          min = 0,
          max = 700
        ),
        em("Ozone column and aerosol optical depth are calculated from climatology, but can be entered manually here"),
        br(),
        numericInput(
          "o3_tc",
          "Ozone Column (DU)",
          value = NULL
        ),
        numericInput(
          "tauaer",
          "Aerosol Optical Depth",
          value = NULL,
          min = 0.1,
          max = 1
        )
      ),
      open = c("Location and Date", "Water Parameters")
    )
  ),
  layout_columns(
    fill = FALSE,
    card(
      "PAH",
      chem_input("chemical"),
      class = "select-overflowable",
      wrapper = function(...) card_body(..., class = "select-overflowable")
    ),
    value_box(
      title = p(HTML("NLC50<br/><small>(&mu;g/L)</small>")),
      value = textOutput("nlc50"),
      showcase = tooltip(
        bsicons::bs_icon("bug-fill"),
        "You must select a chemical"
      )
    ),
    value_box(
      title = p(HTML("P<sub>abs</sub><br/><small>(mol photons/mol PAH)</small>")),
      value = textOutput("pabs"),
      showcase = tooltip(
        bsicons::bs_icon("sun"),
        "You must select a chemical and fill in the necessary parameters on the left to run the TUV model"
      )
    ),
    value_box(
      title = p(HTML("PLC50<br/><small>(&mu;g/L)</small>")),
      value = textOutput("plc50"),
      showcase = tooltip(
        bsicons::bs_icon("bug"),
        "You must select a chemical and fill in the necessary parameters on the left to run the TUV model"
      )
    )
  ),
  navset_tab(
    nav_panel(
      "Map",
      br(),
      p("Click the map to select the location, or set Latitude, Longitude and elevation in the left panel"),
      card(
        card_body(leaflet::leafletOutput("map", height = 600, width = 600)))
    ),
    nav_panel(
      "TUV Results",
      uiOutput("tuv_download_btn"),
      card(tableOutput("irrad_tbl"))
    ),
    nav_panel(
      "TUV Run Parameters",
      br(),
      card(htmlOutput("tuv_params"))
    ),
    nav_panel(
      "Multi-Chemical Toxicity",
      uiOutput("multi_tox_download_btn"),
      card(tableOutput("multi_tox"))
    ),
    nav_panel(
      "DOC and Depth Sensitivity",
      br(),
      p("Select a location (on the Map tab or the Latitude/Longitude/Elevation fields on the left), and a chemical above."),
      layout_columns(
        card(
          card_body(
            numericInput(
              "sens_year",
              "Year",
              value = as.integer(format(Sys.Date(), "%Y")),
              min = 1900,
              max = as.integer(format(Sys.Date(), "%Y"))
            ),
            selectInput(
              "sens_months",
              "Months",
              choices = month.name,
              multiple = TRUE
            ),
            sliderInput(
              "sens_depth",
              "Depth Range",
              min = 0, max = 2,
              value = c(0.25,1),
              step = 0.05
            ),
            sliderInput(
              "depth_steps",
              "Number of depth increments",
              min = 1, max = 10,
              value = 5
            ),
            radioButtons(
              "doc_or_kd",
              "Choose Y axis variable",
              choices = c("DOC" = "doc", "Kd(ref)" = "kd"),
              selected = "doc"
            ),
            uiOutput("attenuation_selector"),
          )
        ),
        card(
          actionButton("run_sens_button", "Run"),
          shinycssloaders::withSpinner(
            ggiraph::girafeOutput("sens_plot", width = "90%", height = "90%"),
            type = 5,
            color = "darkgray"
          )
        ),
        col_widths = c(3,9)
      )
    )
  )
  )
}
