chemical_list <- function() {
  ma_chems <- tolower(sort(unique(pahwq:::molar_absorption$chemical)))
  narc_bench_chems <- tolower(sort(unique(pahwq:::nlc50_lookup$chemical)))
  tools::toTitleCase(intersect(ma_chems, narc_bench_chems))
}

local_tuv_dir <- function(env = parent.frame()) {
  tdir <- file.path(withr::local_tempdir(.local_envir = env), "pahwq", "tuv_data")
  withr::local_options("pahwq.tuv_data_dir" = tdir, .local_envir = env)
  pahwq:::setup_tuv_dir()
}
