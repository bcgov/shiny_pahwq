run_sens <- function(input) {
  dates <- as.Date(
    paste(req(input$sens_year), req(input$sens_months), "21", sep = "-"),
    format = "%Y-%B-%d"
  )

  if (input$doc_or_kd == "doc") {
    doc <- seq(input$sens_doc[1], input$sens_doc[2], length.out = input$doc_steps)
    kd <- NULL
  } else {
    kd <- seq(input$sens_kd[1], input$sens_kd[2], length.out = input$kd_steps)
    doc <- NULL
  }

  depth <- seq(input$sens_depth[1], input$sens_depth[2], length.out = input$depth_steps)

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

x_or_null <- function(x) {
    if (!isTruthy(x)) NULL else x
}
