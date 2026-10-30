test_that("the login page doesn't crash the app", {
  app <- local_app(auth = TRUE)

  expect_equal(app$get_js("Shiny.shinyapp.isConnected()"), TRUE)
})

test_that("narcotic guidelines appear once a chemical is chosen", {
  app <- local_app()

  expect_equal(output_error(app, "narc_bench"), "")
  expect_equal(output_error(app, "narc_cwqg"), "")

  app$set_inputs(chemical = "anthracene")

  expect_equal(
    output_number(app, "narc_bench"),
    round(pahwq::narcotic_benchmark("Anthracene"), 3)
  )
  expect_equal(
    output_number(app, "narc_cwqg"),
    round(pahwq::narcotic_cwqg("Anthracene"), 3)
  )
})

test_that("phototoxic outputs wait for a location and water parameters", {
  app <- local_app()
  app$set_inputs(chemical = "anthracene")

  expect_equal(output_error(app, "pabs"), "")
  expect_equal(output_error(app, "photo_bench"), "")
  expect_equal(output_error(app, "photo_cwqg"), "")
})

test_that("value box titles follow the aquatic environment", {
  app <- local_app()
  titles <- c(
    "narc_bench_title",
    "narc_cwqg_title",
    "photo_bench_title",
    "photo_cwqg_title"
  )

  for (id in titles) {
    expect_match(app$get_value(output = id), "<em>Freshwater</em>")
  }

  app$set_inputs(aq_env = "marine")

  for (id in titles) {
    expect_match(app$get_value(output = id), "<em>Marine</em>")
  }
})
