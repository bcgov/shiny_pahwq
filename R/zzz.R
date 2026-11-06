ignore_unused_dependencies <- function() {
  pkgload::load_all
  # Used by shiny::includeMarkdown(), which only suggests it
  markdown::mark
}
