# =============================================================================
# 01_preprocessing.R
# -----------------------------------------------------------------------------
# Implements the pre-processing pipeline described in report Section 3:
#   3.1 Group-wise median imputation (annual_revenue_m) + global median
#       imputation (team_size)
#   3.2 Log(x + 1) transformation of skewed financial variables
#   3.3 Dummy/factor encoding of industry (AI/ML as reference level)
#   3.4 Outlier check via 3x IQR fence on log(valuation)
#   3.5 80/20 train/test split (seeded, reproducible)
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(caret)
  library(e1071)
})

df <- read.csv("data/processed/startup_valuation_data.csv", stringsAsFactors = FALSE)

cat("Rows loaded:", nrow(df), "\n")
cat("Missing values per column:\n")
print(colSums(is.na(df)))

# -----------------------------------------------------------------------------
# 3.1 Missing value treatment
# -----------------------------------------------------------------------------
df <- df %>%
  group_by(industry) %>%
  mutate(annual_revenue_m = ifelse(is.na(annual_revenue_m),
                                    median(annual_revenue_m, na.rm = TRUE),
                                    annual_revenue_m)) %>%
  ungroup()

df$team_size[is.na(df$team_size)] <- median(df$team_size, na.rm = TRUE)

cat("\nMissing values after imputation:\n")
print(colSums(is.na(df)))

# -----------------------------------------------------------------------------
# 3.2 Log transformation of skewed financial variables
# -----------------------------------------------------------------------------
df$log_valuation_m      <- log1p(df$valuation_m)
df$log_total_funding_m  <- log1p(df$total_funding_m)
df$log_annual_revenue_m <- log1p(df$annual_revenue_m)

skew_raw <- e1071::skewness(df$valuation_m)
skew_log <- e1071::skewness(df$log_valuation_m)
cat(sprintf("\nSkewness (raw valuation): %.3f\n", skew_raw))
cat(sprintf("Skewness (log valuation): %.3f\n", skew_log))

# -----------------------------------------------------------------------------
# 3.3 Encode industry, AI/ML as reference level
# -----------------------------------------------------------------------------
df$industry <- relevel(factor(df$industry), ref = "AI/ML")

# -----------------------------------------------------------------------------
# 3.4 Outlier detection on log(valuation), conservative 3x IQR fence
# -----------------------------------------------------------------------------
Q1  <- quantile(df$log_valuation_m, 0.25)
Q3  <- quantile(df$log_valuation_m, 0.75)
IQR_val <- Q3 - Q1

df_clean <- df %>%
  filter(log_valuation_m >= Q1 - 3 * IQR_val,
         log_valuation_m <= Q3 + 3 * IQR_val)

cat(sprintf("\nRows retained after 3xIQR outlier check: %d of %d\n",
            nrow(df_clean), nrow(df)))

# -----------------------------------------------------------------------------
# 3.5 Train / test split (80/20, stratified on target)
# -----------------------------------------------------------------------------
set.seed(42)
train_idx <- createDataPartition(df_clean$log_valuation_m, p = 0.8, list = FALSE)
train_df <- df_clean[train_idx, ]
test_df  <- df_clean[-train_idx, ]

cat(sprintf("Train: %d | Test: %d\n", nrow(train_df), nrow(test_df)))

# -----------------------------------------------------------------------------
# Save processed artifacts
# -----------------------------------------------------------------------------
dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs/tables", showWarnings = FALSE, recursive = TRUE)

write.csv(df_clean, "data/processed/startup_valuation_clean.csv", row.names = FALSE)
write.csv(train_df, "data/processed/train.csv", row.names = FALSE)
write.csv(test_df,  "data/processed/test.csv",  row.names = FALSE)

desc_stats <- df %>%
  summarise(
    across(c(valuation_m, total_funding_m, annual_revenue_m, team_size,
             funding_rounds, years_since_founding),
           list(min = ~min(.x, na.rm = TRUE),
                median = ~median(.x, na.rm = TRUE),
                mean = ~mean(.x, na.rm = TRUE),
                max = ~max(.x, na.rm = TRUE),
                sd = ~sd(.x, na.rm = TRUE)))
  )
write.csv(desc_stats, "outputs/tables/descriptive_stats.csv", row.names = FALSE)

cat("\nSaved: data/processed/startup_valuation_clean.csv, train.csv, test.csv\n")
cat("Saved: outputs/tables/descriptive_stats.csv\n")
