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

## usethis namespace: start
#' @import shiny
#' @import bslib
#' @import pahwq
## usethis namespace: end
NULL

#' Run the app
#'
#' @param auth Should the app be protected by a login page? The credentials
#'   are read from the `PACWQ_USER` and `PACWQ_PASSWORD` environment
#'   variables (see [app_credentials()]).
#' @param ... Passed on to [shiny::shinyApp()].
#'
#' @noRd
run_app <- function(auth = TRUE, ...) {
  addResourcePath("www", system.file("www/", package = "pacwq.shiny"))

  if (!auth) {
    return(shinyApp(ui = ui, server = server, ...))
  }

  # The credentials are read once, at startup, so that a missing or empty
  # environment variable stops the app rather than silently locking users out.
  credentials <- app_credentials()

  # secure_app() calls the ui function with the request object, whereas ui()
  # takes no arguments, hence the wrapper.
  secure_ui <- shinymanager::secure_app(
    function(request) ui(),
    theme = bs_theme(version = 5, bootswatch = "cerulean")
  )

  secure_server <- function(input, output, session) {
    shinymanager::secure_server(
      check_credentials = shinymanager::check_credentials(credentials)
    )
    server(input, output, session)
  }

  shinyApp(ui = secure_ui, server = secure_server, ...)
}

#' Build the credentials table used by the login page
#'
#' The app is protected by a single shared username and password, read in
#' plain text from the `PACWQ_USER` and `PACWQ_PASSWORD` environment
#' variables.
#'
#' @noRd
app_credentials <- function() {
  user <- Sys.getenv("PACWQ_USER")
  password <- Sys.getenv("PACWQ_PASSWORD")

  if (!nzchar(user) || !nzchar(password)) {
    stop(
      "The environment variables `PACWQ_USER` and `PACWQ_PASSWORD` ",
      "must be set to run the app with authentication. ",
      "Set them in your `~/.Renviron` file, or use `run_app(auth = FALSE)`.",
      call. = FALSE
    )
  }

  data.frame(
    user = user,
    password = password,
    stringsAsFactors = FALSE
  )
}
