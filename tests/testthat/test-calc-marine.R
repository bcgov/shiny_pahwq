test_that("marine guidelines use the ecoregion model and ignore DOC", {
  app <- local_app(tab = "Advanced")
  app$set_inputs(
    `advanced-chemical` = "anthracene",
    `advanced-aq_env` = "marine"
  )
  set_site(app, "marine")

  expected <- expected_results("Anthracene", "marine")
  expect_equal(output_number(app, "advanced-pabs"), expected$pabs)
  expect_equal(output_number(app, "advanced-photo_bench"), expected$photo_bench)
  expect_equal(output_number(app, "advanced-photo_cwqg"), expected$photo_cwqg)
  expect_match(
    app$get_text("#advanced-kd_model_card"),
    "Southern Shelf ecoregion, turbid water, summer"
  )
  card_height <- app$get_js(
    "document.querySelector('#advanced-kd_model_card .card').getBoundingClientRect().height"
  )
  expect_gt(card_height, 50)

  app$set_inputs(`advanced-doc` = 5, wait_ = FALSE)
  app$wait_for_idle()
  expect_equal(output_number(app, "advanced-pabs"), expected$pabs)
})

test_that("Kd(ref) overrides the marine model", {
  app <- local_app(tab = "Advanced")
  app$set_inputs(
    `advanced-chemical` = "anthracene",
    `advanced-aq_env` = "marine"
  )
  set_site(app, "marine")
  app$set_inputs(`advanced-kd_ref` = 10)

  expected <- expected_results(
    "Anthracene",
    "marine",
    Kd_ref = 10
  )
  expect_equal(output_number(app, "advanced-pabs"), expected$pabs)
  expect_equal(output_number(app, "advanced-photo_cwqg"), expected$photo_cwqg)
})

test_that("DOC is disabled and Kd(ref) wavelength changes in marine water", {
  app <- local_app(tab = "Advanced")
  doc_disabled <- function() {
    app$get_js("document.getElementById('advanced-doc').disabled")
  }
  expect_equal(doc_disabled(), FALSE)
  expect_equal(app$get_value(input = "advanced-kd_wvl"), 305)

  app$set_inputs(`advanced-aq_env` = "marine")
  expect_equal(doc_disabled(), TRUE)
  expect_equal(app$get_value(input = "advanced-kd_wvl"), 375)
  expect_match(app$get_text("#advanced-water_params_note"), "DOC is not used")

  app$set_inputs(`advanced-aq_env` = "freshwater")
  expect_equal(doc_disabled(), FALSE)
  expect_equal(app$get_value(input = "advanced-kd_wvl"), 305)
})

test_that("a location far from a marine area shows a clear error", {
  app <- local_app(tab = "Advanced")
  app$set_inputs(`advanced-chemical` = "anthracene")
  set_site(app, "freshwater")
  app$set_inputs(`advanced-aq_env` = "marine", wait_ = FALSE)
  app$wait_for_idle()

  expect_match(
    output_error(app, "advanced-pabs"),
    "not within 25 km of an area with a marine Kd model"
  )
})

test_that("the TUV run parameters include the marine model", {
  app <- local_app(tab = "Advanced")
  set_site(app, "marine")
  show_tab(app, "TUV Run Parameters")

  expect_match(
    app$get_value(output = "advanced-tuv_params")$html,
    "<th>ecoregion</th>\\s*<td>Southern Shelf</td>"
  )
})
