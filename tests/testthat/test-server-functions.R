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
