test_that("the login page doesn't crash the app", {
  app <- local_app(auth = TRUE)

  expect_equal(app$get_js("Shiny.shinyapp.isConnected()"), TRUE)
})

test_that("narcotic guidelines appear once a chemical is chosen", {
  app <- local_app()

  expect_equal(output_error(app, "advanced-narc_bench"), "")
  expect_equal(output_error(app, "advanced-narc_cwqg"), "")

  app$set_inputs(`advanced-chemical` = "anthracene")

  expect_equal(
    output_number(app, "advanced-narc_bench"),
    round(pahwq::narcotic_benchmark("Anthracene"), 3)
  )
  expect_equal(
    output_number(app, "advanced-narc_cwqg"),
    round(pahwq::narcotic_cwqg("Anthracene"), 3)
  )
})

test_that("phototoxic outputs wait for a location and water parameters", {
  app <- local_app()
  app$set_inputs(`advanced-chemical` = "anthracene")

  expect_equal(output_error(app, "advanced-pabs"), "")
  expect_equal(output_error(app, "advanced-photo_bench"), "")
  expect_equal(output_error(app, "advanced-photo_cwqg"), "")
})

test_that("value box titles follow the aquatic environment", {
  app <- local_app()
  titles <- c(
    "advanced-narc_bench_title",
    "advanced-narc_cwqg_title",
    "advanced-photo_bench_title",
    "advanced-photo_cwqg_title"
  )

  for (id in titles) {
    expect_match(app$get_value(output = id), "<em>Freshwater</em>")
  }

  app$set_inputs(`advanced-aq_env` = "marine")

  for (id in titles) {
    expect_match(app$get_value(output = id), "<em>Marine</em>")
  }
})
