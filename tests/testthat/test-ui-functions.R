test_that("kd_model_card() describes the model", {
  card <- as.character(kd_model_card(fake_kd_model()))
  expect_match(card, "<b>Strait of Georgia</b> ecoregion, turbid water, summer")
  expect_match(card, "K<sub>d</sub>\\(375\\) = 1.158 m<sup>-1</sup>")
  expect_match(card, "S<sub>k</sub> = 0.0125 nm<sup>-1</sup>")
  expect_match(card, "R<sup>2</sup> = 0.95")
  expect_no_match(card, "<ul>")
})

test_that("kd_model_card() notes overrides, distance and quality flags", {
  card <- as.character(kd_model_card(
    fake_kd_model(dist_km = 1.66, vpf_time = TRUE),
    kd_ref_set = TRUE
  ))
  expect_match(card, "set by the user")
  expect_match(card, "nearest area \\(1.7 km away\\)")
  expect_match(card, "fewer than 10% valid pixels over time")

  card <- as.character(kd_model_card(
    fake_kd_model(vpf_area = TRUE, vpf_time = TRUE)
  ))
  expect_match(card, "valid pixels across the area and over time")
})
