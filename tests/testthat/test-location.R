test_that("moving from a marine location to land calculates for freshwater", {
  app <- local_app(tab = "Advanced")
  app$set_inputs(`advanced-chemical` = "anthracene", `advanced-doc` = 5)
  set_site(app, "marine")
  expect_equal(app$get_value(input = "advanced-aq_env"), "marine")

  # Record any error shown in between, not just the final state
  app$run_js(
    "window.pabsErrored = false;
    new MutationObserver(function() {
      if (document.getElementById('advanced-pabs').classList.contains('shiny-output-error')) {
        window.pabsErrored = true;
      }
    }).observe(document.getElementById('advanced-pabs'), {attributes: true});"
  )
  set_site(app, "freshwater")
  expect_equal(app$get_value(input = "advanced-aq_env"), "freshwater")
  expect_equal(app$get_js("window.pabsErrored"), FALSE)

  expected <- expected_results("Anthracene", "freshwater", DOC = 5)
  expect_equal(output_number(app, "advanced-pabs"), expected$pabs)
})

test_that("marine can be selected manually for a nearshore location", {
  app <- local_app(tab = "Advanced")
  app$set_inputs(
    `advanced-chemical` = "anthracene",
    `advanced-date` = "2024-06-21"
  )
  app$set_inputs(
    `advanced-lat` = sites$nearshore$lat,
    `advanced-lon` = sites$nearshore$lon,
    wait_ = FALSE
  )
  app$wait_for_idle()
  expect_equal(app$get_value(input = "advanced-aq_env"), "freshwater")

  app$set_inputs(`advanced-aq_env` = "marine", wait_ = FALSE)
  app$wait_for_idle()
  expect_equal(app$get_value(input = "advanced-aq_env"), "marine")
  expect_equal(app$get_value(input = "advanced-elev_m"), 0)
  expect_match(
    app$get_text(".shiny-notification"),
    "using the nearest area",
    all = FALSE
  )
  expect_null(output_error(app, "advanced-pabs"))
  expect_length(output_number(app, "advanced-pabs"), 1)

  app$set_inputs(`advanced-depth_m` = 0.02, wait_ = FALSE)
  app$wait_for_idle()
  expect_equal(app$get_value(input = "advanced-aq_env"), "marine")
})

test_that("a location and environment from the other tab share one lookup", {
  lookups <- 0
  withr::local_options(pacwq.shiny.elevation = function(lon, lat) {
    lookups <<- lookups + 1
    sites$freshwater$elev_m
  })
  shared <- reactiveValues(
    lat = sites$freshwater$lat,
    lon = sites$freshwater$lon
  )

  testServer(
    advanced_server,
    args = list(shared = shared, active = reactive(FALSE)),
    {
      session$setInputs(aq_env = "marine")
      session$setInputs(
        lat = sites$freshwater$lat,
        lon = sites$freshwater$lon,
        aq_env = "freshwater"
      )
    }
  )

  expect_equal(lookups, 1)
})

test_that("a failed elevation lookup is reported on the Simple tab", {
  app <- local_app(elevation = function(lon, lat) stop("no service"))
  app$set_inputs(
    `simple-lat` = sites$freshwater$lat,
    `simple-lon` = sites$freshwater$lon,
    `simple-doc` = 5,
    `simple-chemical` = "anthracene",
    wait_ = FALSE
  )
  app$wait_for_idle()

  expect_match(output_error(app, "simple-pabs"), "No elevation found")
})

test_that("a failed elevation lookup is reported on the Advanced tab", {
  app <- local_app(
    tab = "Advanced",
    elevation = function(lon, lat) stop("no service")
  )
  app$set_inputs(
    `advanced-lat` = sites$freshwater$lat,
    `advanced-lon` = sites$freshwater$lon,
    `advanced-doc` = 5,
    `advanced-chemical` = "anthracene",
    wait_ = FALSE
  )
  app$wait_for_idle()

  expect_match(output_error(app, "advanced-pabs"), "No elevation found")

  show_tab(app, "DOC and Depth Sensitivity")
  app$set_inputs(`advanced-sens_months` = "June")
  app$click("advanced-run_sens_button")
  expect_match(output_error(app, "advanced-sens_plot"), "No elevation found")

  app$set_inputs(`advanced-elev_m` = sites$freshwater$elev_m, wait_ = FALSE)
  app$wait_for_idle()
  expect_null(output_error(app, "advanced-pabs"))
  expect_length(output_number(app, "advanced-pabs"), 1)
})

test_that("a first location doesn't flash the missing elevation message", {
  for (site in c("freshwater", "marine")) {
    app <- local_app(tab = "Advanced")
    app$set_inputs(`advanced-chemical` = "anthracene", `advanced-doc` = 5)
    app$run_js(
      "window.pabsErrors = [];
      new MutationObserver(function() {
        var el = document.getElementById('advanced-pabs');
        if (el.classList.contains('shiny-output-error-validation') && el.textContent) {
          window.pabsErrors.push(el.textContent);
        }
      }).observe(document.getElementById('advanced-pabs'), {
        attributes: true, childList: true, characterData: true, subtree: true
      });"
    )
    app$set_inputs(
      `advanced-lat` = sites[[site]]$lat,
      `advanced-lon` = sites[[site]]$lon,
      wait_ = FALSE
    )
    app$wait_for_idle()

    expect_length(app$get_js("window.pabsErrors"), 0)
    expect_length(output_number(app, "advanced-pabs"), 1)
  }
})

test_that("elevation is looked up, or 0 in marine water", {
  app <- local_app(tab = "Advanced")
  app$set_inputs(
    `advanced-lat` = sites$freshwater$lat,
    `advanced-lon` = sites$freshwater$lon,
    wait_ = FALSE
  )
  app$wait_for_idle()
  expect_equal(
    app$get_value(input = "advanced-elev_m"),
    sites$freshwater$elev_m
  )

  app$set_inputs(`advanced-aq_env` = "marine")
  expect_equal(app$get_value(input = "advanced-elev_m"), 0)

  app$set_inputs(`advanced-aq_env` = "freshwater", wait_ = FALSE)
  app$wait_for_idle()
  expect_equal(
    app$get_value(input = "advanced-elev_m"),
    sites$freshwater$elev_m
  )
})
