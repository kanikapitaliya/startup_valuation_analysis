# Raw data folder

`investments_VC.csv.zip` is the original Kaggle **"Startup Investments
(Crunchbase)"** file supplied alongside this project
(https://www.kaggle.com/datasets/arindam235/startup-investments-crunchbase).

**It is not used directly by any script in this project.** It contains
~54,000 rows with fields like `permalink`, `category_list`, `market`,
`funding_total_usd`, `country_code`, and individual funding-round columns —
but it has **no `valuation`, `annual_revenue`, or `team_size` fields**, which
are required by the regression analysis this project reproduces.

The original coursework report this project is based on states explicitly
(Section 2.1) that its analysis ran on *"a representative 500-record dataset
constructed to mirror the statistical properties of the Crunchbase corpus"* —
i.e., a simulated dataset with the same variable definitions and
distributional shape, not the raw Kaggle export itself.

This project's `R/00_simulate_dataset.R` implements that same idea as a
transparent, seeded, fully documented data-generating process, so the whole
pipeline is genuinely reproducible from a single command. See the main
README for details.
