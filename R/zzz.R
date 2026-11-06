ignore_unused_dependencies <- function() {
  pkgload::load_all
  # Used by shiny::includeMarkdown(), which only suggests it
  markdown::mark
  # Used by markdown, need 1.0 for math rendering
  litedown::mark
}
