test_that("the attenuation sliders switch between DOC and Kd(ref)", {
  app <- local_app()
  show_tab(app, "DOC and Depth Sensitivity")

  selector <- app$get_html("#advanced-attenuation_selector")
  expect_match(selector, 'id="advanced-sens_doc"')
  expect_match(selector, 'id="advanced-doc_steps"')
  expect_no_match(selector, 'id="advanced-sens_kd"')

  app$set_inputs(`advanced-doc_or_kd` = "kd")

  selector <- app$get_html("#advanced-attenuation_selector")
  expect_match(selector, 'id="advanced-sens_kd"')
  expect_match(selector, 'id="advanced-kd_steps"')
  expect_no_match(selector, 'id="advanced-sens_doc"')
})

test_that("the sensitivity analysis produces a plot", {
  app <- local_app()
  app$set_inputs(`advanced-chemical` = "anthracene")
  set_site(app, "freshwater")
  show_tab(app, "DOC and Depth Sensitivity")
  expect_equal(app$get_value(input = "advanced-sens_depth"), c(0.01, 0.51))
  app$set_inputs(
    `advanced-sens_months` = "June",
    `advanced-depth_steps` = 2,
    `advanced-doc_steps` = 2
  )

  app$click("advanced-run_sens_button", timeout_ = 120000)

  plot <- app$get_value(output = "advanced-sens_plot")
  expect_type(plot, "character")
  expect_match(plot, "<svg")
})
