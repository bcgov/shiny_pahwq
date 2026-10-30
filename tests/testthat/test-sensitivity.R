test_that("the attenuation sliders switch between DOC and Kd(ref)", {
  app <- local_app()
  show_tab(app, "DOC and Depth Sensitivity")

  selector <- app$get_html("#attenuation_selector")
  expect_match(selector, 'id="sens_doc"')
  expect_match(selector, 'id="doc_steps"')
  expect_no_match(selector, 'id="sens_kd"')

  app$set_inputs(doc_or_kd = "kd")

  selector <- app$get_html("#attenuation_selector")
  expect_match(selector, 'id="sens_kd"')
  expect_match(selector, 'id="kd_steps"')
  expect_no_match(selector, 'id="sens_doc"')
})

test_that("the sensitivity analysis produces a plot", {
  app <- local_app()
  app$set_inputs(chemical = "anthracene")
  set_site(app, "freshwater")
  show_tab(app, "DOC and Depth Sensitivity")
  expect_equal(app$get_value(input = "sens_depth"), c(0.01, 0.51))
  app$set_inputs(sens_months = "June", depth_steps = 2, doc_steps = 2)

  app$click("run_sens_button", timeout_ = 120000)

  plot <- app$get_value(output = "sens_plot")
  expect_type(plot, "character")
  expect_match(plot, "<svg")
})
