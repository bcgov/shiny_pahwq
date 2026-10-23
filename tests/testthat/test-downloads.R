download_filename <- function(app, id) {
  href <- app$get_js(sprintf(
    "document.getElementById('%s').getAttribute('href')",
    id
  ))
  resp <- httr2::request(paste0(app$get_url(), href)) |>
    httr2::req_perform()
  sub(
    '.*filename="?([^";]+)"?.*',
    "\\1",
    httr2::resp_header(resp, "content-disposition")
  )
}

test_that("TUV results can be downloaded", {
  app <- local_app()
  set_site(app, "freshwater")
  app$set_inputs(doc = 5)
  show_tab(app, "TUV Results")

  expect_equal(
    download_filename(app, "tuv_download"),
    paste0("tuv-results_", Sys.Date(), ".csv")
  )

  expected <- expected_results("Anthracene", "freshwater", DOC = 5)$irrad
  downloaded <- utils::read.csv(app$get_download("tuv_download"))
  expect_named(downloaded, names(expected))
  expect_equal(downloaded, as.data.frame(expected), ignore_attr = TRUE)
})

test_that("multi-chemical results cover every chemical and can be downloaded", {
  app <- local_app()
  set_site(app, "freshwater")
  app$set_inputs(doc = 5)
  show_tab(app, "Multi-Chemical Toxicity")

  expect_equal(
    download_filename(app, "multi_tox_download"),
    paste0("phototoxic-wq-multi-results-freshwater_", Sys.Date(), ".csv")
  )

  downloaded <- utils::read.csv(app$get_download("multi_tox_download"))
  expect_equal(nrow(downloaded), length(chemical_list()))
  expect_contains(
    names(downloaded),
    c(
      "pabs",
      "narcotic_benchmark",
      "narcotic_cwqg",
      "phototoxic_benchmark",
      "phototoxic_cwqg"
    )
  )
})

test_that("representative guideline tables are downloaded unchanged", {
  app <- local_app()
  show_tab(app, "Representative Guidelines")

  fw <- system.file(
    "doc-guideline-lookup/PAH-DOC_freshwater-guidelines.csv",
    package = "pahwq"
  )
  expect_equal(
    download_filename(app, "multi_doc_pah_fw_dl"),
    basename(fw)
  )
  expect_equal(
    unname(tools::md5sum(app$get_download("multi_doc_pah_fw_dl"))),
    unname(tools::md5sum(fw))
  )

  show_tab(app, "Marine")
  marine <- system.file(
    "doc-guideline-lookup/PAH_marine-guidelines.csv",
    package = "pahwq"
  )
  expect_equal(
    download_filename(app, "multi_pah_marine_dl"),
    basename(marine)
  )
  expect_equal(
    unname(tools::md5sum(app$get_download("multi_pah_marine_dl"))),
    unname(tools::md5sum(marine))
  )
})
