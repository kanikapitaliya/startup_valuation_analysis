# =============================================================================
# install_packages.R
# Installs all R package dependencies needed to run this project.
# Run once: Rscript install_packages.R
# =============================================================================

required_pkgs <- c(
  "tidyverse",   # dplyr, ggplot2, readr, etc.
  "caret",       # train/test partitioning
  "e1071",       # skewness()
  "car",         # vif()
  "Metrics",     # rmse(), mae()
  "corrplot",    # (optional) correlation plotting
  "gridExtra",   # combining ggplot panels
  "scales",      # (optional) plot scale helpers
  "reshape2"     # melt() for the correlation heatmap
)

installed <- rownames(installed.packages())
to_install <- setdiff(required_pkgs, installed)

if (length(to_install) > 0) {
  install.packages(to_install, repos = "https://cloud.r-project.org")
} else {
  cat("All required packages are already installed.\n")
}

# --- Alternative for Debian/Ubuntu systems (e.g. GitHub Codespaces, Colab) ---
# If install.packages() is slow or blocked, you can instead run, from a shell:
#
#   sudo apt-get update
#   sudo apt-get install -y r-base-core r-cran-tidyverse r-cran-caret \
#       r-cran-e1071 r-cran-car r-cran-metrics r-cran-corrplot \
#       r-cran-gridextra r-cran-scales r-cran-reshape2
