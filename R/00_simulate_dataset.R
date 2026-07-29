# =============================================================================
# 00_simulate_dataset.R
# -----------------------------------------------------------------------------
# Generates the 500-record startup dataset used throughout this project.
#
# WHY A SIMULATED DATASET?
# The report this project is based on states (Section 2.1) that its data was
# "a representative 500-record dataset constructed to mirror the statistical
# properties of the Crunchbase corpus" -- NOT the raw Kaggle file as-is. The
# raw Kaggle file ("investments_VC.csv", ~54,000 rows) has no valuation,
# revenue, or team-size fields at all, so it cannot directly reproduce the
# analysis. This script implements a fully documented, seeded data-generating
# process (DGP) that reproduces the variable definitions, distributions, and
# correlation structure described in the report, so that every downstream
# script in this project runs on genuine, reproducible data rather than
# hard-coded results.
#
# Method: a two-factor Gaussian copula.
#   F1 = "growth / funding-stage" factor
#   F2 = "operational-scale" factor
# Each numeric predictor is a weighted mix of F1, F2 and idiosyncratic noise,
# which analytically fixes its correlations with the other predictors. Each
# standard-normal variable is then mapped to its target real-world scale.
# Valuation is generated from an explicit structural (true) regression
# equation with industry effects, so the whole pipeline is a genuine,
# checkable simulation rather than numbers copied from a report.
# =============================================================================

set.seed(42)
n <- 500

# -----------------------------------------------------------------------------
# 1. Latent factors
# -----------------------------------------------------------------------------
F1 <- rnorm(n)   # growth / funding-stage factor
F2 <- rnorm(n)   # operational-scale factor

Z_funding <- 0.80 * F1 + sqrt(1 - 0.80^2) * rnorm(n)
Z_rounds  <- 0.75 * F1 + sqrt(1 - 0.75^2) * rnorm(n)
Z_revenue <- 0.40 * F1 + 0.60 * F2 + sqrt(1 - (0.40^2 + 0.60^2)) * rnorm(n)
Z_team    <- 0.30 * F1 + 0.70 * F2 + sqrt(1 - (0.30^2 + 0.70^2)) * rnorm(n)

# -----------------------------------------------------------------------------
# 2. Categorical variables
# -----------------------------------------------------------------------------
industry_levels <- c("AI/ML", "FinTech", "SaaS", "HealthTech",
                      "EdTech", "BioTech", "CleanTech", "E-Commerce")
industry_counts <- c(65, 65, 60, 60, 60, 65, 60, 65)   # matches report's ~12-13% split
stopifnot(sum(industry_counts) == n)
industry <- sample(rep(industry_levels, times = industry_counts))

# Hot sectors (AI/ML, FinTech) also tend to attract more capital, not just a
# higher valuation at a given funding level -- a realistic, documented link
# that keeps the industry effect and the funding effect from being fully
# independent (see report Sec 4.3 on the AI/ML funding premium).
industry_funding_boost <- c(
  "AI/ML" = 0.35, "FinTech" = 0.05, "SaaS" = 0.00, "HealthTech" = -0.05,
  "EdTech" = -0.30, "BioTech" = 0.05, "CleanTech" = -0.15, "E-Commerce" = -0.20
)
Z_funding <- Z_funding + 0.5 * industry_funding_boost[industry]

country_levels <- c("USA", "India", "UK", "Germany",
                     "Singapore", "Canada", "Israel", "Brazil")
country_counts <- c(190, 90, 60, 40, 30, 30, 30, 30)   # 38/18/12/8/6/6/6/6 %
stopifnot(sum(country_counts) == n)
country <- sample(rep(country_levels, times = country_counts))

# -----------------------------------------------------------------------------
# 3. Founding year -> years since founding (independent of the growth factors,
#    matching the near-zero correlations reported between age and funding)
# -----------------------------------------------------------------------------
year_founded <- sample(2000:2021, n, replace = TRUE)
years_since_founding <- 2024 - year_founded

