test_that("clicking the map sets latitude and longitude", {
  app <- local_app()
  show_tab(app, "Map")

  app$set_inputs(
    map_click = list(lat = 49.15085, lng = -125.91427),
    allow_no_input_binding_ = TRUE,
    wait_ = FALSE
  )
  app$wait_for_idle()

  expect_equal(app$get_value(input = "lat"), 49.15085)
  expect_equal(app$get_value(input = "lon"), -125.91427)
})

test_that("elevation is looked up from the location", {
  skip_if_offline()
  app <- local_app()

  app$set_inputs(
    lat = sites$freshwater$lat,
    lon = sites$freshwater$lon,
    wait_ = FALSE
  )
  app$wait_for_idle()

  expect_equal(
    app$get_value(input = "elev_m"),
    sites$freshwater$elev_m,
    tolerance = 0.05
  )
})
