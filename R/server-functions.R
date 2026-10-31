run_sens <- function(input) {
  dates <- as.Date(
    paste(req(input$sens_year), req(input$sens_months), "21", sep = "-"),
    format = "%Y-%B-%d"
  )

  if (input$doc_or_kd == "doc") {
    doc <- seq(
      input$sens_doc[1],
      input$sens_doc[2],
      length.out = input$doc_steps
    )
    kd <- NULL
  } else {
    kd <- seq(input$sens_kd[1], input$sens_kd[2], length.out = input$kd_steps)
    doc <- NULL
  }

  depth <- seq(
    input$sens_depth[1],
    input$sens_depth[2],
    length.out = input$depth_steps
  )

  kd_wvl_reactive <- reactive(x_or_null(input$kd_wvl))

  o3_tc_reactive <- reactive(x_or_null(input$o3_tc))

  tauaer_reactive <- reactive(x_or_null(input$tauaer))

  local_tuv_dir()
  out <- sens_kd_depth(
    pah = req(input$chemical),
    lat = req(input$lat),
    lon = req(input$lon),
    elev_m = req(input$elev_m),
    date = dates,
    time_multiplier = req(input$multiplier),
    DOC = doc,
    Kd_ref = kd,
    depth_m = depth,
    tzone = req(input$tzone),
    Kd_wvl = kd_wvl_reactive(),
    tstart = req(input$tstart),
    tstop = req(input$tstop),
    tsteps = req(input$tsteps),
    wvl_start = req(input$wvl_start),
    wvl_end = req(input$wvl_end),
    o3_tc = o3_tc_reactive(),
    tauaer = tauaer_reactive()
  )

  plot_sens_kd_depth(
    out,
    interactive = TRUE,
    options = list(
      ggiraph::opts_selection(type = "none"),
      ggiraph::opts_sizing(width = 1, rescale = TRUE)
    )
  )
}

update_elevation <- function(input, marine) {
  # calculation pauses until the browser confirms the switch
  freezeReactiveValue(input, "elev_m")
  updateNumericInput(
    inputId = "elev_m",
    value = site_elevation(input$lat, input$lon, marine)
  )
}

x_or_null <- function(x) {
  if (!isTruthy(x)) NULL else x
}

