# ggplot2 Plotting Guide

*Design rules for clean, publication-ready charts in R. Apply these over ggplot2 defaults — always.* Inspired by Saloni's guide and other sources.

---

## Before You Start — Ask First

Before writing any code, ask the user:

1. **What is the primary question** this chart should answer?
2. **Absolute or relative?** Should values be counts/totals, or shares/rates/per-capita?
3. **Highlight or filter?** Are there specific categories, entities, or time periods to emphasize or exclude?
4. **Many categories or series?** If > 5 series or > 15 categories: ask whether to filter to top N, facet, or group small categories into "Other".

Do not default to a chart type before getting answers to at least #1 and #2.

---

## Core Principles

1. **Remove everything that doesn't add information** — no axis titles, no legend titles, no decorative gridlines
2. **Direct labels vs legend** — use direct labels for line charts with few series (≤8) whenever possible, rather than a legend
3. **Format all numbers** — never show raw axis numbers without commas, units, or scale
4. **Prefer simple chart types** — only reach for complex types (Sankey, bump, treemap) when they add clear value

---

## Chart Type Selection

**Do not default to bars.** Use the decision table below first.

| Data situation | Default chart | Bar chart only if... |
|---|---|---|
| Values over time | `geom_line()` | explicitly asked for |
| Single ranked variable | Lollipop (`geom_segment` + `geom_point`) | ≤ 6 categories |
| Distribution across groups | `geom_density_ridges()` or violin | never |
| Before / after (two time points) | Slope chart | never |
| Part-of-whole / shares | Stacked area or waffle | ≤ 3 segments, totals matter |
| Relationship between two variables | Scatter | — |
| Geographic data | Map | — |
| Counts by category | Lollipop first — ask the user | ask before deciding |

**When uncertain about chart type, ask the user** — describe two or three options in plain language, not code.

**Maps are strongly preferred** when data is in geographical units (countries, states) that can be merged using packages like `rnaturalearth`.

### Lollipop Charts (preferred over bars for ranking)

```r
df |>
  mutate(category = fct_reorder(category, value)) |>
  ggplot(aes(x = value, y = category)) +
  geom_segment(aes(x = 0, xend = value, yend = category),
               color = "grey70", linewidth = 0.6) +
  geom_point(color = "#0072B2", size = 3)
```

### Slope Charts (before / after two time points)

```r
df |>
  filter(year %in% c(2010, 2023)) |>
  ggplot(aes(x = factor(year), y = value, group = country)) +
  geom_line(color = "grey70", linewidth = 0.7) +
  geom_point(size = 2) +
  geom_text_repel(data = \(d) filter(d, year == 2023),
                  aes(label = country), hjust = 0, direction = "y",
                  nudge_x = 0.15, segment.size = 0)
```

### Dot Plots / Cleveland Dot Plots (comparing groups on the same measure)

```r
ggplot(df, aes(x = value, y = fct_reorder(category, value))) +
  geom_point(aes(color = group), size = 3) +
  scale_color_manual(values = okabe_ito, name = NULL)
```

### Never Use
- **Pie charts** — use an ordered horizontal lollipop or bar instead
- **3D charts** — use a 2D equivalent
- **Dual y-axes** — use `facet_wrap()` or separate plots instead
- **Stacked bars with > 3 segments or subtle differences** — use grouped lines or `facet_wrap()` instead

---

## Theme & Appearance

- **Always use `ggthemes::theme_clean()`** as the base theme, then layer `theme(...)` on top
- **Theme ordering is critical:** `theme_clean() + theme(...)` — never the reverse, or your overrides will be silently discarded
- **Never use the default ggplot2 grey background**
- **Default font:** `base_family = "sans"` or other sans fonts. Do not use `theme_ipsum()` or `hrbrthemes` unless the font is confirmed installed

```r
theme_clean(base_size = 13, base_family = "sans") +
theme(
  axis.title.x = element_blank(),
  axis.title.y = element_blank(),
  panel.border = element_blank(),
  legend.background = element_blank(),
  legend.box.background = element_blank()
)
```

### Font hierarchy

| Element | Style | Size |
|---|---|---|
| Title | Bold | base + 4pt |
| Subtitle | Regular | base |
| Axis tick labels | Regular | base − 1pt |
| Caption | Regular, grey50 | base − 3pt |

Minimum `base_size = 12` for screen; 13–14 for presentations. Never shrink tick label fonts below `rel(0.7)`.

---

## Titles & Labels

### Title
- **Keep under ~80 characters** — overflow is silently cut off in PNG output; wrap with `\n` if needed
- **Never use raw variable names** — translate to human-readable form (e.g. `gdp_per_capita_usd_20_v2` → "GDP per capita")
- Do not narrate the chart's encoding (e.g. "X highlighted")

