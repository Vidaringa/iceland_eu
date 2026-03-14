# =============================================================================
# Cointegration Analysis: Does Iceland Share Long-Run Equilibria with the EU?
# =============================================================================
# Iceland vs. Eurozone aggregate + Nordic EU members (Denmark, Sweden, Finland)
# Quarterly data, euro era (1999Q1 onwards)
# =============================================================================

library(tidyverse)
library(eurostat)
library(lubridate)
library(urca)
library(tseries)

out_dir <- "output/cointegration"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# -----------------------------------------------------------------------------
# 1. Define countries and parameters
# -----------------------------------------------------------------------------

countries <- c("IS", "DK", "SE", "FI", "EA20")
country_labels <- c(
  IS = "Iceland", DK = "Denmark", SE = "Sweden",
  FI = "Finland", EA20 = "Eurozone"
)

start_date <- "1999-01-01"

# -----------------------------------------------------------------------------
# 2. Pull data from Eurostat
# -----------------------------------------------------------------------------

cat("Pulling GDP...\n")
gdp_raw <- get_eurostat("namq_10_gdp", filters = list(
  geo     = countries,
  unit    = "CLV10_MEUR",
  na_item = "B1GQ",
  s_adj   = "SCA"
)) |>
  filter(time >= start_date) |>
  select(geo, time, gdp = values)

cat("Pulling HICP...\n")
hicp_raw <- get_eurostat("prc_hicp_midx", filters = list(
  geo    = countries,
  unit   = "I15",
  coicop = "CP00"
)) |>
  filter(time >= start_date) |>
  mutate(quarter = floor_date(time, "quarter")) |>
  group_by(geo, quarter) |>
  summarise(hicp = mean(values, na.rm = TRUE), .groups = "drop") |>
  rename(time = quarter)

cat("Pulling long-term interest rates...\n")
interest_raw <- get_eurostat("irt_lt_mcby_q", filters = list(
  geo = countries
)) |>
  filter(time >= start_date) |>
  select(geo, time, interest = values)

cat("Pulling trade data...\n")
trade_raw <- get_eurostat("namq_10_exi", filters = list(
  geo     = countries,
  unit    = "CLV10_MEUR",
  na_item = c("P6", "P7"),
  s_adj   = "SCA"
)) |>
  filter(time >= start_date) |>
  select(geo, time, na_item, values) |>
  pivot_wider(names_from = na_item, values_from = values) |>
  rename(exports = P6, imports = P7)

trade_openness <- trade_raw |>
  left_join(gdp_raw, by = c("geo", "time")) |>
  mutate(openness = (exports + imports) / gdp * 100) |>
  select(geo, time, openness)

# -----------------------------------------------------------------------------
# 3. Helper functions
# -----------------------------------------------------------------------------

run_adf <- function(x, name = "", type = "drift") {
  x_clean <- na.omit(x)
  adf <- ur.df(x_clean, type = type, selectlags = "AIC")
  tibble(
    series    = name,
    adf_stat  = adf@teststat[1, 1],
    crit_1pct = adf@cval[1, 1],
    crit_5pct = adf@cval[1, 2],
    crit_10pct = adf@cval[1, 3],
    lags      = adf@lags,
    I1 = adf@teststat[1, 1] > adf@cval[1, 2]
  )
}

run_kpss <- function(x, name = "") {
  x_clean <- na.omit(x)
  kpss <- ur.kpss(x_clean, type = "mu", use.lag = NULL)
  tibble(
    series     = name,
    kpss_stat  = as.numeric(kpss@teststat),
    crit_5pct  = kpss@cval[1, 2],
    reject_H0  = as.numeric(kpss@teststat) > kpss@cval[1, 2]
  )
}

run_engle_granger <- function(y_is, y_comp, label = "") {
  df <- tibble(is = y_is, comp = y_comp) |> drop_na()
  fit <- lm(is ~ comp, data = df)
  resid_vec <- as.numeric(residuals(fit))
  adf_obj <- ur.df(resid_vec, type = "none", selectlags = "AIC")
  adf_stat <- adf_obj@teststat[1, 1]
  tibble(
    pair       = label,
    beta       = coef(fit)[2],
    r_squared  = summary(fit)$r.squared,
    adf_resid  = adf_stat,
    eg_crit_5pct = -3.34,
    cointegrated = adf_stat < -3.34
  )
}

run_johansen <- function(data_matrix, label = "", K = 2) {
  data_clean <- na.omit(data_matrix)
  tryCatch({
    jo <- ca.jo(data_clean, type = "trace", ecdet = "const", K = K)
    tibble(
      test       = label,
      r0_stat    = jo@teststat[1],
      r0_crit5   = jo@cval[1, 2],
      r1_stat    = if (nrow(jo@cval) >= 2) jo@teststat[2] else NA_real_,
      r1_crit5   = if (nrow(jo@cval) >= 2) jo@cval[2, 2] else NA_real_,
      rank       = sum(jo@teststat > jo@cval[, 2])
    )
  }, error = function(e) {
    cat("  Johansen test failed for", label, ":", conditionMessage(e), "\n")
    tibble(
      test = label, r0_stat = NA_real_, r0_crit5 = NA_real_,
      r1_stat = NA_real_, r1_crit5 = NA_real_, rank = NA_integer_
    )
  })
}

