run_sens <- function(input) {
  dates <- as.Date(
    paste(req(input$sens_year), req(input$sens_months), "21", sep = "-"),
    format = "%Y-%B-%d"
  )

  doc <- seq(input$sens_doc[1], input$sens_doc[2], length.out = input$doc_steps)
  depth <- seq(input$sens_depth[1], input$sens_depth[2], length.out = input$depth_steps)
  # kd <- seq(req(input$sens_kd_min), req(input$sens_kd_max), length.out = input$kd_steps)

  local_tuv_dir()
  out <- sens_kd_depth(
    pah = req(input$chemical),
    lat = req(input$lat),
    lon = req(input$lon),
    elev_m = req(input$elev_m),
    date = dates,
    DOC = doc,
    Kd_ref = NULL,
    depth_m = depth
  )
  # tzone = req(input$tzone),
  # Kd_wvl = tuv_inputs$kd_wvl,
  # tstart = req(input$tstart),
  # tstop = req(input$tstop),
  # tsteps = req(input$tsteps),
  # wvl_start = req(input$wvl_start),
  # wvl_end = req(input$wvl_end),
  # o3_tc = tuv_inputs$o3_tc,
  # tauaer = tuv_inputs$tauaer,

  plot_sens_kd_depth(
    out,
    interactive = TRUE,
    options = list(
      ggiraph::opts_selection(type = "none")
    )
  )

}

x_or_null <- function(x) {
    if (!isTruthy(x)) NULL else x
}
