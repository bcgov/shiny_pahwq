fake_kd_model <- function(...) {
  kd_model <- data.frame(
    area = "Strait_of_Georgia_Turbid",
    ecoregion = "Strait of Georgia",
    water_type = "turbid",
    season = "summer",
    Kd_ref = 1.15809,
    Kd_wvl = 375L,
    Sk = 0.0124955,
    r2 = 0.949951384,
    nodata = FALSE,
    peak = FALSE,
    vpf_area = FALSE,
    vpf_time = FALSE,
    dist_km = 0
  )
  utils::modifyList(kd_model, list(...))
}
