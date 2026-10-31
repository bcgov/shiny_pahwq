test_that("Simple calculates freshwater guidelines for June 21 at 1 cm", {
  app <- local_app()
  app$set_inputs(
    `simple-chemical` = "anthracene",
    `simple-lat` = sites$freshwater$lat,
    `simple-lon` = sites$freshwater$lon,
    `simple-doc` = 5
  )

  expected <- expected_results(
    "Anthracene",
    "freshwater",
    DOC = 5,
    date = simple_date()
  )
  expect_equal(output_number(app, "simple-pabs"), expected$pabs)
  expect_equal(output_number(app, "simple-photo_bench"), expected$photo_bench)
  expect_equal(output_number(app, "simple-photo_cwqg"), expected$photo_cwqg)
})

test_that("Simple selects marine water from the location and disables DOC", {
  app <- local_app()
  app$set_inputs(
    `simple-chemical` = "anthracene",
    `simple-lat` = sites$marine$lat,
    `simple-lon` = sites$marine$lon,
    wait_ = FALSE
  )
  app$wait_for_idle()

  expect_equal(app$get_value(input = "simple-aq_env"), "marine")
  expect_equal(
    app$get_js("document.getElementById('simple-doc').disabled"),
    TRUE
  )
  expected <- expected_results(
    "Anthracene",
    "marine",
    date = simple_date()
  )
  expect_equal(output_number(app, "simple-pabs"), expected$pabs)
  expect_no_match(
    app$get_text(".tab-pane[data-value='Simple']"),
    "Marine light attenuation model"
  )
})

test_that("location, DOC and chemical carry over between Simple and Advanced", {
  app <- local_app()
  app$set_inputs(
    `simple-chemical` = "anthracene",
    `simple-lat` = sites$freshwater$lat,
    `simple-lon` = sites$freshwater$lon,
    `simple-doc` = 5,
    wait_ = FALSE
  )
  app$wait_for_idle()

  show_tab(app, "Advanced")
  expect_equal(app$get_value(input = "advanced-chemical"), "anthracene")
  expect_equal(app$get_value(input = "advanced-lat"), sites$freshwater$lat)
  expect_equal(app$get_value(input = "advanced-lon"), sites$freshwater$lon)
  expect_equal(app$get_value(input = "advanced-doc"), 5)
  expect_equal(app$get_value(input = "advanced-elev_m"), 515)
  expected <- expected_results(
    "Anthracene",
    "freshwater",
    DOC = 5,
    date = simple_date()
  )
  expect_equal(output_number(app, "advanced-pabs"), expected$pabs)

  app$set_inputs(`advanced-chemical` = "pyrene")
  set_site(app, "marine")
  show_tab(app, "Simple")
  expect_equal(app$get_value(input = "simple-chemical"), "pyrene")
  expect_equal(app$get_value(input = "simple-lat"), sites$marine$lat)
  expect_equal(app$get_value(input = "simple-lon"), sites$marine$lon)
  expect_equal(app$get_value(input = "simple-aq_env"), "marine")
})

test_that("a manually selected aquatic environment carries over", {
  app <- local_app()
  app$set_inputs(
    `simple-lat` = sites$nearshore$lat,
    `simple-lon` = sites$nearshore$lon,
    wait_ = FALSE
  )
  app$wait_for_idle()
  expect_equal(app$get_value(input = "simple-aq_env"), "freshwater")
  app$set_inputs(`simple-aq_env` = "marine", wait_ = FALSE)
  app$wait_for_idle()

  show_tab(app, "Advanced")
  expect_equal(app$get_value(input = "advanced-lat"), sites$nearshore$lat)
  expect_equal(app$get_value(input = "advanced-aq_env"), "marine")
  expect_equal(app$get_value(input = "advanced-elev_m"), 0)
})
