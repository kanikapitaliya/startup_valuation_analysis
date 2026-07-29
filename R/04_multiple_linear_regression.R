# =============================================================================
# 04_multiple_linear_regression.R
# -----------------------------------------------------------------------------
# Multiple Linear Regression (report Section 6):
#   log(Valuation) = b0 + b1*log(Funding) + b2*log(Revenue) + b3*Rounds +
#                    b4*TeamSize + b5*YearsSince + sum(bi*Industry_i) + e
# Produces:
#   Figure 6  - Actual vs Predicted (test set)
#   Figure 7  - Diagnostic plots (residuals vs fitted, Q-Q)
#   Figure 8  - Standardised coefficients (predictor importance)
#   Figure 10 - Variance Inflation Factors (multicollinearity check)
# =============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(gridExtra)
  library(car)
  library(Metrics)
})
source("R/utils.R")

ensure_dir("outputs/figures")
ensure_dir("outputs/tables")

train_df <- read.csv("data/processed/train.csv", stringsAsFactors = FALSE)
test_df  <- read.csv("data/processed/test.csv",  stringsAsFactors = FALSE)

train_df$industry <- relevel(factor(train_df$industry), ref = "AI/ML")
test_df$industry  <- factor(test_df$industry, levels = levels(train_df$industry))

# -----------------------------------------------------------------------------
# Fit model
# -----------------------------------------------------------------------------
mlr_model <- lm(log_valuation_m ~
                   log_total_funding_m + log_annual_revenue_m + funding_rounds +
                   team_size + years_since_founding + industry,
                 data = train_df)
print(summary(mlr_model))

test_df$mlr_pred <- predict(mlr_model, newdata = test_df)

r2_train  <- summary(mlr_model)$r.squared
adj_r2    <- summary(mlr_model)$adj.r.squared
ss_res    <- sum((test_df$log_valuation_m - test_df$mlr_pred)^2)
ss_tot    <- sum((test_df$log_valuation_m - mean(test_df$log_valuation_m))^2)
r2_test   <- 1 - ss_res / ss_tot
rmse_test <- Metrics::rmse(test_df$log_valuation_m, test_df$mlr_pred)
mae_test  <- Metrics::mae(test_df$log_valuation_m, test_df$mlr_pred)

cat(sprintf("\nR2 (train): %.4f | Adjusted R2: %.4f\n", r2_train, adj_r2))
cat(sprintf("R2 (test):  %.4f\n", r2_test))
cat(sprintf("RMSE (test): %.4f\n", rmse_test))
cat(sprintf("MAE (test):  %.4f\n", mae_test))

coef_tab <- as.data.frame(summary(mlr_model)$coefficients)
coef_tab$Term <- rownames(coef_tab)
coef_tab <- coef_tab[, c("Term", "Estimate", "Std. Error", "t value", "Pr(>|t|)")]
write.csv(coef_tab, "outputs/tables/mlr_coefficients.csv", row.names = FALSE)

# -----------------------------------------------------------------------------
# Figure 6: Actual vs Predicted (test set)
# -----------------------------------------------------------------------------
p6 <- ggplot(test_df, aes(x = log_valuation_m, y = mlr_pred)) +
  geom_point(color = pal_slate, alpha = 0.7, size = 2) +
  geom_abline(slope = 1, intercept = 0, color = pal_coral, linetype = "dashed", linewidth = 0.8) +
  labs(title = sprintf("Figure 6: MLR - Actual vs Predicted (Test Set, R\u00b2=%.3f, Adj-R\u00b2=%.3f)",
                        r2_test, adj_r2),
       x = "Actual log(Valuation)", y = "Predicted log(Valuation)") +
  theme_startup()

ggsave("outputs/figures/fig6_mlr_actual_vs_predicted.png", p6, width = 7.5, height = 6, dpi = 120)

# -----------------------------------------------------------------------------
# Figure 7: Diagnostic plots
# -----------------------------------------------------------------------------
diag_df <- data.frame(fitted = fitted(mlr_model), resid = resid(mlr_model))

p7a <- ggplot(diag_df, aes(fitted, resid)) +
  geom_point(color = pal_teal, alpha = 0.5) +
  geom_hline(yintercept = 0, linetype = "dashed", color = pal_coral) +
  geom_smooth(se = FALSE, color = pal_navy, linewidth = 0.7) +
  labs(title = "Residuals vs Fitted - MLR", x = "Fitted Values", y = "Residuals") +
  theme_startup()

