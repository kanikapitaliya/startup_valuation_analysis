# =============================================================================
# run_all.R
# Runs the entire pipeline end-to-end, in order. Run this from the project
# root directory, e.g.:
#     Rscript run_all.R
# =============================================================================

steps <- c(
  "R/00_simulate_dataset.R",
  "R/01_preprocessing.R",
  "R/02_eda.R",
  "R/03_simple_linear_regression.R",
  "R/04_multiple_linear_regression.R",
  "R/05_model_comparison.R"
)

for (step in steps) {
  cat("\n", strrep("=", 70), "\n", sep = "")
  cat("Running:", step, "\n")
  cat(strrep("=", 70), "\n")
  source(step, echo = FALSE)
}

cat("\nAll steps completed.\n")
cat("Figures  -> outputs/figures/\n")
cat("Tables   -> outputs/tables/\n")
cat("Data     -> data/processed/\n")
