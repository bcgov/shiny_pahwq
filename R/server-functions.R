run_sens <- function(input) {
  dates <- as.Date(
    paste(req(input$sens_year), req(input$sens_months), "21", sep = "-"),
    format = "%Y-%B-%d"
  )

  doc <- seq(req(input$sens_doc_min), req(input$sens_doc_max), length.out = input$doc_steps)
  depth <- seq(req(input$sens_depth_min), req(input$sens_depth_max), length.out = input$depth_steps)
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
