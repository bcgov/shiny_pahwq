test_that("clicking the map sets the location and aquatic environment", {
  app <- local_app(tab = "Advanced")
  show_tab(app, "Map")

  app$set_inputs(
    `advanced-map-leaflet_click` = list(
      lat = sites$marine$lat,
      lng = sites$marine$lon
    ),
    allow_no_input_binding_ = TRUE,
    wait_ = FALSE
  )
  app$wait_for_idle()
  expect_equal(app$get_value(input = "advanced-lat"), sites$marine$lat)
  expect_equal(app$get_value(input = "advanced-lon"), sites$marine$lon)
  expect_equal(app$get_value(input = "advanced-aq_env"), "marine")
  expect_equal(app$get_value(input = "advanced-elev_m"), 0)

  app$set_inputs(
    `advanced-map-leaflet_click` = list(
      lat = sites$freshwater$lat,
      lng = sites$freshwater$lon
    ),
    allow_no_input_binding_ = TRUE,
    wait_ = FALSE
  )
  app$wait_for_idle()
  expect_equal(app$get_value(input = "advanced-aq_env"), "freshwater")

  # Clicks on the marine area polygons are reported separately
  app$set_inputs(
    `advanced-map-leaflet_shape_click` = list(
      lat = sites$marine$lat,
      lng = sites$marine$lon,
      group = "Marine areas"
    ),
    allow_no_input_binding_ = TRUE,
    wait_ = FALSE
  )
  app$wait_for_idle()
  expect_equal(app$get_value(input = "advanced-lat"), sites$marine$lat)
  expect_equal(app$get_value(input = "advanced-aq_env"), "marine")
})

test_that("the marine areas are shown on the map in marine water", {
  app <- local_app(tab = "Advanced")
  show_tab(app, "Map")
  shown_marine_areas <- function() {
    app$get_js(
      "(function() {
        var map = HTMLWidgets.find('#advanced-map-leaflet').getMap();
        var group = map.layerManager.getLayerGroup('Marine areas', false);
        return group && map.hasLayer(group) ? group.getLayers().length : 0;
      })()"
    )
  }
  legend_shown <- function() {
    app$get_js(
      "document.querySelector('#advanced-map-leaflet .legend') !== null"
    )
  }
  expect_equal(shown_marine_areas(), 0)
  expect_equal(legend_shown(), FALSE)

  app$set_inputs(`advanced-aq_env` = "marine", wait_ = FALSE)
  app$wait_for_idle()
  expect_equal(shown_marine_areas(), nrow(marine_areas()))
  expect_equal(legend_shown(), TRUE)

  app$set_inputs(`advanced-aq_env` = "freshwater", wait_ = FALSE)
  app$wait_for_idle()
  expect_equal(shown_marine_areas(), 0)
  expect_equal(legend_shown(), FALSE)
})

test_that("the map starts on Canada and zooms in for the first location", {
  app <- local_app(width = 1400, height = 1000)
  map <- "HTMLWidgets.find('#simple-map-leaflet').getMap()"
  wait_for_zoom <- function(zoom) {
    app$wait_for_js(sprintf("%s.getZoom() === %d", map, zoom))
  }
  wait_for_zoom(3)

  app$set_inputs(
    `simple-lat` = sites$freshwater$lat,
    `simple-lon` = sites$freshwater$lon
  )
  wait_for_zoom(5)

  app$run_js(sprintf("%s.setZoom(7);", map))
  wait_for_zoom(7)
  app$wait_for_idle()

  app$set_inputs(`simple-lat` = sites$marine$lat)
  app$wait_for_js(sprintf(
    "Math.abs(%s.getCenter().lat - %f) < 0.01",
    map,
    sites$marine$lat
  ))
  expect_equal(app$get_js(sprintf("%s.getZoom()", map)), 7)
})
