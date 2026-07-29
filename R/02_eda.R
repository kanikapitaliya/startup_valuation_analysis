# =============================================================================
# 02_eda.R
# -----------------------------------------------------------------------------
# Exploratory Data Analysis (report Section 4).
# Produces:
#   Figure 1 - Valuation distribution before/after log transform
#   Figure 2 - Pearson correlation matrix (numeric predictors + target)
#   Figure 3 - Valuation by industry sector (boxplot)
#   Figure 9 - Funding rounds vs valuation, coloured by industry
# =============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(reshape2)
  library(gridExtra)
})
source("R/utils.R")

ensure_dir("outputs/figures")
df <- read.csv("data/processed/startup_valuation_clean.csv", stringsAsFactors = FALSE)
df$industry <- factor(df$industry, levels = industry_order)

# -----------------------------------------------------------------------------
# Figure 1: Effect of log transformation on valuation
# -----------------------------------------------------------------------------
p1a <- ggplot(df, aes(x = valuation_m)) +
  geom_histogram(bins = 35, fill = pal_navy, color = "white") +
  labs(title = "Startup Valuation Distribution\n(Raw, USD Million)",
       x = "Valuation (USD Million)", y = "Frequency") +
  annotate("text", x = max(df$valuation_m) * 0.55, y = Inf, vjust = 2,
           label = "Highly right-skewed", color = pal_coral, fontface = "italic") +
  theme_startup()

p1b <- ggplot(df, aes(x = log_valuation_m)) +
  geom_histogram(bins = 35, fill = pal_teal, color = "white") +
  labs(title = "Startup Valuation Distribution\n(Log-Transformed)",
       x = "log(Valuation + 1)", y = "Frequency") +
  annotate("text", x = quantile(df$log_valuation_m, 0.75), y = Inf, vjust = 2,
           label = "Approximately normal", color = pal_teal, fontface = "italic") +
  theme_startup()

png("outputs/figures/fig1_log_transformation.png", width = 1100, height = 500, res = 120)
grid.arrange(p1a, p1b, ncol = 2,
             top = "Figure 1: Effect of Log Transformation on Valuation")
dev.off()

# -----------------------------------------------------------------------------
# Figure 2: Pearson correlation matrix
# -----------------------------------------------------------------------------
num_vars <- df %>%
  transmute(
    `log(Valuation)`      = log_valuation_m,
    `log(Total Funding)`  = log_total_funding_m,
    `log(Revenue)`        = log_annual_revenue_m,
    `Funding Rounds`      = funding_rounds,
    `Team Size`           = team_size,
    `Years Since Founding` = years_since_founding
  )

cor_mat <- round(cor(num_vars, use = "complete.obs"), 2)
cor_melt <- melt(cor_mat)

p2 <- ggplot(cor_melt, aes(Var2, Var1, fill = value)) +
  geom_tile(color = "white") +
  geom_text(aes(label = sprintf("%.2f", value)), size = 3.5) +
  scale_fill_gradient2(low = "#4575b4", mid = "white", high = "#c0392b",
                        midpoint = 0, limits = c(-1, 1), name = "r") +
  labs(title = "Figure 2: Pearson Correlation Matrix - Key Variables",
       x = NULL, y = NULL) +
  theme_startup() +
  theme(axis.text.x = element_text(angle = 40, hjust = 1))

ggsave("outputs/figures/fig2_correlation_matrix.png", p2, width = 7.5, height = 6, dpi = 120)

write.csv(cor_mat, "outputs/tables/correlation_matrix.csv")

# -----------------------------------------------------------------------------
# Figure 3: Valuation by industry sector
# -----------------------------------------------------------------------------
industry_medians <- df %>%
  group_by(industry) %>%
  summarise(med = round(median(log_valuation_m), 2))

p3 <- ggplot(df, aes(x = industry, y = log_valuation_m, fill = industry)) +
  geom_boxplot(show.legend = FALSE, outlier.color = pal_slate) +
  geom_text(data = industry_medians, aes(x = industry, y = med, label = med),
            inherit.aes = FALSE, size = 3, fontface = "bold", vjust = -0.4) +
  labs(title = "Figure 3: Startup Valuation Distribution by Industry Sector",
       x = "Industry Sector", y = "log(Valuation, USD M)") +
  theme_startup() +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))

ggsave("outputs/figures/fig3_valuation_by_industry.png", p3, width = 8, height = 5.5, dpi = 120)

write.csv(industry_medians, "outputs/tables/industry_median_valuation.csv", row.names = FALSE)

# -----------------------------------------------------------------------------
# Figure 9: Funding rounds vs valuation, coloured by industry
# -----------------------------------------------------------------------------
p9 <- ggplot(df, aes(x = funding_rounds, y = log_valuation_m, color = industry)) +
  geom_jitter(width = 0.15, alpha = 0.7, size = 1.8) +
  labs(title = "Figure 9: Funding Rounds vs Valuation by Industry",
       x = "Number of Funding Rounds", y = "log(Valuation, USD M)", color = "Industry") +
  theme_startup()

ggsave("outputs/figures/fig9_funding_rounds_by_industry.png", p9, width = 8, height = 5.5, dpi = 120)

cat("EDA figures written to outputs/figures/\n")
cat("\nKey correlations with log(Valuation):\n")
print(sort(cor_mat[, "log(Valuation)"], decreasing = TRUE))
