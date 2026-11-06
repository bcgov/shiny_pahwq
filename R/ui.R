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

app_title <- "Water Quality Guideline Calculator for Polycyclic Aromatic Compounds"

# Follows ccme.ca, apart from the headings: its greys don't meet WCAG AA on white
app_theme <- function() {
  bs_theme(
    version = 5,
    bg = "#ffffff",
    fg = "#272c2b",
    primary = "#00817a",
    base_font = font_google("Noto Sans", wght = c(400, 700), local = FALSE),
    "body-color" = "#272c2b",
    "font-size-base" = "1rem",
    "h2-font-size" = "1.5 * $font-size-base",
    "h3-font-size" = "1.33 * $font-size-base",
    "h4-font-size" = "1.125 * $font-size-base",
    "h5-font-size" = "$font-size-base",
    "h6-font-size" = "$font-size-base",
    "headings-color" = "#4f5957",
    "headings-font-weight" = 700,
    "link-color" = "#00817a",
    "link-hover-color" = "#272c2b",
    "navbar-light-brand-color" = "#272c2b",
    "navbar-light-brand-hover-color" = "#272c2b",
    "navbar-light-color" = "#272c2b",
    "navbar-light-hover-color" = "#00817a",
    "navbar-light-active-color" = "#00817a"
  )
}

ui <- function() {
  page_navbar(
    id = "nav",
    theme = app_theme(),
    navbar_options = navbar_options(bg = "#ffffff", theme = "light"),
    header = tags$head(
      tags$link(
        rel = "stylesheet",
        type = "text/css",
        href = "www/style.css"
      ),
      tags$script(src = "www/app.js")
    ),
    title = div(
      class = "app-header",
      img(
        class = "img-logo",
        src = "www/ccme_logo.png",
        alt = "CCME",
        height = 72,
        width = 192
      ),
      div(
        h1(class = "bslib-page-title", app_title),
        p(
          class = "app-disclaimer",
          "Draft for public review. Do not cite or distribute."
        )
      )
    ),
    window_title = app_title,
    nav_panel("Simple", simple_ui("simple")),
    nav_panel("Advanced", advanced_ui("advanced")),
    nav_panel(tu_hi_tab, tu_hi_ui("tu_hi")),
    rep_guidelines_panel(),
    help_panel()
  )
}

rep_guidelines_panel <- function() {
  nav_panel(
    "Representative Guidelines",
    navset_tab(
      nav_panel(
        "Freshwater",
        card(
          p(
            HTML(
              "This is a static lookup table for short-term and long-term
          guidelines at a representative freshwater site in
          Canada on June 21, for a range of dissolved organic carbon (DOC)
          (g/m<sup>3</sup>) concentrations."
            )
          ),
          tags$ul(
            tags$li("Location: Basin Lake, Saskatchewan"),
            tags$li("Lat: 52.60453"),
            tags$li("Long: -105.28278"),
            tags$li("Elevation: 515m"),
            tags$li("Depth: 0.01m"),
            tags$li("Date: 2024-06-21"),
          ),
          downloadButton(
            "multi_doc_pac_fw_dl",
            "Download",
            style = "width:200px;"
          )
        ),
        DT::DTOutput("multi_doc_pac_fw")
      ),
      nav_panel(
        "Marine",
        card(
          p(
            "This is a static lookup table for short-term and long-term
          guidelines at a representative marine site in
          Canada on June 21."
          ),
          tags$ul(
            tags$li("Location: Tofino, BC"),
            tags$li("Lat: 49.15085"),
            tags$li("Lon: -125.91427"),
            tags$li("Elevation: 0m"),
            tags$li("Depth: 0.01m"),
            tags$li("Date: 2024-06-21"),
          ),
          downloadButton(
            "multi_pac_marine_dl",
            "Download",
            style = "width:200px;"
          )
        ),
        DT::DTOutput("multi_pac_marine")
      )
    )
  )
}

