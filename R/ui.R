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
      includeMarkdown(system.file("help/en.md", package = "pacwq.shiny")),
      version_info()
    )
  )
}
