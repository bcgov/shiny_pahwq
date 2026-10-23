test_that("marine guidelines match pahwq and ignore DOC", {
  app <- local_app()
  app$set_inputs(chemical = "Anthracene", aq_env = "marine")
  set_site(app, "marine")
  app$set_inputs(depth_m = 0.01)

  expect_match(
    app$get_text(".shiny-notification"),
    "ignored for marine calculations",
    all = FALSE
  )

  expected <- expected_results("Anthracene", "marine", depth_m = 0.01)
  expect_equal(output_number(app, "pabs"), expected$pabs)
  expect_equal(output_number(app, "photo_bench"), expected$photo_bench)
  expect_equal(output_number(app, "photo_cwqg"), expected$photo_cwqg)

  app$set_inputs(doc = 5, wait_ = FALSE)
  app$wait_for_idle()
  expect_equal(output_number(app, "pabs"), expected$pabs)
})
