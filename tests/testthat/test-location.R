test_that("moving from a marine location to land calculates for freshwater", {
  app <- local_app()
  app$set_inputs(`advanced-chemical` = "anthracene", `advanced-doc` = 5)
  set_site(app, "marine")
  expect_equal(app$get_value(input = "advanced-aq_env"), "marine")

  # Record any error shown in between, not just the final state
  app$run_js(
    "window.pabsErrored = false;
    new MutationObserver(function() {
      if (document.getElementById('advanced-pabs').classList.contains('shiny-output-error')) {
        window.pabsErrored = true;
      }
    }).observe(document.getElementById('advanced-pabs'), {attributes: true});"
  )
  set_site(app, "freshwater")
  expect_equal(app$get_value(input = "advanced-aq_env"), "freshwater")
  expect_equal(app$get_js("window.pabsErrored"), FALSE)

  expected <- expected_results("Anthracene", "freshwater", DOC = 5)
  expect_equal(output_number(app, "advanced-pabs"), expected$pabs)
})

test_that("marine can be selected manually for a nearshore location", {
  app <- local_app()
  app$set_inputs(
    `advanced-chemical` = "anthracene",
    `advanced-date` = "2024-06-21"
  )
  app$set_inputs(
    `advanced-lat` = sites$nearshore$lat,
    `advanced-lon` = sites$nearshore$lon,
    wait_ = FALSE
  )
  app$wait_for_idle()
  expect_equal(app$get_value(input = "advanced-aq_env"), "freshwater")

  app$set_inputs(`advanced-aq_env` = "marine", wait_ = FALSE)
  app$wait_for_idle()
  expect_equal(app$get_value(input = "advanced-aq_env"), "marine")
  expect_equal(app$get_value(input = "advanced-elev_m"), 0)
  expect_match(
    app$get_text(".shiny-notification"),
    "using the nearest area",
    all = FALSE
  )
  expect_null(output_error(app, "advanced-pabs"))
  expect_length(output_number(app, "advanced-pabs"), 1)

  app$set_inputs(`advanced-depth_m` = 0.02, wait_ = FALSE)
  app$wait_for_idle()
  expect_equal(app$get_value(input = "advanced-aq_env"), "marine")
})

test_that("elevation is looked up, or 0 in marine water", {
  app <- local_app()
  app$set_inputs(
    `advanced-lat` = sites$freshwater$lat,
    `advanced-lon` = sites$freshwater$lon,
    wait_ = FALSE
  )
  app$wait_for_idle()
  expect_equal(
    app$get_value(input = "advanced-elev_m"),
    sites$freshwater$elev_m
  )

  app$set_inputs(`advanced-aq_env` = "marine")
  expect_equal(app$get_value(input = "advanced-elev_m"), 0)

  app$set_inputs(`advanced-aq_env` = "freshwater", wait_ = FALSE)
  app$wait_for_idle()
  expect_equal(
    app$get_value(input = "advanced-elev_m"),
    sites$freshwater$elev_m
  )
})