```r
# Bad — overflows at width = 10
title = "Average annual conflict fatalities by country across all focus countries 2000–2020"

# Good — shortened
title = "Average annual conflict fatalities by country, 2000–2020"

# Good — manual line break
title = "Average annual conflict fatalities by country\nacross focus countries, 2000–2020"
```

### Subtitle
- Units, date range, and key caveats only. Plain language — write "each panel uses its own vertical scale" not "free_y"; write "log scale" not "log1p". Do not narrate the chart's encoding.

### Caption
- Include `labs(caption = "Source: ...")` with a real, human-readable source name
- **Never invent a source**

### Category and axis label names
- **Shorten long labels in the data before plotting** — never rotate them to fit. If the name has no obvious shorter version, ask the user.
- **Same category, different spelling or form** (e.g. OIL vs oil, "Montgomery Co." vs "Montgomery County"): **ask the user** before normalizing — do not silently collapse categories. Splits produce duplicate bars, empty bars, or wrong legend mapping.
- Prefer Title Case or Sentence case; avoid ALL CAPS

```r
# Good — shorten before plotting
df <- df |> mutate(
  country = case_when(
    country == "United States of America"           ~ "USA",
    country == "Democratic Republic of the Congo"   ~ "DRC",
    country == "United Kingdom of Great Britain..." ~ "UK",
    .default = country
  )
)
```

---

## Axes & Scales

- **Remove axis titles** on every chart — convey what the axis shows via the title or subtitle:
  ```r
  # Good - remove axis titles
  theme(axis.title.x = element_blank(), axis.title.y = element_blank())
  ```
- **Never rotate axis text** — `element_text(angle = 45)` is always wrong; use `coord_flip()` or shorten labels in the data instead
- **Time on the x-axis:** show as character or date, never as decimals (e.g. "2020" not 2020.0). Use `scale_x_date(date_labels = "%Y")` or `scale_x_continuous(breaks = 2018:2025)` for integer years; for month/year use `date_labels = "%b %Y"`
- **Bar chart y-axis must start at 0** — never truncate the baseline
- **Always format axis numbers** — never display raw values like `1000000`:
  ```r
  scale_y_continuous(labels = scales::comma)                                                    # 1,000,000
  scale_y_continuous(labels = scales::label_number(scale_cut = scales::cut_short_scale()))      # 1M, 3.4B
  scale_y_continuous(labels = scales::percent)                                                  # 42%
  scale_y_continuous(labels = scales::label_dollar())                                           # $1.2M
  scale_x_date(date_labels = "%b %Y")                                                          # Jan 2020
  ```
  - **Never use the deprecated `scales::label_number_si()`** — replace with `label_number(scale_cut = cut_short_scale())`
- **Variables with very different scales**: use `facet_wrap()` or separate plots — never a dual y-axis
- **Heavily right-skewed data**: consider a log scale; if used, say so plainly in the subtitle
- **Factor order**: default alphabetical is usually wrong. Use `fct_reorder(category, value)` for ranked data; `fct_relevel()` for ordinal or natural order (Mon→Sun, Jan→Dec). For time (day of week, month), natural order usually beats ordering by value.

```r
df$size    <- fct_relevel(df$size, "Small", "Medium", "Large")  # ordinal
df$month   <- fct_relevel(df$month, month.abb)                  # Jan→Dec, not by value
df$country <- fct_reorder(df$country, df$value)                 # ranked
```

---

## Legends & Direct Labels

- **Suppress legend titles** with `name = NULL` on every `scale_*()` call:
  ```r
  scale_fill_manual(name = NULL, values = pal)
  scale_color_viridis_c(name = NULL)
  ```
- **Line charts with around ≤ 8 series**: use direct end-of-line labels instead of a legend. Label color must match the series color — do not use one color for all labels when series have distinct colors.
- Place at each series' last available x-value — not the global max if a series ends early
- Use `geom_text_repel()` with `segment.size = 0`, `hjust = 0`, `direction = "y"`
  - `nudge_x` is in data units — recalibrate per chart, never copy-paste from another
  - Expand right margin by ≥ 0.22 to prevent clipping
  ```r
  geom_text_repel(
    data         = \(d) slice_max(d, year, n = 1, by = country),
    aes(label    = country),
    nudge_x      = 1.5,
    direction    = "y",
    segment.size = 0,
    hjust        = 0,
    size         = 3.5
  ) +
  scale_x_continuous(expand = expansion(mult = c(0.02, 0.25))) +
  theme(legend.position = "none")
  ```
