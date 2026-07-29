# =============================================================================
# utils.R
# Shared ggplot2 theme and helper constants used across the project scripts.
# =============================================================================

suppressPackageStartupMessages(library(ggplot2))

theme_startup <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title       = element_text(face = "bold", size = base_size + 2, hjust = 0),
      plot.subtitle    = element_text(color = "grey30"),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "grey90"),
      axis.title       = element_text(face = "plain"),
      legend.position  = "right"
    )
}

# Palette matching the original report's teal / navy / coral scheme
pal_teal  <- "#1f9e89"
pal_navy  <- "#2c3e50"
pal_coral <- "#e07856"
pal_slate <- "#5b7c99"

industry_order <- c("AI/ML", "FinTech", "BioTech", "SaaS",
                     "HealthTech", "CleanTech", "E-Commerce", "EdTech")

ensure_dir <- function(path) {
  dir.create(path, showWarnings = FALSE, recursive = TRUE)
}