# Runs tuv(), showing its messages and warnings (e.g., DOC clamped to the valid
# range) as notifications. pahwq's errors (e.g., no marine Kd model for the
# location) are shown as validation messages, as Shiny hides error messages in
# deployed apps. Errors from req() and validate() are passed through unchanged.
run_tuv <- function(...) {
  tryCatch(
    withCallingHandlers(
      tuv(..., quiet = TRUE),
      message = function(m) {
        showNotification(conditionMessage(m), type = "message")
        invokeRestart("muffleMessage")
      },
      warning = function(w) {
        showNotification(conditionMessage(w), type = "warning")
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      if (inherits(e, "validation")) {
        stop(e)
      }
      validate(conditionMessage(e))
    }
  )
}

# The outputs of `result_boxes()` and `multi_tox_panel()`, in a calculator
# module
result_outputs <- function(input, output, session, irrad, multiplier) {
  pabs <- reactive(
    p_abs(irrad(), req(input$chemical), time_multiplier = req(multiplier()))
  )

  output$pabs <- renderText({
    paste(
      "<p>",
      round(pabs(), 3),
      '</br><span class="small">mol photons/mol PAH</span></p>'
    )
  })

  box_title <- function(title) {
    renderText(glue::glue(
      "<p><em>{aq_env}</em> {title}</p>",
      aq_env = tools::toTitleCase(input$aq_env)
    ))
  }
  box_value <- function(value) {
    renderText(glue::glue("<p>{round(value(), 3)} &mu;g/L</p>"))
  }

  output$narc_bench_title <- box_title("short-term NLC50<sub>(5)</sub>")
  output$narc_bench <- box_value(\() narcotic_benchmark(req(input$chemical)))
  output$narc_cwqg_title <- box_title("narcotic CWQG")
  output$narc_cwqg <- box_value(\() narcotic_cwqg(req(input$chemical)))
  output$photo_bench_title <- box_title("short-term PLC50<sub>(5)</sub>")
  output$photo_bench <- box_value(
    \() phototoxic_benchmark(pabs(), pah = req(input$chemical))
  )
  output$photo_cwqg_title <- box_title("phototoxic CWQG")
  output$photo_cwqg <- box_value(
    \() phototoxic_cwqg(pabs(), pah = req(input$chemical))
  )

  multi_tox <- reactive({
    multi_tox_table(req(irrad()), time_multiplier = req(multiplier()))
  })

  output$multi_tox <- DT::renderDT({
    DT::datatable(req(multi_tox())) |>
      DT::formatRound(
        columns = c(
          "narcotic_benchmark",
          "narcotic_cwqg",
          "phototoxic_benchmark",
          "phototoxic_cwqg"
        ),
        digits = 3
      ) |>
      DT::formatRound(columns = "pabs", digits = 5)
  })

  output$multi_tox_download_btn <- renderUI({
    req(multi_tox())
    downloadButton(
      session$ns("multi_tox_download"),
      "Download results to csv",
      class = "btn-primary m-2"
    )
  })

  output$multi_tox_download <- downloadHandler(
    filename = function() {
      paste0(
        "phototoxic-wq-multi-results-",
        input$aq_env,
        "_",
        Sys.Date(),
        ".csv"
      )
    },
    content = function(file) {
      utils::write.csv(multi_tox(), file, row.names = FALSE, na = "")
    }
  )
}

shared_ids <- c("lat", "lon", "aq_env", "doc", "chemical")

# Keeps the location, aquatic environment, DOC and chemical the same on the Simple and
# Advanced tabs: the active tab saves them in `shared`, and a tab loads them
# when it is selected.
share_inputs <- function(input, shared, active) {
  for (id in shared_ids) {
    local({
      id <- id
      # Lower priority than the observers that respond to the input, so they
      # can tell a new value from one loaded from `shared`
      observeEvent(
        input[[id]],
        if (active()) shared[[id]] <- input[[id]],
        ignoreNULL = FALSE,
        priority = -1
      )
    })
  }

  observeEvent(active(), {
    req(active())
    for (id in shared_ids) {
      value <- shared[[id]]
      if (is.null(value) || same_value(value, input[[id]])) {
        next
      }
      # calculation pauses until the browser confirms the update
      freezeReactiveValue(input, id)
      if (id == "aq_env") {
        updateRadioButtons(inputId = id, selected = value)
      } else if (id == "chemical") {
        updateSelectInput(inputId = id, selected = value)
      } else {
        updateNumericInput(inputId = id, value = value)
      }
    }
  })
}

# Whether the location was loaded from the other tab, rather than entered
from_shared <- function(input, shared) {
  same_value(input$lat, shared$lat) && same_value(input$lon, shared$lon)
}

same_value <- function(x, y) {
  if (is.character(x) || is.character(y)) {
    return(identical(x, y))
  }
  isTRUE(all.equal(as.numeric(x), as.numeric(y)))
}

# Selects the aquatic environment from the location: marine in a marine area,
# freshwater otherwise. Returns whether it changed.
select_aq_env <- function(input, area) {
  aq_env <- if (is.null(area)) "freshwater" else "marine"
  if (aq_env == input$aq_env) {
    return(FALSE)
  }
  # calculation pauses until the browser confirms the switch
  freezeReactiveValue(input, "aq_env")
  updateRadioButtons(inputId = "aq_env", selected = aq_env)
  TRUE
}

# June 21 of the current year, the date of the Simple calculator
simple_date <- function(today = Sys.Date()) {
  as.Date(paste0(format(today, "%Y"), "-06-21"))
}
