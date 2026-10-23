test_that("clicking the map sets the location and aquatic environment", {
  app <- local_app()
  show_tab(app, "Map")

  app$set_inputs(
    map_click = list(lat = sites$marine$lat, lng = sites$marine$lon),
    allow_no_input_binding_ = TRUE,
    wait_ = FALSE
  )
  app$wait_for_idle()
  expect_equal(app$get_value(input = "lat"), sites$marine$lat)
  expect_equal(app$get_value(input = "lon"), sites$marine$lon)
  expect_equal(app$get_value(input = "aq_env"), "marine")
  expect_equal(app$get_value(input = "elev_m"), 0)

  app$set_inputs(
    map_click = list(lat = sites$freshwater$lat, lng = sites$freshwater$lon),
    allow_no_input_binding_ = TRUE,
    wait_ = FALSE
  )
  app$wait_for_idle()
  expect_equal(app$get_value(input = "aq_env"), "freshwater")
})

test_that("moving from a marine location to land calculates for freshwater", {
  app <- local_app()
  app$set_inputs(chemical = "Anthracene", doc = 5)
  set_site(app, "marine")
  expect_equal(app$get_value(input = "aq_env"), "marine")

  # Record any error shown in between, not just the final state
  app$run_js(
    "window.pabsErrored = false;
    new MutationObserver(function() {
      if (document.getElementById('pabs').classList.contains('shiny-output-error')) {
        window.pabsErrored = true;
      }
    }).observe(document.getElementById('pabs'), {attributes: true});"
  )
  set_site(app, "freshwater")
  expect_equal(app$get_value(input = "aq_env"), "freshwater")
  expect_equal(app$get_js("window.pabsErrored"), FALSE)

  expected <- expected_results("Anthracene", "freshwater", DOC = 5)
  expect_equal(output_number(app, "pabs"), expected$pabs)
})

test_that("marine can be selected manually for a nearshore location", {
  app <- local_app()
  app$set_inputs(chemical = "Anthracene", depth_m = 0.01, date = "2024-06-21")
  app$set_inputs(
    lat = sites$nearshore$lat,
    lon = sites$nearshore$lon,
    wait_ = FALSE
  )
  app$wait_for_idle()
  expect_equal(app$get_value(input = "aq_env"), "freshwater")

  app$set_inputs(aq_env = "marine", wait_ = FALSE)
  app$wait_for_idle()
  expect_equal(app$get_value(input = "aq_env"), "marine")
  expect_equal(app$get_value(input = "elev_m"), 0)
  expect_match(
    app$get_text(".shiny-notification"),
    "using the nearest area",
    all = FALSE
  )
  expect_null(output_error(app, "pabs"))
  expect_length(output_number(app, "pabs"), 1)

  app$set_inputs(depth_m = 0.02, wait_ = FALSE)
  app$wait_for_idle()
  expect_equal(app$get_value(input = "aq_env"), "marine")
})

test_that("elevation is looked up, or 0 in marine water", {
  skip_if_offline()
  app <- local_app()
  app$set_inputs(
    lat = sites$freshwater$lat,
    lon = sites$freshwater$lon,
    wait_ = FALSE
  )
  app$wait_for_idle()
  expect_equal(
    app$get_value(input = "elev_m"),
    sites$freshwater$elev_m,
    tolerance = 0.05
  )

  app$set_inputs(aq_env = "marine")
  expect_equal(app$get_value(input = "elev_m"), 0)

  app$set_inputs(aq_env = "freshwater", wait_ = FALSE)
  app$wait_for_idle()
  expect_equal(
    app$get_value(input = "elev_m"),
    sites$freshwater$elev_m,
    tolerance = 0.05
  )
})

test_that("the marine areas are shown on the map in marine water", {
  app <- local_app()
  show_tab(app, "Map")
  shown_marine_areas <- function() {
    app$get_js(
      "(function() {
        var map = HTMLWidgets.find('#map').getMap();
        var group = map.layerManager.getLayerGroup('Marine areas', false);
        return group && map.hasLayer(group) ? group.getLayers().length : 0;
      })()"
    )
  }
  legend_shown <- function() {
    app$get_js("document.querySelector('#map .legend') !== null")
  }
  expect_equal(shown_marine_areas(), 0)
  expect_equal(legend_shown(), FALSE)

  app$set_inputs(aq_env = "marine", wait_ = FALSE)
  app$wait_for_idle()
  expect_equal(shown_marine_areas(), nrow(marine_areas()))
  expect_equal(legend_shown(), TRUE)

  app$set_inputs(aq_env = "freshwater", wait_ = FALSE)
  app$wait_for_idle()
  expect_equal(shown_marine_areas(), 0)
  expect_equal(legend_shown(), FALSE)
})

test_that("clicking a marine area polygon sets the location", {
  app <- local_app()
  show_tab(app, "Map")

  app$set_inputs(
    map_shape_click = list(
      lat = sites$marine$lat,
      lng = sites$marine$lon,
      group = "Marine areas"
    ),
    allow_no_input_binding_ = TRUE,
    wait_ = FALSE
  )
  app$wait_for_idle()

  expect_equal(app$get_value(input = "lat"), sites$marine$lat)
  expect_equal(app$get_value(input = "lon"), sites$marine$lon)
})