# -----------------------------------------------------------------------------
# 4. Map latent normals to real-world scales
# -----------------------------------------------------------------------------
log_total_funding_m   <- 5.15 + 1.00 * Z_funding
funding_rounds        <- round(4.5 + 1.9 * Z_rounds)
funding_rounds        <- pmin(pmax(funding_rounds, 1), 8)
log_annual_revenue_m  <- 3.20 + 1.25 * Z_revenue
team_size             <- round(400 + 220 * Z_team)
team_size             <- pmin(pmax(team_size, 5), 798)

total_funding_m  <- pmax(expm1(log_total_funding_m), 0.5)
annual_revenue_m <- pmax(expm1(log_annual_revenue_m), 0.1)

# -----------------------------------------------------------------------------
# 5. True structural equation for valuation (the "ground truth" regression)
#    Coefficients are chosen to reflect realistic VC heuristics: funding
#    dominates, industry creates large premiums/discounts, age is irrelevant
#    once stage (funding rounds) is accounted for.
# -----------------------------------------------------------------------------
industry_effect <- c(
  "AI/ML" = 0.00, "FinTech" = -0.20, "SaaS" = -0.47, "HealthTech" = -0.54,
  "EdTech" = -1.01, "BioTech" = -0.35, "CleanTech" = -0.72, "E-Commerce" = -0.90
)

beta0 <- 3.55
b_funding <- 0.55
b_revenue <- 0.08
b_rounds  <- 0.03
b_team    <- 0.00035
b_age     <- 0.00      # true effect is zero -> should come out non-significant

linear_predictor <- beta0 +
  b_funding * log_total_funding_m +
  b_revenue * log_annual_revenue_m +
  b_rounds  * funding_rounds +
  b_team    * team_size +
  b_age     * years_since_founding +
  industry_effect[industry]

# noise sd calibrated so SLR R^2 ~ 0.65-0.70 and MLR R^2 ~ 0.84-0.86,
# matching the order of magnitude reported in the source analysis
noise <- rnorm(n, mean = 0, sd = 0.33)
log_valuation_m <- linear_predictor + noise
valuation_m <- pmax(expm1(log_valuation_m), 1)

# -----------------------------------------------------------------------------
# 6. Assemble data frame
# -----------------------------------------------------------------------------
startup_id <- sprintf("ST%04d", seq_len(n))

df <- data.frame(
  startup_id            = startup_id,
  industry              = industry,
  country               = country,
  year_founded          = year_founded,
  years_since_founding  = years_since_founding,
  funding_rounds        = funding_rounds,
  total_funding_m       = round(total_funding_m, 2),
  annual_revenue_m      = round(annual_revenue_m, 2),
  team_size             = team_size,
  valuation_m           = round(valuation_m, 2),
  stringsAsFactors = FALSE
)

# -----------------------------------------------------------------------------
# 7. Introduce realistic missingness (MCAR), matching the report's stated
#    7% missing on annual_revenue_m and 4% missing on team_size
# -----------------------------------------------------------------------------
set.seed(43)
na_revenue_idx <- sample(seq_len(n), size = round(0.07 * n))
na_team_idx    <- sample(seq_len(n), size = round(0.04 * n))
df$annual_revenue_m[na_revenue_idx] <- NA
df$team_size[na_team_idx]           <- NA

# -----------------------------------------------------------------------------
# 8. Save
# -----------------------------------------------------------------------------
dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
write.csv(df, "data/processed/startup_valuation_data.csv", row.names = FALSE)

cat("Simulated dataset written to data/processed/startup_valuation_data.csv\n")
cat("Rows:", nrow(df), " | Columns:", ncol(df), "\n")
cat("Missing - annual_revenue_m:", sum(is.na(df$annual_revenue_m)),
    " | team_size:", sum(is.na(df$team_size)), "\n")
