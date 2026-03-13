# # Does Iceland Fit Economically into the EU?

An econometric analysis examining whether Iceland shares long-run economic equilibria with the European Union, using quarterly macroeconomic data from Eurostat.

## Motivation

Iceland is deeply integrated into the European single market through the EEA agreement, yet remains outside the EU and the eurozone. This project applies a sequence of econometric and statistical methods to assess how well Iceland's economy aligns with that of the EU — a question with implications for monetary policy independence, trade integration, and the perennial Icelandic EU membership debate.

The analysis is structured around a central question: **if Iceland joined the EU and adopted the euro, would it be entering an economic area whose cycles, price dynamics, and trade patterns align with its own?**

## Methods

The project applies four complementary approaches, each answering a different aspect of the question:

1. **Cointegration analysis** — Tests whether key macroeconomic series (GDP, price levels, interest rates, trade openness) share long-run equilibrium relationships between Iceland and EU/Nordic comparators. Uses Engle-Granger bivariate tests and Johansen multivariate trace tests, preceded by ADF and KPSS unit root testing.

2. **Cluster analysis** — Positions Iceland within the broader European economic landscape using a panel of structural indicators. Identifies which group of EU member states Iceland most closely resembles and whether it is a natural member of any existing cluster or a persistent outlier.

3. **Optimum Currency Area (OCA) analysis** — Evaluates Iceland against the classical OCA criteria: business cycle synchronization, structural similarity, asymmetric shock exposure, labor mobility, and fiscal transfer capacity. Quantified through dynamic correlations, sectoral decomposition, and variance analysis.

4. **Synthetic Control Method (SCM)** — Constructs a counterfactual "synthetic Iceland" from a weighted combination of EU member states to estimate what Iceland's economic trajectory would have looked like under EU membership. Provides a causal framing for the membership question.

## Comparison group

- **Eurozone aggregate** (EA20)
- **Nordic EU members**: Denmark, Sweden, Finland

These were chosen to provide both a broad benchmark (eurozone) and the most structurally comparable EU members (fellow Nordic economies with similar institutions, welfare models, and trade exposure).

## Data

All data is sourced from Eurostat via the `eurostat` R package, supplemented where necessary with data from Hagstofa Íslands (Statistics Iceland) and Seðlabanki Íslands (Central Bank of Iceland).

Key series:
- Real GDP (chain-linked volumes)
- HICP (Harmonised Index of Consumer Prices)
- 10-year government bond yields
- Trade openness (exports + imports as share of GDP)

## Tools

- **R** with tidyverse, eurostat, urca, tseries, vars
- Visualizations in ggplot2

## Output

Analysis and visualizations supporting a short-form piece for *Vísbending* and accompanying posts on X.

## Author

Viðar Ingason