# -----------------------------------------------------------------------------
# 4. Prepare wide-format data
# -----------------------------------------------------------------------------

prep_wide <- function(df, value_col) {
  df |>
    mutate(geo_label = country_labels[geo]) |>
    select(geo_label, time, value = {{ value_col }}) |>
    pivot_wider(names_from = geo_label, values_from = value) |>
    arrange(time)
}

gdp_wide      <- prep_wide(gdp_raw, gdp)
hicp_wide     <- prep_wide(hicp_raw, hicp)
interest_wide <- prep_wide(interest_raw, interest)
openness_wide <- prep_wide(trade_openness, openness)

# Skip series without Iceland
all_series <- list(
  GDP      = gdp_wide,
  HICP     = hicp_wide,
  Interest = interest_wide,
  Openness = openness_wide
)
all_series <- all_series[sapply(all_series, function(df) "Iceland" %in% names(df))]

skipped <- setdiff(c("GDP", "HICP", "Interest", "Openness"), names(all_series))
if (length(skipped) > 0) cat("Skipping (no Iceland data):", skipped, "\n")

# -----------------------------------------------------------------------------
# 5. Unit root tests
# -----------------------------------------------------------------------------

cat("Running unit root tests...\n")

adf_results <- bind_rows(
  map(names(all_series), function(s) {
    df <- all_series[[s]]
    map_dfr(names(df)[-1], ~run_adf(df[[.x]], paste0(s, ": ", .x)))
  })
)

adf_diff_results <- bind_rows(
  map(names(all_series), function(s) {
    df <- all_series[[s]]
    map_dfr(names(df)[-1], ~run_adf(diff(na.omit(df[[.x]])), paste0("d", s, ": ", .x)))
  })
)

kpss_results <- bind_rows(
  map(names(all_series), function(s) {
    df <- all_series[[s]]
    map_dfr(names(df)[-1], ~run_kpss(df[[.x]], paste0(s, ": ", .x)))
  })
)

# -----------------------------------------------------------------------------
# 6. Engle-Granger cointegration (bivariate: Iceland vs each comparator)
# -----------------------------------------------------------------------------

cat("Running Engle-Granger tests...\n")

comparators <- c("Eurozone", "Denmark", "Sweden", "Finland")

eg_results <- bind_rows(
  map(names(all_series), function(s) {
    df_wide <- all_series[[s]]
    available_comps <- intersect(comparators, names(df_wide))
    map_dfr(available_comps, function(comp) {
      df <- df_wide |> select(time, Iceland, all_of(comp)) |> drop_na()
      if (nrow(df) > 10) {
        run_engle_granger(df$Iceland, df[[comp]], paste0(s, ": IS vs ", comp))
      }
    })
  })
)

# -----------------------------------------------------------------------------
# 7. Johansen cointegration (two groups to avoid EA20/Nordic multicollinearity)
# -----------------------------------------------------------------------------

cat("Running Johansen tests...\n")

johansen_groups <- list(
  "Iceland + Eurozone" = c("Iceland", "Eurozone"),
  "Nordic group"       = c("Iceland", "Denmark", "Sweden", "Finland")
)

johansen_results <- bind_rows(
  map(names(all_series), function(s) {
    df <- all_series[[s]]
    map_dfr(names(johansen_groups), function(grp_name) {
      cols <- intersect(johansen_groups[[grp_name]], names(df))
      if (length(cols) < 2) return(NULL)
      mat <- df |> select(all_of(cols)) |> drop_na() |> as.matrix()
      if (nrow(mat) > 20) run_johansen(mat, paste0(s, ": ", grp_name), K = 2)
    })
  })
)

# -----------------------------------------------------------------------------
# 8. Save results to CSV
# -----------------------------------------------------------------------------

cat("Saving results...\n")

write_csv(adf_results,      file.path(out_dir, "adf_results.csv"))
write_csv(adf_diff_results, file.path(out_dir, "adf_diff_results.csv"))
write_csv(kpss_results,     file.path(out_dir, "kpss_results.csv"))
write_csv(eg_results,       file.path(out_dir, "eg_results.csv"))
write_csv(johansen_results, file.path(out_dir, "johansen_results.csv"))

# -----------------------------------------------------------------------------
# 9. Plots
# -----------------------------------------------------------------------------

