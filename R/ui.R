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
    theme = bs_theme(version = 5, bootswatch = "cerulean"),
    tags$head(
      tags$link(
        rel = "stylesheet", type = "text/css", href = "www/style.css")
      ),
      title = h1(
        class = "bslib-page-title",
        img(
          class = "img-logo",
          src = "www/BCID_V_rgb_rev.png",
          height = 80,
          width = 80
        ), "Water Quality Calculator for Phototoxic PAHs"
      ),
      # title = "Water Quality Calculator for Phototoxic PAHs",
      
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
              "date",
              "Date"
            ),
            numericInput(
              "tzone",
              input_tooltip(
                "Timezone (hrs)",
                "timezone offset from UTC, in hours. Default 0"
              ),
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
              input_tooltip(
                HTML("K<sub>d</sub>(ref) wavelength (nm)"),
                "The reference wavelength at which `Kd_ref` was obtained, in nm.
                Default 305. Only used if Kd_ref is set."
              ),
              value = 305
            ),
            numericInput(
              "tstart",
              input_tooltip(
                "Start time (h)",
                "Start time of the calculation, in hours (between 0 and 24)"
              ),
              value = 0,
              min = 0,
              max = 23
            ),
            numericInput(
              "tstop",
              input_tooltip(
                "Stop time (h)",
                "Stop time of the calculation, in hours (between 0 and 24)"
              ),
              value = 23,
              min = 0,
              max = 23
            ),
            sliderInput(
              "tsteps",
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
              "multiplier",
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
              "wvl_start",
              input_tooltip(
                "Start Wavelength (nm)",
                "Shortest wavelength at which to calculate irradiance"
              ),
              value = 280,
              min = 0,
              max = 700
            ),
            numericInput(
              "wvl_end",
              input_tooltip(
                "End Wavelength (nm)",
                "Longest wavelength at which to calculate irradiance"
              ),
              value = 700,
              min = 0,
              max = 700
            ),
            em("Ozone column and aerosol optical depth are calculated from 
            climatology, but can be entered manually here"),
            br(),
            numericInput(
              "o3_tc",
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
              "tauaer",
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
            DT::DTOutput("multi_tox")
          ),
          nav_panel(
            "DOC and Depth Sensitivity",
            br(),
            p("Select a chemical above, and a location using the Map tab or the Latitude/Longitude/Elevation fields on the left."),
            p("Choose a range of depths and DOC or Kd(ref), and click 'Run'. All other TUV parameters (e.g., Ozone Column and Aerosol Optical Depth) will be used as set in the left sidebar."),
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
                    "Depth Range (m)",
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
          ), 
          nav_panel(
            "Help/About",
            card(
              withMathJax(),
              p(HTML(
                "This app implements the <a href='https://doi.org/10.1002/etc.3601'>
                Phototoxic Target Lipid Model</a> (PTLM) for 
                the calculation of Canadian Water Quality Guidelines for Polycyclic 
                Aromatic Hydrocarbons (PAH)."
              )),
              
              p(HTML(
                "It relies on the <a href='https://bcgov.github.io/pahwq'>pahwq</a> 
                R package, which uses the <a href='https://github.com/NCAR/TUV'>
                Tropospheric Ultraviolet and Visible (TUV) Radiation Model</a>
                to calculate the light penetration through water of a given depth 
                at a given location and date, with a specified attennuation coeffcienct. This
                coefficient can be calculated from a Dissolved Organic Carbon concentration. 
                The light exposure is then used (along with the PAH-specific molar 
                  absorption across a range of wavelengths), to calculate the light 
                  absorption (Pabs) of the given PAH at that location. This is then 
                  used to determine the PLC50 of the PAH under those conditions."
                )),
                
                p(
                  "By default, the app will run the TUV model for 24 hours on the
                  given day, with one irradiance calculation per hour at each wavelength.
                  When calculating Pabs, total light absorption by the given
                  chemical is multiplied by 2 as the standard exposure is 48h for
                  determining NLC50 and PLC50."
                ),
                
                h3("Inputs"),
                h4("Location and Date"),
                p(
                  "These determine the location and date for which the TUV model 
                  is run to determine irradiance."
                ),
                p(HTML(
                  "Location is determined by entering latitude, longitude, and 
                  elevation, or by clicking a location on the map.
                  When clicking a location on a map, elevation is looked up using 
                  Natural Resource Canada's <a href='https://natural-resources.canada.ca/science-and-data/science-and-research/earth-sciences/geography/topographic-information/web-services/elevation-api/17328'>
                  Elevation API</a>, and if outside of Canada, using the 
                  <a href='https://epqs.nationalmap.gov/v1/docs'>USGS Elevation 
                  Point Query Service</a>.
                  "
                )),
                
                h4("Water parameters"),
                
                p(HTML(
                  "These determine the light attenuation through the water at a given depth. Light attenuation 
                  at each wavelength (\\(k_d(\\lambda)\\)) is determined 
                  from the attenuation coefficient at a reference wavelength (305nm), which is calculated from 
                  Dissolved Organic Carbon (DOC) concentration using the following 
                  equation from Morris et al (1995):"
                )),
                p(HTML(
                  "$$k_{d,305} = a_{305}[DOC]^{b,305} + 0.13;\\,a_{305} = 2.76\\text{ and }b_{305} = 1.23$$"
                )),
                
                p(HTML("You can supply an absoruption coeffecient (\\(k_d(\\lambda)\\)) 
                and reference wavelength directly instead of calculating it from DOC
                in the 'Other TUV Parameters section:")),
                
                h4("Other TUV parameters"),
                p(
                  "Ozone column and aerosol optical depth are looked up from 
                  historic climatology based on the date and location entered."
                ),
                
                h5("Ozone column (DU)"),
                p(
                  "The app uses monthly ozone column data from 1980-1991 from 
                  Fortuin and Kelder (1998), which is bundled with the TUV model. 
                  Based on latitude and longitude and month, the ozone column value 
                  is looked up and supplied to the TUV model. It can be supplied 
                  manually to override this behaviour"
                ),
                
                h5("Aerosol optical depth"),
                p(
                  "The app uses average monthly aerosol optical depth data from 
                  2002 to 2023, obtained from NASA MODIS/Aqua satellite data, 
                  aggregated to 1 degree latutide and longitude resolution. If no
                  value is available for a given month, latitude, and longitude,
                  a default value of 0.235 is used.
                  It can be supplied manually to override this behaviour"
                ),
                
                h3("References"),
                
                  p(
                    "Morris, D.P., H. Zagarese, C.E. Williamson, E.G. Balseiro, 
                    B.R. Hargreaves, B. Modenutti, R. Moeller, and C. Queimalinos. 
                    1995. The attenuation of solar UV radiation in lakes and the 
                    role of dissolved organic carbon. Limnology and Oceanography, 4
                    0, 1381-1391. doi:", 
                    a("10.4319/lo.1995.40.8.1381.", 
                    href = "https://10.4319/lo.1995.40.8.1381")
                  ),
                  p(
                    "Paul, J., F. Fortuin, and H. Kelder (1998), An ozone 
                    climatology based on ozonesonde and satellite measurements, 
                    J. Geophys. Res., 103(D24), 31709–31734, doi:",
                    a("10.1029/1998JD200008.", 
                    href = "https://10.1029/1998JD200008")
                  )
                  
                  
                )
              ))
            )
          }
