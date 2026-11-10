test_that("marine_kd_problem() explains when a marine run can't be done", {
  far <- sites$freshwater
  expect_null(marine_kd_problem(sites$marine$lat, sites$marine$lon))
  expect_null(marine_kd_problem(sites$nearshore$lat, sites$nearshore$lon))
  expect_null(marine_kd_problem(far$lat, far$lon, Kd_ref = 1, Sk = 0.02))
  expect_match(
    marine_kd_problem(sites$marine$lat, sites$marine$lon, Sk = 0.02),
    "Enter Kd\\(ref\\) to use your own Sk"
  )
  expect_match(
    marine_kd_problem(far$lat, far$lon, Kd_ref = 1),
    "more than 25 km .* Enter Kd\\(ref\\) and Sk to calculate"
  )
  expect_match(
    marine_kd_problem(far$lat, far$lon, tab = "Advanced"),
    "Enter Kd\\(ref\\) and Sk on the Advanced tab to calculate"
  )
})

test_that("marine_area_at() finds the containing or nearest marine area", {
  expect_equal(
    marine_area_at(sites$marine$lat, sites$marine$lon)$water_type,
    "turbid"
  )
  expect_null(marine_area_at(sites$nearshore$lat, sites$nearshore$lon))
  expect_equal(
    marine_area_at(
      sites$nearshore$lat,
      sites$nearshore$lon,
      nearest = TRUE
    )$area,
    "Strait_of_Georgia_Turbid"
  )
  expect_null(
    marine_area_at(sites$freshwater$lat, sites$freshwater$lon, nearest = TRUE)
  )
  expect_null(marine_area_at(NA, NA))
})

test_that("site_elevation() is 0 in marine water without a lookup", {
  local_mocked_bindings(get_elevation = function(...) stop("looked up"))
  expect_equal(site_elevation(49, -125, marine = TRUE), 0)
  expect_equal(site_elevation(NA, NA, marine = TRUE), 0)
})

test_that("site_elevation() looks up elevation in freshwater", {
  local_mocked_bindings(get_elevation = function(lon, lat) lon + lat)
  expect_equal(site_elevation(50, -100, marine = FALSE), -50)
})

test_that("site_elevation() is NA without a location or a lookup", {
  local_mocked_bindings(get_elevation = function(...) stop("no service"))
  expect_equal(site_elevation(NA, -100, marine = FALSE), NA_real_)
  expect_equal(site_elevation(NULL, -100, marine = FALSE), NA_real_)
  expect_equal(site_elevation(50, -100, marine = FALSE), NA_real_)
})

test_that("tuv_results_export() adds the marine Kd model as columns", {
  res <- data.frame(wl = c(280, 281), t_12 = c(0.1, 0.2))
  expect_equal(tuv_results_export(res), res)

  attr(res, "kd_model") <- fake_kd_model()
  exported <- tuv_results_export(res)
  expect_named(
    exported,
    c(
      "wl",
      "t_12",
      paste0("marine_kd_model_", setdiff(names(fake_kd_model()), "area"))
    )
  )
  expect_equal(exported$marine_kd_model_ecoregion, rep("Strait of Georgia", 2))
  expect_equal(exported$marine_kd_model_Kd_ref, rep(1.15809, 2))
})

test_that("chemical_list() has one entry per PAC shown in the app", {
  chems <- chemical_list()
  expect_length(chems, 47)
  expect_setequal(names(chems), pac_list(app_only = TRUE)$pac_name)
  expect_equal(
    chems[["C1-Benz(a)anthracenes/Chrysenes"]],
    "c1-benzo(a)anthracenes"
  )
  expect_equal(chems[["Benzo(a)pyrene"]], "benzo(a)pyrene")
})

