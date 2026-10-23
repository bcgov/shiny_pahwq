test_that("in_marine_area() finds marine locations", {
  expect_equal(in_marine_area(sites$marine$lat, sites$marine$lon), TRUE)
  expect_equal(
    in_marine_area(sites$freshwater$lat, sites$freshwater$lon),
    FALSE
  )
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
