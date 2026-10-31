test_that("guidelines calculated from DOC match pahwq", {
  app <- local_app()
  app$set_inputs(`advanced-chemical` = "anthracene")
  set_site(app, "freshwater")
  app$set_inputs(`advanced-doc` = 5)

  expected <- expected_results("Anthracene", "freshwater", DOC = 5)
  expect_equal(output_number(app, "advanced-pabs"), expected$pabs)
  expect_equal(output_number(app, "advanced-photo_bench"), expected$photo_bench)
  expect_equal(output_number(app, "advanced-photo_cwqg"), expected$photo_cwqg)
  expect_equal(app$get_text("#advanced-kd_model_card"), "")
})

test_that("the TUV results multiplier is applied to Pabs", {
  app <- local_app()
  app$set_inputs(`advanced-chemical` = "anthracene")
  set_site(app, "freshwater")
  app$set_inputs(`advanced-doc` = 5, `advanced-multiplier` = 1)

  expected <- expected_results(
    "Anthracene",
    "freshwater",
    DOC = 5,
    multiplier = 1
  )
  expect_equal(output_number(app, "advanced-pabs"), expected$pabs)
  expect_equal(output_number(app, "advanced-photo_cwqg"), expected$photo_cwqg)
})

test_that("guidelines calculated from Kd(ref) match pahwq", {
  app <- local_app()
  app$set_inputs(`advanced-chemical` = "anthracene")
  set_site(app, "freshwater")
  app$set_inputs(`advanced-kd_ref` = 10)

  expected <- expected_results("Anthracene", "freshwater", Kd_ref = 10)
  expect_equal(output_number(app, "advanced-pabs"), expected$pabs)
  expect_equal(output_number(app, "advanced-photo_bench"), expected$photo_bench)
  expect_equal(output_number(app, "advanced-photo_cwqg"), expected$photo_cwqg)
})

test_that("DOC and Kd(ref) can't both be supplied", {
  app <- local_app()
  app$set_inputs(`advanced-chemical` = "anthracene")
  set_site(app, "freshwater")
  app$set_inputs(`advanced-doc` = 5, `advanced-kd_ref` = 10)

  expect_equal(
    output_error(app, "advanced-pabs"),
    "Only one of DOC or Kd(ref) may be chosen"
  )
})

test_that("out of range DOC warns and is replaced with the maximum", {
  app <- local_app()
  app$set_inputs(`advanced-chemical` = "anthracene")
  set_site(app, "freshwater")
  app$set_inputs(`advanced-doc` = 100)

  expect_match(
    app$get_text(".shiny-notification"),
    "greater than the maximum valid DOC",
    all = FALSE
  )

  expected <- expected_results("Anthracene", "freshwater", DOC = doc_range()[2])
  expect_equal(output_number(app, "advanced-pabs"), expected$pabs)
})
