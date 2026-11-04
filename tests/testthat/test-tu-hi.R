expected_tu_hi <- function(values, ...) {
  pahwq::tu_hi(
    data.frame(pac = names(values), concentration_ug_L = unname(values)),
    expected_results("Anthracene", ...)$irrad
  )
}

conc_id <- function(pac) {
  paste0("tu_hi-conc_", match(pac, names(chemical_list())))
}

calculate <- function(app) {
  app$click("tu_hi-calculate")
  app$wait_for_idle()
}

test_that("TUs and HIs are calculated from entered concentrations", {
  app <- local_app(tab = "Advanced")
  set_site(app, "freshwater")
  app$set_inputs(`advanced-doc` = 5)
  show_tab(app, tu_hi_tab)

  app$set_inputs(
    !!conc_id("Acenaphthene") := 0,
    !!conc_id("Anthracene") := 0.1,
    !!conc_id("Pyrene") := 2
  )
  calculate(app)

  downloaded <- utils::read.csv(app$get_download("tu_hi-results_download"))
  expected <- expected_tu_hi(
    c(Anthracene = 0.1, Pyrene = 2),
    "freshwater",
    DOC = 5
  )
  total <- downloaded[downloaded$pac == "Total", ]
  expect_equal(
    downloaded$pac,
    c("Acenaphthene", "Anthracene", "Pyrene", "Total")
  )
  expect_equal(total$tu_narcotic, expected$tu_narcotic)
  expect_equal(total$tu_phototoxic, expected$tu_phototoxic)
  expect_equal(total$hi_narcotic, expected$hi_narcotic)
  expect_equal(total$hi_phototoxic, expected$hi_phototoxic)
  expect_equal(unique(downloaded$lat), sites$freshwater$lat)
  expect_equal(unique(downloaded$DOC), 5)
  params <- pahwq::tuv_run_params(
    expected_results("Anthracene", "freshwater", DOC = 5)$irrad
  )
  expect_equal(
    unique(downloaded$o3_tc),
    as.numeric(params[[grep("^o3_tc", names(params))]])
  )
  expect_equal(
    unique(downloaded$tauaer),
    as.numeric(params[[grep("^tauaer", names(params))]])
  )
  expect_equal(unique(downloaded$Sk), 0.018)
  expect_match(app$get_text("#tu_hi-results"), "Narcotic TUs")
})

test_that("a sample of only zeros gives results of 0", {
  app <- local_app(tab = "Advanced")
  set_site(app, "freshwater")
  app$set_inputs(`advanced-doc` = 5)
  show_tab(app, tu_hi_tab)
  app$set_inputs(!!conc_id("Anthracene") := 0)
  calculate(app)

  downloaded <- utils::read.csv(app$get_download("tu_hi-results_download"))
  expect_equal(downloaded$pac, c("Anthracene", "Total"))
  expect_equal(downloaded$tu_narcotic, c(0, 0))
  expect_equal(downloaded$hi_phototoxic, c(0, 0))
})

test_that("settings from Simple are used without visiting Advanced", {
  app <- local_app()
  app$set_inputs(
    `simple-lat` = sites$freshwater$lat,
    `simple-lon` = sites$freshwater$lon,
    `simple-doc` = 5,
    wait_ = FALSE
  )
  app$wait_for_idle()

  show_tab(app, tu_hi_tab)
  expect_match(
    app$get_text("#tu_hi-settings"),
    paste0(sites$freshwater$lat, ", ", sites$freshwater$lon),
    fixed = TRUE
  )

  app$set_inputs(!!conc_id("Anthracene") := 0.1)
  calculate(app)
  downloaded <- utils::read.csv(app$get_download("tu_hi-results_download"))
  expected <- expected_tu_hi(
    c(Anthracene = 0.1),
    "freshwater",
    DOC = 5,
    date = simple_date()
  )
  expect_equal(
    downloaded$tu_phototoxic[downloaded$pac == "Total"],
    expected$tu_phototoxic
  )
})

test_that("results hold until Calculate is pressed again after settings change", {
  app <- local_app(tab = "Advanced")
  set_site(app, "freshwater")
  app$set_inputs(`advanced-doc` = 5)
  show_tab(app, tu_hi_tab)
  app$set_inputs(!!conc_id("Anthracene") := 0.1)
  calculate(app)
  before <- utils::read.csv(app$get_download("tu_hi-results_download"))
  expect_no_match(app$get_text("#tu_hi-stale_notice"), "settings have changed")

  app$click("tu_hi-edit_settings")
  expect_equal(app$get_value(input = "nav"), "Advanced")
  app$set_inputs(`advanced-date` = "2024-03-21")
  app$click("advanced-back_to_tu_hi")
  expect_equal(app$get_value(input = "nav"), tu_hi_tab)
  app$wait_for_idle()

  expect_match(app$get_text("#tu_hi-settings"), "2024-03-21")
  expect_match(app$get_text("#tu_hi-stale_notice"), "settings have changed")
  held <- utils::read.csv(app$get_download("tu_hi-results_download"))
  expect_equal(held, before)

  calculate(app)
  expect_no_match(app$get_text("#tu_hi-stale_notice"), "settings have changed")
  after <- utils::read.csv(app$get_download("tu_hi-results_download"))
  expect_equal(unique(after$date), "2024-03-21")
})

test_that("Calculate shows messages for missing inputs", {
  app <- local_app(tab = tu_hi_tab)
  expect_match(app$get_text("#tu_hi-settings"), "Not set")

  calculate(app)
  expect_equal(
    output_error(app, "tu_hi-results"),
    "Enter at least one concentration."
  )

  app$set_inputs(!!conc_id("Anthracene") := 0.1)
  calculate(app)
  expect_equal(
    output_error(app, "tu_hi-results"),
    "Set a location on the Simple or Advanced tab to calculate results."
  )

  app$set_inputs(!!conc_id("Anthracene") := -1)
  calculate(app)
  expect_equal(
    output_error(app, "tu_hi-results"),
    "Concentrations can't be negative."
  )
})

test_that("an uploaded file fills in the table, and Clear empties it", {
  path <- withr::local_tempfile(fileext = ".csv")
  writeLines(c("pac,concentration_ug_L", "Benzo[a]pyrene,0.5"), path)

  app <- local_app(tab = tu_hi_tab)
  app$set_inputs(!!conc_id("Anthracene") := 0.1)
  app$upload_file(`tu_hi-upload` = path)
  app$wait_for_idle()

  expect_equal(app$get_value(input = conc_id("Benzo(a)pyrene")), 0.5)
  expect_equal(app$get_value(input = conc_id("Anthracene")), NA)
  expect_match(app$get_text("#tu_hi-upload_status"), "Concentrations loaded")

  app$click("tu_hi-clear")
  app$wait_for_idle()
  expect_equal(app$get_value(input = conc_id("Benzo(a)pyrene")), NA)
  expect_equal(app$get_text("#tu_hi-upload_status"), "")
})
