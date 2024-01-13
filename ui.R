#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
library(bslib)
library(bsicons)
library(fontawesome)
library(leaflet)

page_sidebar(
  theme = bs_theme(bootswatch = "cerulean"),
  # Test TUV
  title = "Water Quality Calculator for Photoxic PAHs",

  # Sidebar with a slider input for DOC
  sidebar = sidebar(
    selectInput(
      "chemical",
      "PAH",
      choices = pahwq:::molar_absorption$chemical,
      selected = "Anthracene"
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
          "elev_km",
          "Elevation (km)",
          value = 0.342,
          min = -2,
          max = 10
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
    ),
    value_box(title = "Test", value = textOutput("kdreftxt"))
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
         card("Click to select the location, or set the Latitude and Longitude in the left panel",
              leafletOutput("map"))
    ),
    nav_panel(
      "tuv results",
      card(tableOutput("irrad_tbl"))
    )
  )
)
