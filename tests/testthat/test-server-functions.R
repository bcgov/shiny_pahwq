test_that("simple_date() is June 21 of the current year", {
  expect_equal(simple_date(as.Date("2027-01-05")), as.Date("2027-06-21"))
})

test_that("same_value() compares inputs, treating empty values as equal", {
  expect_equal(same_value(5, 5L), TRUE)
  expect_equal(same_value(NA, NA_real_), TRUE)
  expect_equal(same_value(NA, 5), FALSE)
  expect_equal(same_value(NULL, 5), FALSE)
  expect_equal(same_value("marine", "marine"), TRUE)
  expect_equal(same_value("marine", "freshwater"), FALSE)
})

test_that("require_elevation() accepts sea level but not a missing elevation", {
  expect_equal(require_elevation(0), 0)
  expect_equal(require_elevation(515), 515)
  expect_error(require_elevation(NA_real_), class = "validation")
  expect_error(require_elevation(NULL), class = "validation")
})

test_that("require_attenuation() names what is missing", {
  expect_no_error(require_attenuation(TRUE, "DOC"))
  expect_error(
    require_attenuation(FALSE, "DOC or Kd(ref)"),
    "Enter DOC or Kd\\(ref\\) to calculate results",
    class = "validation"
  )
})

test_that("tuv_inputs() has arguments of tuv() and leaves DOC as entered", {
  inputs <- tuv_inputs(list(aq_env = "freshwater", doc = 100, multiplier = 2))
  expect_in(names(inputs), names(formals(tuv)))
  expect_equal(inputs$DOC, 100)
})

test_that("advanced_settings() only includes inputs used in the TUV run", {
  input <- list(
    lat = 50,
    lon = NA_real_,
    aq_env = "marine",
    doc = 5,
    kd_wvl = 375,
    multiplier = 2
  )
  settings <- advanced_settings(input)
  expect_equal(settings$lat, 50)
  expect_null(settings$lon)
  expect_null(settings$DOC)
  expect_null(settings$Kd_wvl)
  expect_equal(settings$time_multiplier, 2)

  input$aq_env <- "freshwater"
  input$kd_ref <- 10
  settings <- advanced_settings(input)
  expect_equal(settings$DOC, 5)
  expect_equal(settings$Kd_wvl, 375)

  input$doc <- 100
  expect_no_warning(settings <- advanced_settings(input))
  expect_equal(settings$DOC, doc_range()[2])
})
