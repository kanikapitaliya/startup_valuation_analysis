# What Influences Startup Valuation?
### A Data-Driven Analysis Using Simple & Multiple Linear Regression in R

This project investigates the determinants of startup valuation using Simple
Linear Regression (SLR) and Multiple Linear Regression (MLR) in R — total
funding raised, annual revenue, funding rounds, team size, company age, and
industry sector are used to explain and predict `log(valuation)`.

It is a fully reproducible, end-to-end R pipeline: one command regenerates
the dataset, cleans it, runs the EDA, fits both models, produces every
figure/table, and prints the model comparison.

---

## Crunchbase Dataset

The original raw Kaggle file is kept in `data/raw/` for provenance but is not
read by any script.

---

## Project structure

```
.
├── R/
│   ├── 00_simulate_dataset.R          # builds the 500-row dataset (see note above)
│   ├── 01_preprocessing.R             # imputation, log transforms, encoding, split
│   ├── 02_eda.R                       # Figures 1, 2, 3, 9
│   ├── 03_simple_linear_regression.R  # Figures 4, 5 + SLR summary table
│   ├── 04_multiple_linear_regression.R# Figures 6, 7, 8, 10 + MLR/VIF tables
│   ├── 05_model_comparison.R          # SLR vs MLR head-to-head table
│   └── utils.R                        # shared ggplot theme / constants
├── run_all.R                          # runs every step above, in order
├── install_packages.R                 # installs all R dependencies
├── data/
│   ├── raw/                           # original Kaggle CSV (not used directly, see note)
│   └── processed/                     # generated + cleaned data, train/test splits
├── outputs/
│   ├── figures/                       # all 10 figures as .png
│   └── tables/                        # all model/summary tables as .csv, saved model .rds files
└── SESSION_INFO.txt                   # R version + package versions used to build this
```

## Variables

| Variable | Type | Description |
|---|---|---|
| `startup_id` | categorical | unique ID (e.g. `ST0001`) |
| `industry` | categorical | one of 8 sectors (AI/ML, FinTech, SaaS, HealthTech, EdTech, BioTech, CleanTech, E-Commerce) |
| `country` | categorical | HQ country (USA, India, UK, Germany, Singapore, Canada, Israel, Brazil) |
| `year_founded` | numeric | year incorporated |
| `years_since_founding` | numeric | 2024 − year_founded |
| `funding_rounds` | numeric | total external funding rounds (1–8) |
| `total_funding_m` | numeric (USD M) | cumulative funding raised |
| `annual_revenue_m` | numeric (USD M) | most recent annual revenue (7% missing) |
| `team_size` | numeric | headcount at last funding round (4% missing) |
| `valuation_m` | numeric (USD M) | **target** — post-money valuation at last round |

## How to run

```bash
# 1. Install R (>= 4.1) if you don't have it, then install dependencies:
Rscript install_packages.R

# 2. Run the full pipeline:
Rscript run_all.R
```

This regenerates everything in `data/processed/` and `outputs/` from
scratch. Total runtime is a few seconds.

To run a single stage (e.g. just the EDA) once the earlier stages have been
run at least once:

```bash
Rscript R/02_eda.R
```

## Methodology

1. **Simulation** (`00`): builds the 500-row dataset (see note above).
2. **Pre-processing** (`01`): group-wise median imputation of
   `annual_revenue_m` by industry, global median imputation of `team_size`,
   `log1p()` transform of the three skewed financial variables, `industry`
   releveled with `AI/ML` as the reference category, a conservative 3×IQR
   outlier check on `log(valuation)`, and an 80/20 train/test split
   (`caret::createDataPartition`, seeded).
3. **EDA** (`02`): distribution shape before/after log transform, Pearson
   correlation matrix, valuation by industry, funding rounds vs valuation by
   industry.
4. **SLR** (`03`): `log(valuation) ~ log(total_funding)`, fit on the training
   set, evaluated on the held-out test set.
5. **MLR** (`04`): `log(valuation) ~ log(funding) + log(revenue) + rounds +
   team_size + years_since_founding + industry`, with VIF multicollinearity
   diagnostics and standardised (β) coefficients for predictor-importance
   ranking.
6. **Comparison** (`05`): SLR vs MLR side-by-side on R², adjusted R², test
   RMSE/MAE, and predictor significance counts.

## Results

Fitted on this project's generated data (your numbers will vary slightly if
you re-run the simulation with a different seed):

| Metric | Simple LR | Multiple LR |
|---|---|---|
| R² (train) | 0.650 | 0.855 |
| Adjusted R² (train) | 0.649 | 0.850 |
| R² (test) | 0.489 | 0.755 |
| RMSE (test, log scale) | 0.543 | 0.376 |
| MAE (test, log scale) | 0.445 | 0.296 |
| Predictors | 1 | 12 |
| Significant predictors (p<0.05) | 1/1 | 11/12 |
| Max VIF | — | 1.64 (no multicollinearity) |

Key findings (see `outputs/tables/` for full detail):

- **Total funding raised** is by far the strongest predictor of valuation
  (standardised β ≈ 0.64), consistent with funding acting as a market signal
  of investor conviction.
- **Industry sector** creates large, statistically significant premiums and
  discounts relative to AI/ML — EdTech and E-Commerce are the most heavily
  discounted sectors in this sample.
- **Years since founding** is not a significant predictor once funding stage
  is controlled for — age alone doesn't move valuation.
- No multicollinearity concerns (all VIFs well under 5).

## Dependencies

R ≥ 4.1, with: `tidyverse`, `caret`, `e1071`, `car`, `Metrics`, `corrplot`,
`gridExtra`, `scales`, `reshape2`. See `install_packages.R` and
`SESSION_INFO.txt` for exact versions used to build this repo.

## References

1. Crunchbase. (2023). *Crunchbase Annual Startup Funding Report 2022.*
2. Gompers, P., Gornall, W., Kaplan, S. N., & Strebulaev, I. A. (2020). How do
   venture capitalists make decisions? *Journal of Financial Economics*,
   135(1), 169–190.
3. Kaplan, S. N., & Lerner, J. (2010). It ain't broke: The past, present, and
   future of venture capital. *Journal of Applied Corporate Finance*, 22(2),
   36–47.
4. James, G., Witten, D., Hastie, T., & Tibshirani, R. (2021). *An
   Introduction to Statistical Learning with Applications in R* (2nd ed.).
   Springer.
5. Kaggle. (2023). *Startup Investments (Crunchbase) Dataset.*
   https://www.kaggle.com/datasets/arindam235/startup-investments-crunchbase

## License

MIT — see `LICENSE`.
