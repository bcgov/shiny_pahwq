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
    kd_ref_set = TRUE,
    sk_set = TRUE
  ))
  expect_match(card, "K<sub>d</sub>\\(ref\\) was set by the user")
  expect_match(card, "S<sub>k</sub> was set by the user")
  expect_match(card, "nearest area \\(1.7 km away\\)")
  expect_match(card, "fewer than 10% valid pixels over time")

  card <- as.character(kd_model_card(
    fake_kd_model(vpf_area = TRUE, vpf_time = TRUE)
  ))
  expect_match(card, "valid pixels across the area and over time")
})

test_that("tu_hi_settings_items() shows what's missing and what isn't default", {
  defaults <- list(
    aq_env = "freshwater",
    date = as.Date("2026-06-21"),
    tzone = 0,
    depth_m = 0.01,
    tstart = 0,
    tstop = 23,
    tsteps = 24,
    wvl_start = 280,
    wvl_end = 500,
    time_multiplier = 2
  )
  items <- tu_hi_settings_items(defaults)
  expect_equal(items[["Location (latitude, longitude)"]], "Not set")
  expect_equal(items[["DOC (g/m<sup>3</sup>)"]], "Not set")
  expect_equal(items[["Date"]], "2026-06-21")
  expect_length(items, 6)
  expect_null(items[["TUV results multiplier"]])

  items <- tu_hi_settings_items(modifyList(
    defaults,
    list(
      aq_env = "marine",
      lat = 49,
      lon = -125,
      tzone = -8,
      Sk = 0.02,
      time_multiplier = 3
    )
  ))
  expect_equal(items[["Location (latitude, longitude)"]], "49, -125")
  expect_equal(items[["Light attenuation"]], "Marine ecoregion model")
  expect_null(items[["DOC (g/m<sup>3</sup>)"]])
  expect_equal(items[["Timezone (hrs)"]], "-8")
  expect_equal(items[["TUV results multiplier"]], "3")
  expect_equal(items[["S<sub>k</sub> (nm<sup>-1</sup>)"]], "0.02")
})

test_that("format_sum() keeps small values readable", {
  expect_equal(format_sum(0.00041234), "0.000412")
  expect_equal(format_sum(12.345), "12.3")
  expect_equal(format_sum(0), "0")
})