test_that("tu_hi_export() has each PAC, a total and the settings", {
  pacs <- data.frame(
    pac_name = c("a", "b"),
    concentration_ug_L = c(1, 0),
    narcotic_benchmark = 1,
    tu_narcotic = c(1, 0)
  )
  results <- structure(
    data.frame(tu_narcotic = 1),
    pacs = pacs,
    class = c("tu_hi", "data.frame")
  )
  settings <- list(lat = 50, DOC = NULL, date = as.Date("2024-06-21"))

  out <- tu_hi_export(results, settings)
  expect_equal(out$pac, c("a", "b", "Total"))
  expect_equal(out$tu_narcotic, c(1, 0, 1))
  expect_equal(out$narcotic_benchmark, c(1, 1, NA))
  expect_equal(out$lat, rep(50, 3))
  expect_equal(out$DOC, rep(NA, 3))
  expect_equal(out$date, rep("2024-06-21", 3))

  out <- tu_hi_export(results, settings, list(area = "x", ecoregion = "y"))
  expect_equal(out$marine_kd_model_ecoregion, rep("y", 3))
  expect_null(out$marine_kd_model_area)
})

test_that("settings_used() fills in values from the TUV run", {
  params <- c(
    "a,b,c for: kvdom = a exp(-b(wvl-c)). a = kd(c), b = Sk, c = reference wavelength" = "10.67 0.018 305",
    "o3_tc  ozone column, Dobson Units (DU)" = "359.937",
    "tauaer - aerosol optical depth at 550 nm" = "0.137"
  )
  used <- settings_used(list(lat = 50, DOC = 5, o3_tc = NULL), params)
  expect_equal(used$lat, 50)
  expect_equal(used$DOC, 5)
  expect_equal(used$Kd_ref, 10.67)
  expect_equal(used$Sk, 0.018)
  expect_equal(used$Kd_wvl, 305)
  expect_equal(used$o3_tc, 359.937)
  expect_equal(used$tauaer, 0.137)
})

test_that("read_concentrations() fills in values by PAC name", {
  path <- withr::local_tempfile(fileext = ".csv")
  writeLines(
    c(
      "﻿pac,concentration_ug_L,other",
      " Benzo[a]pyrene ,0.5,x",
      "c1-anthracenes,2,x",
      "Pyrene,,x"
    ),
    path,
    useBytes = TRUE
  )

  res <- read_concentrations(path)
  pacs <- names(chemical_list())
  expect_equal(res$errors, character())
  expect_equal(res$notices, NULL)
  expect_equal(res$values[match("Benzo(a)pyrene", pacs)], 0.5)
  expect_equal(res$values[match("C1-Phenanthrenes/Anthracenes", pacs)], 2)
  expect_equal(sum(!is.na(res$values)), 2)
})

test_that("read_concentrations() reads a results download back in", {
  pacs <- names(chemical_list())
  path <- withr::local_tempfile(fileext = ".csv")
  utils::write.csv(
    data.frame(
      pac = c(pacs, "Total"),
      concentration_ug_L = c(1, rep(NA, length(pacs))),
      tu_narcotic = 1
    ),
    path,
    row.names = FALSE,
    na = ""
  )

  res <- read_concentrations(path)
  expect_equal(res$values, c(1, rep(NA, length(pacs) - 1)))
  expect_null(res$notices)
})

test_that("read_concentrations() rejects files it can't use", {
  read_lines <- function(...) {
    path <- withr::local_tempfile(fileext = ".csv")
    writeLines(c(...), path)
    read_concentrations(path)
  }

  expect_snapshot({
    read_lines("pac,value", "Pyrene,1")$errors
    read_lines("pac,concentration_ug_L", "Pyrene,<0.01", "Anthracene,1")$errors
    read_lines("pac,concentration_ug_L", "Pyrene,-1")$errors
    read_lines(
      "pac,concentration_ug_L",
      "c1-anthracenes,1",
      "C1-Phenanthrenes/Anthracenes,2"
    )$errors
    read_lines("pac,concentration_ug_L", "Pyrene,")$errors
  })
  expect_null(read_lines("pac,concentration_ug_L", "Pyrene,-1")$values)
})