help_panel <- function() {
  nav_panel(
    "Help/About",
    card(
      withMathJax(),
      p(
        HTML(
          "This calculator implements the <a href='https://doi.org/10.1002/etc.3601'>
            Phototoxic Target Lipid Model</a> (PTLM) for
            the calculation of draft Canadian Water Quality Guidelines for Polycyclic
            Aromatic Compounds (PAC)."
        )
      ),
      p(
        HTML(
          "It relies on the <a href='https://bcgov.github.io/pahwq'>pacwq</a>
            R package, which uses the <a href='https://github.com/NCAR/TUV'>
            Tropospheric Ultraviolet and Visible (TUV) Radiation Model</a>
            (Madronich 2021) to calculate the light penetration through water of a given depth
            at a given location and date, with a specified attenuation coefficient. This
            coefficient can be calculated from a Dissolved Organic Carbon concentration.
            The light exposure is then used (along with the PAC-specific molar
              absorption across a range of wavelengths), to calculate the light
              absorption (Pabs) of the given PAC at that location. This is then
              used to determine the short-term phototoxic guideline of the PAC under those conditions."
        )
      ),
      p(
        "By default, the app will run the TUV model for 24 hours on the
              given day, with one irradiance calculation per hour at each wavelength.
              When calculating Pabs, total light absorption by the given
              chemical is multiplied by 2 as the standard exposure is 48h for
              determining the narcotic and phototoxic short-term guidelines."
      ),
      h3("Simple and Advanced tabs"),
      p(
        "Both tabs calculate guidelines for a chemical at a location. The
          latitude, longitude, aquatic environment, DOC and chemical carry
          over when you switch between them."
      ),
      h4("Simple"),
      p(
        "The Simple tab needs only a location, an aquatic environment, a DOC
          concentration (freshwater only) and a chemical. It always uses June
          21 of the current year, a water depth of 1 cm, and the default TUV
          settings described below. Because of the date, marine water always
          uses the summer model, and results can shift very slightly from year to
          year."
      ),
      h4("Advanced"),
      p(
        HTML(
          "The Advanced tab starts with the same settings as the Simple tab,
            and every input can be changed, including elevation, date,
            timezone, water depth, \\(k_d(\\lambda_{ref})\\) and \\(S_k\\).
            It also shows the TUV results and run parameters, the DOC and
            depth sensitivity analysis, and the marine model used. Settings
            that only exist in the Advanced tab do not affect the Simple tab."
        )
      ),
      h3("Toxic Units (TU) and Hazard Index (HI)"),
      p(
        "This tab calculates narcotic and phototoxic TUs and HIs for a monitoring
          sample from one site. The site settings are shown at the top of the tab
          and should be set to match the sample. The location, aquatic
          environment and DOC can be changed on the Simple or Advanced tab, and
          all other settings on the Advanced tab."
      ),
      p(
        HTML(
          "Enter the concentrations (&mu;g/L) or upload them as a CSV file with
            the columns <code>pac</code> and <code>concentration_ug_L</code>.
            The template has a row for each PAC. An uploaded file replaces all of
            the values in the table, which can then be edited. Blank cells count
            as 0. If you substitute a value for non-detects, such as half the
            detection limit, enter that value. If the compounds in a homologue
            group, such as C1-Phenanthrenes/Anthracenes, were reported
            separately, add their concentrations together and enter the total."
        )
      ),
      p(
        "For each PAC, a TU is the concentration divided by the short-term
          guideline, and an HI is the concentration divided by the long-term
          guideline. The results for the sample are the sums over all PACs:"
      ),
      p(
        "\\[TU = \\sum_{i=1}^{n} \\frac{\\text{concentration}_i}{\\text{short-term guideline}_i}
          \\qquad
          HI = \\sum_{i=1}^{n} \\frac{\\text{concentration}_i}{\\text{long-term guideline}_i}\\]"
      ),
      h3("Inputs"),
      h4("Location and Date"),
      p(
        "These determine the location and date for which the TUV model
              is run to determine irradiance. The date can be changed in the
              Advanced tab."
      ),
      p(
        HTML(
          "Location is determined by entering latitude and longitude, or by
              clicking a location on the map.
              Elevation is looked up from the location using
              Natural Resources Canada's <a href='https://natural-resources.canada.ca/science-data/data-analysis/geospatial-data-tools-services/elevation-api'>
              Elevation API</a>. It can be entered manually in the
              Advanced tab.
              "
        )
      ),
      p(
        "The aquatic environment is selected from the location: marine
          if it is within one of the marine areas described below, and
          freshwater otherwise. It can be changed manually, and is selected
          again when the location changes. In marine water, elevation is
          set to 0 m."
      ),
      h4("Water parameters"),
      p(
        HTML(
          "These determine the light attenuation through the water at a
            given depth. Light attenuation at each wavelength
            (\\(k_d(\\lambda)\\)) is calculated from the attenuation
            coefficient at a reference wavelength
            (\\(k_d(\\lambda_{ref})\\)) and the slope of its decrease with
            wavelength (\\(S_k\\)):"
        )
      ),
      p(
        HTML(
          "$$k_d(\\lambda) = k_d(\\lambda_{ref})\\,e^{-S_k(\\lambda - \\lambda_{ref})}$$"
        )
      ),
      h5("Freshwater"),
      p(
        HTML(
          "The attenuation coefficient at 305 nm is calculated from the
            Dissolved Organic Carbon (DOC) concentration using the
            following equation from [CCME (20XX)], with
            \\(S_k = 0.018\\) nm<sup>-1</sup>:"
        )
      ),
      p(
        HTML(
          "$$k_{d,305} = a_{305}[DOC]^{b_{305}} + 0.13;\\,a_{305} = 1.28\\text{ and }b_{305} = 1.31$$"
        )
      ),
      p(
        HTML(
          "DOC must be between 0.2 and 61.5 g/m<sup>3</sup>. A value outside
            this range is replaced by the nearest limit, and a notice is
            shown."
        )
      ),
      p(
        HTML(
          "Instead of DOC, you can supply \\(k_d(\\lambda_{ref})\\) and the
            reference wavelength at which it was measured in the 'Other TUV
            parameters' section of the Advanced tab, and \\(S_k\\) can be
            changed there too. The default water depth is 0.01 m, which can
            also be changed in the Advanced tab."
        )
      ),
      h5("Marine water"),
      p(
        HTML(
          "Light attenuation is calculated from models of
            \\(\\log_{10}(k_d)\\) as a linear function of wavelength,
            derived from satellite observations for 21 areas: Canada's
            marine ecoregions, divided into clear and turbid water. There
            is a model for each area and season (winter: December to
            February, spring: March to May, summer: June to August, fall:
            September to November). The area is selected from the location
            and the season from the date. The areas are shown on the map
            when marine water is selected. DOC is not used."
        )
      ),
      p(
        HTML(
          "The models are expressed in the form above with a reference
            wavelength of 375 nm. They were fitted to visible wavelengths
            (up to 490 or 555 nm, depending on the area and season) and are
            extrapolated to shorter wavelengths, down to 280 nm."
        )
      ),
      tags$ul(
        tags$li(
          "If the location is outside the marine areas, the nearest area
            within 25 km is used. Further away, there is no model."
        ),
        tags$li(
          "Some Arctic areas have no model in winter, as there were no
            data."
        ),
        tags$li(
          "A warning is shown when a model was derived from data with
            fewer than 10% valid pixels across the area or over time, as it
            may not be reliable."
        ),
        tags$li(
          HTML(
            "\\(k_d(\\lambda_{ref})\\) and \\(S_k\\) can each be set in the
              'Other TUV parameters' section of the Advanced tab to override
              the model."
          )
        )
      ),
      p(
        "In the Advanced tab, the model used is shown with the results, and
          included in the TUV run parameters and the TUV results download."
      ),
      h4("Other TUV parameters"),
      p(
        "Irradiance is calculated from 280 to 500 nm by default. Ozone
          column and aerosol optical depth are looked up from historic
          climatology based on the date and location entered."
      ),
      h5("Ozone column (DU)"),
      p(
        "The app uses monthly ozone column data from 1980-1991 from
              Fortuin and Kelder (1998), which is bundled with the TUV model.
              Based on latitude and longitude and month, the ozone column value
              is looked up and supplied to the TUV model. It can be supplied
              manually in the Advanced tab to override this behaviour."
      ),
      h5("Aerosol optical depth"),
      p(
        "The app uses average monthly aerosol optical depth data from
              2002 to 2023, obtained from NASA MODIS/Aqua satellite data,
              aggregated to 1 degree latitude and longitude resolution. If no
              value is available for a given month, latitude, and longitude,
              a default value of 0.235 is used.
              It can be supplied manually in the Advanced tab to override this
              behaviour."
      ),
      h3("References"),
      p(
        "[CCME 20XX. Scientific Criteria Document for the development of the
        Canadian Water Quality Guidelines for the protection of aquatic
        life: Polycyclic Aromatic Compounds (PACs) (DRAFT)]"
      ),
      p(
        "Madronich, S. 2021. Tropospheric Ultraviolet and Visible Radiation
        Model (TUV). Retrieved from: ",
        a(
          "https://www2.acom.ucar.edu/modeling/tropospheric-ultraviolet-and-visible-tuv-radiation-model",
          href = "https://www2.acom.ucar.edu/modeling/tropospheric-ultraviolet-and-visible-tuv-radiation-model"
        )
      ),
      p(
        "Paul, J., F. Fortuin, and H. Kelder (1998), An ozone
                climatology based on ozonesonde and satellite measurements,
                J. Geophys. Res., 103(D24), 31709-31734, doi:",
        a(
          "10.1029/1998JD200008.",
          href = "https://doi.org/10.1029/1998JD200008"
        )
      )
    )
  )
}
