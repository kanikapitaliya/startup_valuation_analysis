# =============================================================================
# 05_model_comparison.R
# -----------------------------------------------------------------------------
# Head-to-head comparison of SLR vs MLR on the held-out test set
# (report Section 7).
# =============================================================================

suppressPackageStartupMessages({
  library(Metrics)
})
source("R/utils.R")

train_df <- read.csv("data/processed/train.csv", stringsAsFactors = FALSE)
test_df  <- read.csv("data/processed/test.csv",  stringsAsFactors = FALSE)

train_df$industry <- relevel(factor(train_df$industry), ref = "AI/ML")
test_df$industry  <- factor(test_df$industry, levels = levels(train_df$industry))

slr_model <- lm(log_valuation_m ~ log_total_funding_m, data = train_df)
mlr_model <- lm(log_valuation_m ~ log_total_funding_m + log_annual_revenue_m +
                   funding_rounds + team_size + years_since_founding + industry,
                 data = train_df)

eval_model <- function(model, test_df) {
  pred <- predict(model, newdata = test_df)
  ss_res <- sum((test_df$log_valuation_m - pred)^2)
  ss_tot <- sum((test_df$log_valuation_m - mean(test_df$log_valuation_m))^2)
  list(
    r2_test   = 1 - ss_res / ss_tot,
    rmse_test = Metrics::rmse(test_df$log_valuation_m, pred),
    mae_test  = Metrics::mae(test_df$log_valuation_m, pred)
  )
}

slr_eval <- eval_model(slr_model, test_df)
mlr_eval <- eval_model(mlr_model, test_df)

n_sig <- function(model) {
  p <- summary(model)$coefficients[-1, "Pr(>|t|)"]
  sum(p < 0.05)
}

comparison <- data.frame(
  Metric = c("R2 (Train)", "Adjusted R2 (Train)", "R2 (Test)", "RMSE (Test, log scale)",
             "MAE (Test, log scale)", "No. of Predictors", "Significant Predictors (p<0.05)"),
  Simple_LR = c(
    round(summary(slr_model)$r.squared, 4),
    round(summary(slr_model)$adj.r.squared, 4),
    round(slr_eval$r2_test, 4),
    round(slr_eval$rmse_test, 4),
    round(slr_eval$mae_test, 4),
    1,
    n_sig(slr_model)
  ),
  Multiple_LR = c(
    round(summary(mlr_model)$r.squared, 4),
    round(summary(mlr_model)$adj.r.squared, 4),
    round(mlr_eval$r2_test, 4),
    round(mlr_eval$rmse_test, 4),
    round(mlr_eval$mae_test, 4),
    length(coef(mlr_model)) - 1,
    n_sig(mlr_model)
  )
)

print(comparison)

ensure_dir("outputs/tables")
write.csv(comparison, "outputs/tables/model_comparison.csv", row.names = FALSE)

# Multiplicative error factor on the original (non-log) scale: exp(RMSE)
cat(sprintf("\nSLR typical multiplicative error: %.2fx\n", exp(slr_eval$rmse_test)))
cat(sprintf("MLR typical multiplicative error: %.2fx\n", exp(mlr_eval$rmse_test)))

cat("\nSaved: outputs/tables/model_comparison.csv\n")
