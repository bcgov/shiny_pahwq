chemical_list <- function() {
  ma_chems <- tolower(sort(unique(pahwq:::molar_absorption$chemical)))
  nlc50_chems <- tolower(sort(unique(pahwq:::nlc50_lookup$chemical)))
  tools::toTitleCase(intersect(ma_chems, nlc50_chems))
}
