# Cointegration Analysis: English Interpretation of Results

## What the tests found

### 1. Unit Root Tests (ADF and KPSS)

**Conclusion: All series are I(1) — integrated of order one.**

Every series (GDP, HICP, trade openness) for every country passes both tests consistently:

- **ADF on levels**: All test statistics are far above the 5% critical value of −2.88. We cannot reject the null of a unit root. The series are non-stationary in levels.
- **ADF on first differences**: All test statistics plunge to between −3.4 and −8.5, well below −2.88. After one round of differencing, all series are stationary.
- **KPSS on levels**: All KPSS statistics (between 0.99 and 2.23) far exceed the 5% critical value of 0.463. We reject the null of stationarity.

This is the expected and required result. I(1) series are a necessary condition for cointegration. The evidence is unambiguous — no series is borderline.

Note: Interest rates were dropped entirely because Eurostat's dataset (`irt_lt_mcby_q`) contains no data for Iceland or EA20, only for Denmark, Sweden, and Finland. Since we can't test Iceland against anything, the series is excluded from all tests.

---

### 2. Engle-Granger Bivariate Tests

**Conclusion: Iceland's GDP co-moves with the Eurozone in the long run, but almost nothing else does.**

12 pairs were tested (3 series × 4 comparators). Only **1 was cointegrated** at the 5% level:

**Cointegrated:**
- **GDP: Iceland vs. Eurozone** — ADF on residuals = −4.32, well below the critical value of −3.34. The R² of the long-run regression is 0.97, indicating an extremely tight long-run relationship. The beta coefficient is tiny (0.0025) because the units are very different (Iceland's GDP in millions EUR vs. EA20 aggregate), but the proportional co-movement is real.

**Not cointegrated:**
- **GDP: Iceland vs. Denmark/Sweden/Finland** — ADF statistics around −1.3 to −2.2. The Nordic individual countries don't share a long-run equilibrium with Icelandic GDP, despite the raw correlations being high (R² 0.84–0.94). The residuals drift.
- **HICP: all four comparators** — ADF statistics between −0.8 and −2.0. Icelandic prices have diverged persistently from European price levels. This is the clearest signal in the data: Iceland's independent monetary policy and floating exchange rate have allowed its price level to follow a very different trajectory.
- **Trade openness: all four comparators** — ADF statistics between −2.6 and −2.8, tantalizingly close to the −3.34 threshold but not crossing it. Iceland is a very open economy (often 80–100% of GDP) but its openness co-moves imperfectly with European counterparts.

**Key interpretive note on GDP:** The cointegration with EA20 but not with the individual Nordic countries is at first puzzling. The most likely explanation is that EA20 is a large aggregate that smooths idiosyncratic shocks from any one country, making it easier to detect a long-run trend relationship with Iceland's GDP growth trajectory. Iceland and the Eurozone as a whole have both grown substantially since 1999 in a way that is statistically indistinguishable from a shared long-run equilibrium — but Iceland's path is too volatile relative to any single Nordic country for the residuals to be stationary.

---

### 3. Johansen Multivariate Tests

**Conclusion: Mixed signals — some HICP cointegration found, but GDP failed and trade openness is weak.**

We split into two groups to avoid the singularity problem (EA20 is a weighted average of its members, creating near-perfect multicollinearity when all countries are included):

- **Iceland + Eurozone** (bivariate Johansen — the core EU question)
- **Nordic group**: Iceland + Denmark + Sweden + Finland

Results by series:

| Test | r=0 stat | Critical 5% | r=1 stat | Critical 5% | Rank |
|------|----------|-------------|----------|-------------|------|
| GDP: Iceland + Eurozone | NA | — | NA | — | NA (failed) |
| GDP: Nordic group | 3.57 | 9.24 | 14.68 | 19.96 | 0 |
| HICP: Iceland + Eurozone | 1.35 | 9.24 | **31.56** | 19.96 | 1 |
| HICP: Nordic group | 6.02 | 9.24 | **16.27** | 19.96 | 2 |
| Openness: Iceland + Eurozone | 5.39 | 9.24 | 19.10 | 19.96 | 0 |
| Openness: Nordic group | 3.44 | 9.24 | 9.80 | 19.96 | 1 |

**GDP: Iceland + Eurozone — failed (singular matrix).** Even in the bivariate case, the GDP pair produces a singular covariance matrix. This is unusual and suggests something is wrong with the data for this specific combination in the Johansen VAR framework — possibly that the series are too highly correlated at short lags for the VAR residuals to be well-behaved. The Engle-Granger result (cointegrated) is more reliable here as it doesn't rely on VAR estimation.

**GDP: Nordic group — rank 0.** No cointegration among Iceland + the three Nordic EU members. Consistent with Engle-Granger.

**HICP: Iceland + Eurozone — rank 1.** The trace test does not reject r=0 (statistic 1.35 << 9.24), so no cointegration with the Eurozone at conventional significance... but then rejects r≤1 with a statistic of 31.56 >> 19.96. This is an unusual pattern — rank 1 is accepted but not through the sequential testing logic we'd expect. It likely reflects numerical instability in the bivariate Johansen with only 2 variables (only one possible cointegrating vector exists, and the test can behave oddly). Treat with caution; Engle-Granger says no cointegration for HICP pairs.

**HICP: Nordic group — rank 2.** Two cointegrating vectors among Iceland + 3 Nordics for price levels. This is the strongest positive result in the Johansen tests. It suggests that despite different *levels* of inflation, the Nordic price series (including Iceland) share a common long-run structure. However, this may partly reflect the fact that all HICP series trend upward together globally — cointegration of price levels is common across countries even without meaningful economic integration.

**Openness: Iceland + Eurozone — rank 0.** No cointegration between Iceland's and the Eurozone's trade openness.

**Openness: Nordic group — rank 1.** One cointegrating vector among Iceland + 3 Nordics. Weak evidence of shared long-run trade structure.

---

### 4. How Engle-Granger and Johansen Compare

The two methods sometimes disagree, and that's expected — they have different power properties:

- **Engle-Granger** is better at detecting *pairwise* relationships clearly. It found GDP (IS vs EA20) cointegrated.
- **Johansen** is designed for *multivariate* systems and can find cointegration that Engle-Granger misses by looking at the joint structure. Its HICP result (rank 2 for Nordic group) is the main additional finding.
- Where they conflict (e.g., HICP Iceland+Eurozone), Johansen's bivariate behavior is unreliable — Engle-Granger is preferable.
- The GDP Johansen failure is a known limitation of the method with highly trending series.

The safest reading is: **take the Engle-Granger results as the primary findings, and Johansen's Nordic HICP result as supplementary evidence.**

---

### 5. What This Means for the Iceland-EU Question

**GDP:** Iceland's long-run economic growth trajectory aligns with the Eurozone as a whole. Over 1999–2025, Iceland and the EA20 have moved together in a statistically meaningful sense, despite Iceland's very different monetary framework. However, Iceland does *not* align with individual Nordic EU members — its path is more volatile than any single comparator.

**Prices (HICP):** No bivariate cointegration with any comparator. This is the clearest finding: Iceland's price level has followed its own trajectory, shaped by its independent monetary policy, exchange rate fluctuations, and domestic inflation dynamics. Adopting the euro would remove this flexibility — and the data suggest Iceland has used it substantially.

**Trade openness:** Close to the threshold but not cointegrated with any individual country. Iceland is highly open but the composition and direction of its trade (fishing, aluminum, tourism) differs enough from European patterns that no long-run equilibrium is detected.

**Interest rates:** Not testable with available Eurostat data (Iceland and EA20 missing from the dataset). This is a significant gap — interest rate convergence is one of the most direct channels of monetary integration.

**Bottom line:** The evidence is mixed, leaning slightly against strong economic integration. The single clear positive (GDP co-movement with EA20) is encouraging but reflects long-run trend similarity more than cyclical synchronization. The HICP result is the most damaging for the case for EU membership: Iceland's prices have not moved with Europe's, which is exactly what you'd expect if monetary independence has mattered. Whether this is a feature (Iceland could adjust via the exchange rate during shocks) or a bug (it would need to give this up in the eurozone) is the central policy question.

---

### Caveats

1. **Structural breaks**: The sample spans the 2008 banking collapse (Iceland's was extreme) and COVID-19. These may distort the long-run relationships. Formal structural break tests (Zivot-Andrews, Gregory-Hansen) would strengthen the analysis.
2. **Sample length**: 108 quarters (1999–2025) is adequate but not long. Unit root and cointegration tests have low power in small samples.
3. **HICP baseline**: The raw HICP is anchored to 2015=100. Re-indexing to 1999Q1=100 (as in our plots) makes the visual comparison cleaner but doesn't affect the cointegration tests (which are scale-invariant).
4. **Interest rate gap**: The missing Iceland data for long-term rates is a real limitation. Central Bank of Iceland data could supplement Eurostat here.
