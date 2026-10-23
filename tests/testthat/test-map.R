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