qq_df <- as.data.frame(qqnorm(diag_df$resid, plot.it = FALSE))
p7b <- ggplot(qq_df, aes(x, y)) +
  geom_point(color = pal_teal, alpha = 0.5) +
  geom_qq_line(aes(sample = diag_df$resid), color = pal_coral) +
  labs(title = "Q-Q Plot - MLR Residuals", x = "Theoretical Quantiles", y = "Sample Quantiles") +
  theme_startup()

png("outputs/figures/fig7_mlr_diagnostics.png", width = 1100, height = 500, res = 120)
grid.arrange(p7a, p7b, ncol = 2, top = "Figure 7: MLR Diagnostic Plots")
dev.off()

# -----------------------------------------------------------------------------
# Figure 8: Standardised coefficients (predictor importance)
# -----------------------------------------------------------------------------
scaled_train <- train_df %>%
  mutate(across(c(log_total_funding_m, log_annual_revenue_m, funding_rounds,
                   team_size, years_since_founding, log_valuation_m), scale))

mlr_scaled <- lm(log_valuation_m ~ log_total_funding_m + log_annual_revenue_m +
                    funding_rounds + team_size + years_since_founding + industry,
                  data = scaled_train)

std_coef <- coef(mlr_scaled)[-1]
std_coef <- std_coef[!grepl("industryAI/ML", names(std_coef))]  # reference level has no coef
names(std_coef) <- gsub("^industry", "", names(std_coef))
names(std_coef) <- gsub("^log_total_funding_m$", "log(Total Funding)", names(std_coef))
names(std_coef) <- gsub("^log_annual_revenue_m$", "log(Revenue)", names(std_coef))
names(std_coef) <- gsub("^funding_rounds$", "Funding Rounds", names(std_coef))
names(std_coef) <- gsub("^team_size$", "Team Size", names(std_coef))
names(std_coef) <- gsub("^years_since_founding$", "Years Since Founding", names(std_coef))

std_df <- data.frame(predictor = names(std_coef), beta = as.numeric(std_coef)) %>%
  arrange(beta) %>%
  mutate(predictor = factor(predictor, levels = predictor),
         direction = ifelse(beta >= 0, "Positive effect on valuation", "Negative effect on valuation"))

p8 <- ggplot(std_df, aes(x = predictor, y = beta, fill = direction)) +
  geom_col() +
  geom_text(aes(label = sprintf("%.3f", beta),
                hjust = ifelse(beta >= 0, -0.15, 1.1)), size = 3.2) +
  coord_flip() +
  scale_fill_manual(values = c("Positive effect on valuation" = pal_teal,
                                "Negative effect on valuation" = pal_coral)) +
  labs(title = "Figure 8: Standardized Regression Coefficients\n(Relative Importance of Predictors)",
       x = NULL, y = "Standardized Coefficient (\u03b2)", fill = NULL) +
  theme_startup() +
  theme(legend.position = "bottom")

ggsave("outputs/figures/fig8_standardized_coefficients.png", p8, width = 8, height = 6, dpi = 120)
write.csv(std_df, "outputs/tables/standardized_coefficients.csv", row.names = FALSE)

# -----------------------------------------------------------------------------
# Figure 10: Variance Inflation Factor (multicollinearity check)
# -----------------------------------------------------------------------------
vif_vals <- car::vif(mlr_model)
if (is.matrix(vif_vals)) vif_vals <- vif_vals[, 1]  # GVIF for factors
vif_df <- data.frame(predictor = names(vif_vals), VIF = as.numeric(vif_vals))

p10 <- ggplot(vif_df, aes(x = reorder(predictor, VIF), y = VIF)) +
  geom_col(fill = pal_teal) +
  geom_text(aes(label = sprintf("%.1f", VIF)), vjust = -0.4, size = 3.2) +
  geom_hline(yintercept = 5, linetype = "dashed", color = pal_coral) +
  geom_hline(yintercept = 10, linetype = "dotted", color = "firebrick") +
  labs(title = "Figure 10: Variance Inflation Factor (VIF) - Multicollinearity Check",
       x = NULL, y = "VIF") +
  theme_startup() +
  theme(axis.text.x = element_text(angle = 35, hjust = 1))

ggsave("outputs/figures/fig10_vif.png", p10, width = 8, height = 5.5, dpi = 120)
write.csv(vif_df, "outputs/tables/vif_table.csv", row.names = FALSE)

saveRDS(mlr_model, "outputs/tables/mlr_model.rds")

cat("\nMax VIF:", round(max(vif_df$VIF), 2), "\n")
cat("MLR outputs written to outputs/figures/ and outputs/tables/\n")