test_that("read_concentrations() reads every row, whatever else is in the file", {
  lines <- paste0(
    "pac,concentration_ug_L,note\r\n",
    "Anthracene,0.1,\r\n",
    "Pyrene,0.2,%s\r\n",
    "Benzo(a)pyrene,0.3,\r\n"
  )
  plain <- charToRaw(sprintf(lines, "x"))
  files <- list(
    windows_1252 = charToRaw(sprintf(lines, "5 \xb5g/L")),
    undefined_byte = charToRaw(sprintf(lines, "\x81")),
    utf8 = charToRaw(sprintf(lines, "5 \xc2\xb5g/L")),
    utf8_bom = c(as.raw(c(0xef, 0xbb, 0xbf)), plain),
    mac_line_endings = charToRaw(gsub("\r\n", "\r", sprintf(lines, "x"))),
    null_byte_in_pac = c(plain[1:37], as.raw(0), plain[-(1:37)])
  )
  pacs <- names(chemical_list())

  for (bytes in files) {
    path <- withr::local_tempfile(fileext = ".csv")
    writeBin(bytes, path)
    res <- read_concentrations(path)
    expect_equal(res$errors, character())
    expect_equal(res$values[match("Anthracene", pacs)], 0.1)
    expect_equal(res$values[match("Pyrene", pacs)], 0.2)
    expect_equal(res$values[match("Benzo(a)pyrene", pacs)], 0.3)
  }
})

test_that("read_concentrations() reads a short file with no final line ending", {
  path <- withr::local_tempfile(fileext = ".csv")
  writeBin(charToRaw("pac,concentration_ug_L\nPyrene,1"), path)
  res <- read_concentrations(path)
  expect_equal(res$errors, character())
  expect_equal(sum(!is.na(res$values)), 1)
})

test_that("read_concentrations() rejects files that can't be read in full", {
  read_bytes <- function(bytes) {
    path <- withr::local_tempfile(fileext = ".csv")
    writeBin(bytes, path)
    read_concentrations(path)
  }
  message <- "The file could not be read as a CSV file."

  expect_equal(
    read_bytes(charToRaw("pac,concentration_ug_L\nPyr\xb5ne,1\n"))$errors,
    message
  )
  expect_equal(
    read_bytes(charToRaw("pac,concentration_ug_L\nPyrene,1\xb5\n"))$errors,
    message
  )

  unclosed_quote <- charToRaw(paste0(
    "pac,concentration_ug_L,note\n",
    "Anthracene,0.1,\n",
    "Pyrene,0.2,\"unclosed\n",
    "Benzo(a)pyrene,0.3,\n"
  ))
  res <- read_bytes(unclosed_quote)
  expect_equal(res$errors, message)
  expect_null(res$values)
})

test_that("read_concentrations() gives notices for concentrations not counted", {
  hidden <- setdiff(pac_list()$pac_name, pac_list(app_only = TRUE)$pac_name)[1]
  path <- withr::local_tempfile(fileext = ".csv")
  writeLines(
    c(
      "pac,concentration_ug_L",
      "Pyrene,1",
      "not a PAC,2",
      "also not a PAC,",
      paste0('"', hidden, '",3')
    ),
    path
  )

  res <- read_concentrations(path)
  expect_equal(sum(!is.na(res$values)), 1)
  expect_length(res$notices, 2)
  expect_match(res$notices[1], "not a PAC", fixed = TRUE)
  expect_no_match(res$notices[1], "also not a PAC", fixed = TRUE)
  expect_match(res$notices[2], hidden, fixed = TRUE)
})

test_that("read_concentrations() gives the row of a concentration with no name", {
  path <- withr::local_tempfile(fileext = ".csv")
  writeLines(
    c(
      "pac,concentration_ug_L",
      "Pyrene,1",
      ",2",
      "not a PAC,3",
      "",
      "NA,4",
      ",",
      "Anthracene,"
    ),
    path
  )

  res <- read_concentrations(path)
  expect_equal(sum(!is.na(res$values)), 1)
  expect_equal(
    res$notices,
    paste0(
      "These names weren't recognized, so their concentrations aren't counted: ",
      "row 3 (no name), not a PAC, row 6 (no name)."
    )
  )
})
