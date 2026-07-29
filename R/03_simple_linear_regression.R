# =============================================================================
# 03_simple_linear_regression.R
# -----------------------------------------------------------------------------
# Simple Linear Regression (report Section 5):
#   log(Valuation + 1) = b0 + b1 * log(Total Funding + 1) + e
# Produces Figure 4 (scatter + regression line) and Figure 5 (diagnostics),
# plus a coefficient table and test-set performance metrics.
# =============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(gridExtra)
  library(Metrics)
})
source("R/utils.R")

ensure_dir("outputs/figures")
ensure_dir("outputs/tables")

train_df <- read.csv("data/processed/train.csv", stringsAsFactors = FALSE)
test_df  <- read.csv("data/processed/test.csv",  stringsAsFactors = FALSE)

# -----------------------------------------------------------------------------
# Fit model
# -----------------------------------------------------------------------------
slr_model <- lm(log_valuation_m ~ log_total_funding_m, data = train_df)
print(summary(slr_model))

test_df$slr_pred <- predict(slr_model, newdata = test_df)

r2_train   <- summary(slr_model)$r.squared
r2_test    <- cor(test_df$log_valuation_m, test_df$slr_pred)^2
rmse_test  <- Metrics::rmse(test_df$log_valuation_m, test_df$slr_pred)
mae_test   <- Metrics::mae(test_df$log_valuation_m, test_df$slr_pred)

cat(sprintf("\nR2 (train): %.4f\n", r2_train))
cat(sprintf("R2 (test):  %.4f\n", r2_test))
cat(sprintf("RMSE (test): %.4f\n", rmse_test))
cat(sprintf("MAE (test):  %.4f\n", mae_test))

coef_tab <- as.data.frame(summary(slr_model)$coefficients)
coef_tab$Term <- rownames(coef_tab)
coef_tab <- coef_tab[, c("Term", "Estimate", "Std. Error", "t value", "Pr(>|t|)")]
coef_tab <- rbind(coef_tab,
                   data.frame(Term = "R2 (train)", Estimate = r2_train,
                              `Std. Error` = NA, `t value` = NA, `Pr(>|t|)` = NA,
                              check.names = FALSE),
                   data.frame(Term = "R2 (test)", Estimate = r2_test,
                              `Std. Error` = NA, `t value` = NA, `Pr(>|t|)` = NA,
                              check.names = FALSE),
                   data.frame(Term = "RMSE (test)", Estimate = rmse_test,
                              `Std. Error` = NA, `t value` = NA, `Pr(>|t|)` = NA,
                              check.names = FALSE),
                   data.frame(Term = "MAE (test)", Estimate = mae_test,
                              `Std. Error` = NA, `t value` = NA, `Pr(>|t|)` = NA,
                              check.names = FALSE))
write.csv(coef_tab, "outputs/tables/slr_summary.csv", row.names = FALSE)

b0 <- coef(slr_model)[1]
b1 <- coef(slr_model)[2]
eq_label <- sprintf("y = %.3f + %.3f\u00b7x", b0, b1)

# -----------------------------------------------------------------------------
# Figure 4: Scatter plot with regression line + 95% CI
# -----------------------------------------------------------------------------
p4 <- ggplot(train_df, aes(x = log_total_funding_m, y = log_valuation_m)) +
  geom_point(color = pal_slate, alpha = 0.55, size = 1.8) +
  geom_smooth(method = "lm", color = pal_coral, fill = pal_coral, alpha = 0.2) +
  annotate("label", x = min(train_df$log_total_funding_m) + 0.3,
           y = max(train_df$log_valuation_m) - 0.2, label = eq_label,
           hjust = 0, fill = "white") +
  labs(title = "Figure 4: Simple Linear Regression - Total Funding vs Valuation",
       x = "log(Total Funding, USD M)", y = "log(Valuation, USD M)") +
  theme_startup()

ggsave("outputs/figures/fig4_slr_scatter.png", p4, width = 8, height = 6, dpi = 120)

# -----------------------------------------------------------------------------
# Figure 5: Diagnostic plots
# -----------------------------------------------------------------------------
diag_df <- data.frame(fitted = fitted(slr_model), resid = resid(slr_model))

p5a <- ggplot(diag_df, aes(fitted, resid)) +
  geom_point(color = pal_teal, alpha = 0.6) +
  geom_hline(yintercept = 0, linetype = "dashed", color = pal_coral) +
  labs(title = "Residuals vs Fitted - SLR", x = "Fitted Values", y = "Residuals") +
  theme_startup()

qq_df <- as.data.frame(qqnorm(diag_df$resid, plot.it = FALSE))
p5b <- ggplot(qq_df, aes(x, y)) +
  geom_point(color = pal_teal, alpha = 0.6) +
  geom_qq_line(aes(sample = diag_df$resid), color = pal_coral) +
  labs(title = "Q-Q Plot - SLR Residuals", x = "Theoretical Quantiles", y = "Sample Quantiles") +
  theme_startup()

png("outputs/figures/fig5_slr_diagnostics.png", width = 1100, height = 500, res = 120)
grid.arrange(p5a, p5b, ncol = 2, top = "Figure 5: SLR Diagnostic Plots")
dev.off()

saveRDS(slr_model, "outputs/tables/slr_model.rds")
cat("\nSLR outputs written to outputs/figures/ and outputs/tables/\n")
