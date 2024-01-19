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
          value = 49.601632,
          min = -70,
          max = 70
        ),
        numericInput(
          "lon",
          "Longitude (decimal degrees)",
          value = -119.605862,
          min = -180,
          max = 180
        ),
        numericInput(
          "elev_m",
          "Elevation (m)",
          value = 342,
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
        numericInput(
          "doc",
          "DOC",
          value = 5,
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
          "Kd(ref)",
          value = NA
        ),
        numericInput(
          "kd_wvl",
          "Kd(ref) wavelength (nm)",
          value = 305
        ),
        numericInput(
          "tstart",
          "Start time",
          value = 0,
          min = 0,
          max = 23
        ),
        numericInput(
          "tstop",
          "Stop time",
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
          "Start Wavelength",
          value = 280,
          min = 0,
          max = 700
        ),
        numericInput(
          "wvl_end",
          "End Wavelength",
          value = 420,
          min = 0,
          max = 700
        ),
        numericInput(
          "o3_tc",
          "Ozone Column (DU)",
          value = NULL
        ),
        numericInput(
          "tauaer",
          "Aerosol Optical Depth",
          value = NULL
        )
      )
    )
  ),
  layout_columns(
    fill = FALSE,
    value_box(title = "P~abs~", value = textOutput("pabs"), showcase = bs_icon("sun")),
    value_box(title = "NLC50", value = textOutput("nlc50"), showcase = bs_icon("bug-fill")),
    value_box(title = "PLC50", value = textOutput("plc50"), showcase = bs_icon("bug"))
  ),
  navset_tab(
    nav_panel(
      "map",
         card(
           card_header("Click to select the location, or set the Latitude and Longitude in the left panel"),
              card_body(leafletOutput("map")))
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