theme_visbending <- theme_minimal(base_size = 13) +
  theme(
    plot.title    = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(color = "grey40", size = 11),
    plot.caption  = element_text(color = "grey50", size = 9),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

palette_is <- c(
  "Iceland"  = "#003897",
  "Denmark"  = "#C8102E",
  "Sweden"   = "#006AA7",
  "Finland"  = "#003580",
  "Eurozone" = "#FFD700"
)

# GDP — indexed to 100 at start
p_gdp <- gdp_wide |>
  pivot_longer(-time, names_to = "country", values_to = "gdp") |>
  drop_na() |>
  group_by(country) |>
  mutate(gdp_idx = gdp / first(gdp) * 100) |>
  ggplot(aes(time, gdp_idx, colour = country)) +
  geom_line(aes(linewidth = country == "Iceland")) +
  scale_linewidth_manual(values = c("TRUE" = 1.3, "FALSE" = 0.7), guide = "none") +
  scale_colour_manual(values = palette_is) +
  labs(
    title    = "Real GDP: Iceland vs EU/Nordics",
    subtitle = "Chain-linked volumes, indexed to start = 100",
    x = NULL, y = "Index", colour = NULL,
    caption  = "Source: Eurostat (namq_10_gdp)"
  ) +
  theme_visbending

# HICP — indexed to 100 at start (not raw 2015=100)
p_hicp <- hicp_wide |>
  pivot_longer(-time, names_to = "country", values_to = "hicp") |>
  drop_na() |>
  group_by(country) |>
  mutate(hicp_idx = hicp / first(hicp) * 100) |>
  ggplot(aes(time, hicp_idx, colour = country)) +
  geom_line(aes(linewidth = country == "Iceland")) +
  scale_linewidth_manual(values = c("TRUE" = 1.3, "FALSE" = 0.7), guide = "none") +
  scale_colour_manual(values = palette_is) +
  labs(
    title    = "Price Levels (HICP): Iceland vs EU/Nordics",
    subtitle = "Harmonised index, indexed to start = 100",
    x = NULL, y = "Index", colour = NULL,
    caption  = "Source: Eurostat (prc_hicp_midx)"
  ) +
  theme_visbending

# Interest rates
p_interest <- interest_wide |>
  pivot_longer(-time, names_to = "country", values_to = "rate") |>
  drop_na() |>
  ggplot(aes(time, rate, colour = country)) +
  geom_line(aes(linewidth = country == "Iceland")) +
  scale_linewidth_manual(values = c("TRUE" = 1.3, "FALSE" = 0.7), guide = "none") +
  scale_colour_manual(values = palette_is) +
  labs(
    title    = "Long-Term Interest Rates: Iceland vs EU/Nordics",
    subtitle = "10-year government bond yields (%)",
    x = NULL, y = "Yield (%)", colour = NULL,
    caption  = "Source: Eurostat (irt_lt_mcby_q)"
  ) +
  theme_visbending

# Trade openness
p_openness <- openness_wide |>
  pivot_longer(-time, names_to = "country", values_to = "openness") |>
  drop_na() |>
  ggplot(aes(time, openness, colour = country)) +
  geom_line(aes(linewidth = country == "Iceland")) +
  scale_linewidth_manual(values = c("TRUE" = 1.3, "FALSE" = 0.7), guide = "none") +
  scale_colour_manual(values = palette_is) +
  labs(
    title    = "Trade Openness: Iceland vs EU/Nordics",
    subtitle = "(Exports + Imports) / GDP × 100",
    x = NULL, y = "Trade Openness (%)", colour = NULL,
    caption  = "Source: Eurostat (namq_10_exi, namq_10_gdp)"
  ) +
  theme_visbending

# Engle-Granger summary
p_eg <- eg_results |>
  separate(pair, into = c("series", "comparator"), sep = ": IS vs ") |>
  ggplot(aes(comparator, adf_resid, fill = cointegrated)) +
  geom_col() +
  geom_hline(yintercept = -3.34, linetype = "dashed", colour = "red") +
  facet_wrap(~series, scales = "free_y") +
  scale_fill_manual(values = c("TRUE" = "#2E8B57", "FALSE" = "#CD5C5C"),
                    labels = c("TRUE" = "Cointegrated", "FALSE" = "Not cointegrated")) +
  coord_flip() +
  labs(
    title    = "Engle-Granger Cointegration: Iceland vs Comparators",
    subtitle = "ADF test statistic on regression residuals (red line = 5% critical value)",
    x = NULL, y = "ADF Statistic", fill = NULL,
    caption  = "More negative = stronger evidence of cointegration"
  ) +
  theme_visbending

# Save plots
ggsave(file.path(out_dir, "01_gdp_comparison.png"), p_gdp, width = 10, height = 6, dpi = 300)
ggsave(file.path(out_dir, "02_hicp_comparison.png"), p_hicp, width = 10, height = 6, dpi = 300)
ggsave(file.path(out_dir, "03_interest_comparison.png"), p_interest, width = 10, height = 6, dpi = 300)
ggsave(file.path(out_dir, "04_trade_openness.png"), p_openness, width = 10, height = 6, dpi = 300)
ggsave(file.path(out_dir, "05_cointegration_summary.png"), p_eg, width = 10, height = 7, dpi = 300)

cat("Done! Results saved to", out_dir, "\n")