- **Stacked area charts**: replace the legend with right-side labels at the midpoint of each final band
- **Maps and scatter plots**: keep the legend, suppress the title (`name = NULL`), position at `"bottom"`
- **Legends with many items** (15+): wrap into columns with `guide_legend(ncol = 4, byrow = TRUE)`

---

## Color

- **Qualitative (nominal) data**: use the **Okabe-Ito palette** by default — colorblind-safe, up to 8 groups:
  ```r
  okabe_ito <- c("#E69F00", "#56B4E9", "#009E73", "#F0E442",
                 "#0072B2", "#D55E00", "#CC79A7", "#000000")
  scale_color_manual(values = okabe_ito, name = NULL)
  scale_fill_manual(values = okabe_ito, name = NULL)
  ```
- **Sequential (low → high magnitude)**: `scale_fill_distiller(palette = "Blues", direction = 1, name = NULL)`
- **Diverging (above/below a midpoint)**: `scale_fill_distiller(palette = "RdBu", name = NULL)` — midpoint should map to white or light grey
- **Continuous**: `scale_fill_viridis_c(name = NULL)`
- **Focus + context**: one highlight color, all other series in grey:
  ```r
  df <- df |> mutate(highlight = ifelse(country == "Nigeria", "Nigeria", "Other"))
  scale_color_manual(values = c("Nigeria" = "#D55E00", "Other" = "grey80"), guide = "none")
  ```
- Never use the same color for two different nominal categories
- Match color to concept: loss/negative = red, gain/positive = green; never invert
- **Single-color bars where all bars share one uniform color communicate nothing about the data** — always encode a meaningful variable in the fill
- **Multiple charts sharing categories**: define a named color vector once and reuse:
  ```r
  region_colors <- c("Africa" = "#0072B2", "Asia" = "#D55E00", "Europe" = "#009E73")
  scale_fill_manual(values = region_colors, name = NULL)
  ```
- **Redundant encoding for accessibility** — map both color and shape/linetype:
  ```r
  aes(color = group, linetype = group)  # lines
  aes(color = group, shape = group)     # points
  ```

---

## Chart-Specific Rules

### Bar Charts

Use `geom_col()` on pre-aggregated data — never `geom_bar()` on it. Before using bars, consider whether a lollipop or dot plot would be cleaner.

- Use `coord_flip()` when labels are long — never rotate text
- Order bars: `fct_reorder(category, value)` for magnitude; `fct_relevel()` for natural order
- Use `width = 0.7` in `geom_col()`
- **Stacked bars**: only when ≤ 3 segments and the total matters. For subtle differences between groups, **ask the user** whether they prefer grouped bars, faceted lines, or shares — do not decide autonomously.
- For many categories (> 15): filter to top N; **ask the user** how to handle the rest
- Scale chart height with category count: `height = max(6, n_distinct(df$category) * 0.28)`

### Line Charts

- Use solid lines in different colors in most cases. Different line types fit specific cases (e.g. subcategories within a variable like countries × left/right)
- Omit `geom_point()` on dense series (≥ 10 observations); add points on sparse series (< 8) or irregular intervals to make gaps visible
- Use `linewidth = 0.9` for primary series; `linewidth = 0.4–0.6` for grey context lines
- **Sawtooth / jagged line** signals multiple rows per x — aggregate before plotting:
  ```r
  df |> summarise(value = mean(value, na.rm = TRUE), .by = c(year, category))
  ```

### Scatter Plots

- Add `geom_smooth()` to show the trend; state the method and interval in the subtitle (e.g. "LOESS smooth, 95% CI")
- Use `coord_fixed()` only when x and y are on the same scale and a 45° reference line is meaningful — not as a default
- For > ~500 overlapping points: use `geom_hex()` or `geom_bin2d()`, or reduce `alpha`

### Stacked Area Charts

- Fill variable must be a **fixed set of categories** with exactly one row per (x, category) — use 0 for missing combinations, not NA
- Do not use when the category set changes over time — use a fixed set or switch to a line chart
- Labels at the midpoint of each final band on the right side
- Stack order follows the fill variable's factor level order — set levels explicitly before plotting

### Histograms & Distributions

- Prefer `ggridges::geom_density_ridges()` for distributions across multiple groups (≤ 8 groups), or use faceted plots.
- For a single distribution, add a density overlay:
  ```r
  geom_histogram(aes(y = after_stat(density)), bins = 30) +
  geom_density(color = "#0072B2", linewidth = 0.8)
  ```

### Data prep gotchas

