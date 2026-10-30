test_that("marine guidelines use the ecoregion model and ignore DOC", {
  app <- local_app()
  app$set_inputs(chemical = "anthracene", aq_env = "marine")
  set_site(app, "marine")

  expected <- expected_results("Anthracene", "marine")
  expect_equal(output_number(app, "pabs"), expected$pabs)
  expect_equal(output_number(app, "photo_bench"), expected$photo_bench)
  expect_equal(output_number(app, "photo_cwqg"), expected$photo_cwqg)
  expect_match(
    app$get_text("#kd_model_card"),
    "Southern Shelf ecoregion, turbid water, summer"
  )
  card_height <- app$get_js(
    "document.querySelector('#kd_model_card .card').getBoundingClientRect().height"
  )
  expect_gt(card_height, 50)

  app$set_inputs(doc = 5, wait_ = FALSE)
  app$wait_for_idle()
  expect_equal(output_number(app, "pabs"), expected$pabs)
})

test_that("Kd(ref) overrides the marine model", {
  app <- local_app()
  app$set_inputs(chemical = "anthracene", aq_env = "marine")
  set_site(app, "marine")
  app$set_inputs(kd_ref = 10)

  expected <- expected_results(
    "Anthracene",
    "marine",
    Kd_ref = 10
  )
  expect_equal(output_number(app, "pabs"), expected$pabs)
  expect_equal(output_number(app, "photo_cwqg"), expected$photo_cwqg)
})

test_that("DOC is disabled and Kd(ref) wavelength changes in marine water", {
  app <- local_app()
  doc_disabled <- function() {
    app$get_js("document.getElementById('doc').disabled")
  }
  expect_equal(doc_disabled(), FALSE)
  expect_equal(app$get_value(input = "kd_wvl"), 305)

  app$set_inputs(aq_env = "marine")
  expect_equal(doc_disabled(), TRUE)
  expect_equal(app$get_value(input = "kd_wvl"), 375)
  expect_match(app$get_text("#water_params_note"), "DOC is not used")

  app$set_inputs(aq_env = "freshwater")
  expect_equal(doc_disabled(), FALSE)
  expect_equal(app$get_value(input = "kd_wvl"), 305)
})

test_that("a location far from a marine area shows a clear error", {
  app <- local_app()
  app$set_inputs(chemical = "anthracene")
  set_site(app, "freshwater")
  app$set_inputs(aq_env = "marine", wait_ = FALSE)
  app$wait_for_idle()

  expect_match(
    output_error(app, "pabs"),
    "not within 25 km of an area with a marine Kd model"
  )
})

test_that("a marine area and season with no model shows a clear error", {
  app <- local_app()
  app$set_inputs(chemical = "anthracene", date = "2024-01-15")
  app$set_inputs(
    lat = sites$arctic_basin$lat,
    lon = sites$arctic_basin$lon,
    wait_ = FALSE
  )
  app$wait_for_idle()

  expect_equal(app$get_value(input = "aq_env"), "marine")
  expect_match(
    output_error(app, "pabs"),
    "There is no marine Kd model for Arctic_Basin_Clear in winter"
  )
})

test_that("a low-confidence marine model shows a warning", {
  app <- local_app()
  app$set_inputs(chemical = "anthracene", date = "2024-01-15")
  app$set_inputs(
    lat = sites$labrador_shelf$lat,
    lon = sites$labrador_shelf$lon,
    wait_ = FALSE
  )
  app$wait_for_idle()

  expect_equal(app$get_value(input = "aq_env"), "marine")
  expect_match(
    app$get_text(".shiny-notification"),
    "fewer than 10% valid pixels over time",
    all = FALSE
  )
  expect_match(
    app$get_text("#kd_model_card"),
    "Low confidence"
  )
  expect_null(output_error(app, "pabs"))
  expect_length(output_number(app, "pabs"), 1)
})

test_that("depth defaults to 1 cm and keeps a depth the user entered", {
  app <- local_app()
  expect_equal(app$get_value(input = "depth_m"), 0.01)

  set_site(app, "marine")
  expect_equal(app$get_value(input = "depth_m"), 0.01)

  app$set_inputs(depth_m = 0.05)
  set_site(app, "freshwater")
  expect_equal(app$get_value(input = "depth_m"), 0.05)
})

test_that("the TUV run parameters include the marine model", {
  app <- local_app()
  set_site(app, "marine")
  show_tab(app, "TUV Run Parameters")

  expect_match(
    app$get_value(output = "tuv_params")$html,
    "<th>ecoregion</th>\\s*<td>Southern Shelf</td>"
  )
})
