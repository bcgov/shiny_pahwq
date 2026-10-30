test_that("marine_area_at() finds the containing or nearest marine area", {
  expect_equal(
    marine_area_at(sites$marine$lat, sites$marine$lon)$water_type,
    "turbid"
  )
  expect_null(marine_area_at(sites$nearshore$lat, sites$nearshore$lon))
  expect_equal(
    marine_area_at(
      sites$nearshore$lat,
      sites$nearshore$lon,
      nearest = TRUE
    )$area,
    "Strait_of_Georgia_Turbid"
  )
  expect_null(
    marine_area_at(sites$freshwater$lat, sites$freshwater$lon, nearest = TRUE)
  )
  expect_null(marine_area_at(NA, NA))
})

test_that("site_elevation() is 0 in marine water without a lookup", {
  local_mocked_bindings(get_elevation = function(...) stop("looked up"))
  expect_equal(site_elevation(49, -125, marine = TRUE), 0)
  expect_equal(site_elevation(NA, NA, marine = TRUE), 0)
})

test_that("site_elevation() looks up elevation in freshwater", {
  local_mocked_bindings(get_elevation = function(lon, lat) lon + lat)
  expect_equal(site_elevation(50, -100, marine = FALSE), -50)
})

test_that("site_elevation() is NA without a location or a lookup", {
  local_mocked_bindings(get_elevation = function(...) stop("no service"))
  expect_equal(site_elevation(NA, -100, marine = FALSE), NA_real_)
  expect_equal(site_elevation(NULL, -100, marine = FALSE), NA_real_)
  expect_equal(site_elevation(50, -100, marine = FALSE), NA_real_)
})

test_that("tuv_results_export() adds the marine Kd model as columns", {
  res <- data.frame(wl = c(280, 281), t_12 = c(0.1, 0.2))
  expect_equal(tuv_results_export(res), res)

  attr(res, "kd_model") <- fake_kd_model()
  exported <- tuv_results_export(res)
  expect_named(
    exported,
    c(
      "wl",
      "t_12",
      paste0("marine_kd_model_", setdiff(names(fake_kd_model()), "area"))
    )
  )
  expect_equal(exported$marine_kd_model_ecoregion, rep("Strait of Georgia", 2))
  expect_equal(exported$marine_kd_model_Kd_ref, rep(1.15809, 2))
})

test_that("chemical_list() has one entry per PAC shown in the app", {
  chems <- chemical_list()
  expect_length(chems, 47)
  expect_setequal(names(chems), pac_list(app_only = TRUE)$pac)
  expect_equal(
    chems[["C1-Benz(a)anthracenes/Chrysenes"]],
    "c1-benzo(a)anthracenes"
  )
  expect_equal(chems[["Benzo(a)pyrene"]], "benzo(a)pyrene")
})