- **`slice_sample(n = ...)`** — `n` must be a constant. Compute it first (`n_samp <- min(8000L, nrow(df))`) then `slice_sample(df, n = n_samp)`; do not use `n = min(8000, n())` inside a pipe.

---

## Layout & Facets

- **Too many overlapping lines**: use faint grey context lines (`linewidth = 0.4`) with a few highlighted series (`linewidth = 0.9`) and right-margin labels, or switch to `facet_wrap()`
- **Facet y-axis scales**: keep identical across panels by default; only use `scales = "free_y"` when within-panel variation is the point — describe it in plain language in the subtitle
- **Facet strip labels**: for long names use `labeller = label_wrap_gen(width = 20)`; to show the variable name use `labeller = label_both`
- **Faceted bar charts**: prefer `coord_flip()` so categories move to the y-axis

```r
facet_wrap(~ country, ncol = 3, labeller = label_wrap_gen(width = 20))
```

---

## Annotations

- **Reference lines and bands** are among the most useful annotations — add when the data has a natural average, threshold, or notable time period:
  ```r
  geom_hline(yintercept = mean(df$value, na.rm = TRUE),
             linetype = "dashed", color = "grey40", linewidth = 0.4)

  geom_vline(xintercept = 2008, linetype = "dotted", color = "grey40", linewidth = 0.4)

  annotate("rect",
    xmin = as.Date("2020-03-01"), xmax = as.Date("2021-06-01"),
    ymin = -Inf, ymax = Inf,
    fill = "grey85", alpha = 0.4)
  ```
- **Always label reference elements** — a dashed line with no label is ambiguous
- **Layer reference elements before the main geom** so they sit behind the data
- **Do not annotate outliers or spikes automatically** — flag them to the user first and ask whether to label them

---

## Maps

- **Base map first:** draw geography as context — `fill = "grey88"` boundaries, then data on top. Bare lat/lon points with no base are hard to read. For sparse point data (events), overlay points or bubbles; for dense counts use hex/bin or choropleth.
- Use `theme_void()` — axes and grid add no information. No box around plot or legend.
- Always use `coord_sf()` for sf data.
- **Two-layer pattern**: base `fill = "grey88"`, then data layer for non-NA only; set `na.value = "grey80"` so missing reads as "no data", not white.
- **Right-skewed fill** (counts): if the variable is suspected to be right-skewed, ask the user and consider `trans = "log1p"` with back-transformed labels: `labels = \(x) scales::comma(round(expm1(x)))`. A map that is mostly one colour is miscalibrated.
- **Polygon borders:** thin white/grey (`linewidth = 0.15–0.2`) for admin maps; `color = NA` for fine grids so borders don't dominate.
- Legend at bottom, horizontal: `legend.position = "bottom"`, `legend.key.width = unit(2, "cm")`, `legend.key.height = unit(0.3, "cm")`.

---

## Export

- **Always include `ggsave()`** with `bg = "white"` and `dpi = 300`:
  ```r
  ggsave("output.png", plot = last_plot(), width = 10, height = 6, dpi = 300, bg = "white")
  ```
- **Use `linewidth =`** not `size =` for lines (ggplot2 ≥ 3.4.0)
- **Aspect ratio defaults**: 3:2 (width:height) for time series; let geography dictate for maps via `coord_sf()`; use `coord_fixed()` for scatter plots only when x and y are on the same scale

---

## Gold Standard Template

```r
library(ggplot2)
library(scales)
library(ggrepel)
library(dplyr)

# Context lines first (grey), then highlight on top (color)
ggplot(df, aes(x = year, y = value, group = country)) +
  geom_line(
    data      = \(d) filter(d, country != "Nigeria"),
    color     = "grey85", linewidth = 0.5
  ) +
  geom_line(
    data      = \(d) filter(d, country == "Nigeria"),
    color     = "#D55E00", linewidth = 0.95
  ) +
  geom_text_repel(
    data         = \(d) slice_max(d, year, n = 1, by = country),
    aes(label    = country),
    nudge_x      = 1.5,  # in data units; recalibrate per chart
    direction    = "y",
    segment.size = 0,
    hjust        = 0,
    size         = 3.5
  ) +
  scale_x_continuous(expand = expansion(mult = c(0.02, 0.25))) +
  scale_y_continuous(labels = scales::comma) +
  theme_clean(base_size = 13, base_family = "sans") +
  theme(
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    legend.position = "none"
  ) +
  labs(
    title    = "Chart title, under 80 characters",
    subtitle = "Units, date range, and key caveats only",
    caption  = "Source: Data source name"
  )

ggsave("output.png", plot = last_plot(), width = 10, height = 6, dpi = 300, bg = "white")
```
