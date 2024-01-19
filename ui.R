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

page_sidebar(
  theme = bs_theme(bootswatch = "cerulean"),
  # Test TUV
  title = "Water Quality Calculator for Photoxic PAHs",

  # Sidebar with a slider input for DOC
  sidebar = sidebar(
    selectInput(
      "chemical",
      "PAH",
      choices = c(
        "Choose a chemical" = "",
        chemical_list()
      )
    ),
    accordion(
      accordion_panel(
        "Location and Date",
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
          "Elevation (m)",
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
        numericInput(
          "doc",
          HTML("DOC (g/m<sup>3</sup>)"),
          value = NA_real_,
          min = 0.2,
          max = 23
        ),
        numericInput(
          "depth_m",
          "Water Depth (m)",
          value = 0.25
        )
      ),
      accordion_panel(
        "Other TUV parameters",
        numericInput(
          "kd_ref",
          HTML("K<sub>d</sub>(ref) (m<sup>-1</sup>)"),
          value = NA_real_
        ),
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
        em("Ozone column and aerosol optical depth are calculated from climatology, but can be overridden here"),
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
      )
    )
  ),
  layout_columns(
    fill = FALSE,
    value_box(title = p(HTML("P<sub>abs</sub><br/><small>(mol photons/mol PAH)</small>")), value = textOutput("pabs"), showcase = bs_icon("sun")),
    value_box(title = p(HTML("NLC50<br/><small>(&mu;g/L)</small>")), value = textOutput("nlc50"), showcase = bs_icon("bug-fill")),
    value_box(title = p(HTML("PLC50<br/><small>(&mu;g/L)</small>")), value = textOutput("plc50"), showcase = bs_icon("bug"))
  ),
  navset_tab(
    nav_panel(
      "map",
         card(
           card_header("Click to select the location, or set the Latitude and Longitude in the left panel"),
              card_body(leafletOutput("map", height = 600, width = 600)))
    ),
    nav_panel(
      "tuv results",
      card(tableOutput("irrad_tbl"))
    ),
    nav_panel(
      "tuv run parameters",
      card(htmlOutput("tuv_params"))
    )
  )
)
