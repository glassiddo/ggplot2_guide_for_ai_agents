# ggplot2 Plotting Guide

*Design rules for clean, publication-ready charts in R. Apply these over ggplot2 defaults — always.* Inspired by Saloni's guide and other sources.

---

## Core Principles

1. **Remove everything that doesn't add information** — no axis titles, no legend titles, no decorative gridlines
2. **Use direct labels over legends** wherever possible
3. **Format all numbers** — never show raw axis numbers without commas, units, or scale
4. **Horizontal text only** — never rotate axis labels
5. **Prefer simple chart types** — only reach for complex types (Sankey, bump, treemap) when they add clear value

---

## Theme & Appearance

- **Always use `ggthemes::theme_clean()`** as the base theme, then layer `theme(...)` on top
- **Theme ordering is critical:** `theme_clean() + theme(...)` — never the reverse, or your overrides will be silently discarded
- **Never use the default ggplot2 grey background**
- **Default font:** `base_family = "sans"` or other sans fonts. Do not use `theme_ipsum()` or `hrbrthemes` unless the font is confirmed installed

```r
theme_clean(base_size = 13, base_family = "sans") +
theme(
  axis.title.x = element_blank(),   # always remove axis titles
  axis.title.y = element_blank()
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

```r
# Bad — overflows at width = 10
title = "Average annual conflict fatalities by country across all focus countries 2000–2020"

# Good — shortened
title = "Average annual conflict fatalities by country, 2000–2020"

# Good — manual line break
title = "Average annual conflict fatalities by country\nacross focus countries, 2000–2020"
```

### Subtitle
- Units, date range, and key caveats only
- Plain language only — write "each panel uses its own vertical scale" not "free_y"; write "log scale" not "log1p"

### Caption
- Include `labs(caption = "Source: ...")` with a real, human-readable source name
- **Never invent a source**. 

### Category and axis label names
- **Shorten long labels in the data before plotting** — never rotate them to fit. If the name has no obvious shorter version, ask the user.
- Prefer Title Case or Sentence case; avoid ALL CAPS
- Replace raw column names with human-readable equivalents throughout

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
  theme(
    axis.title.x = element_blank(),  
    axis.title.y = element_blank()
  )
  ```
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
- **Never rotate axis text** — `element_text(angle = 45)` is always wrong; use `coord_flip()` or shorten the labels in the data instead
- **Variables with very different scales**: use `facet_wrap()` or separate plots — never a dual y-axis
- **Heavily right-skewed data**: consider a log scale; if used, say so plainly in the subtitle
- **Factor order**: default alphabetical ordering is almost always wrong — use `fct_reorder(category, value)` for ranked data or `fct_relevel()` for ordinal data

```r
df$size    <- fct_relevel(df$size, "Small", "Medium", "Large")  # ordinal
df$country <- fct_reorder(df$country, df$value)                 # ranked
```

---

## Legends & Direct Labels

- **Suppress legend titles** with `name = NULL` on every `scale_*()` call:
  ```r
  scale_fill_manual(name = NULL, values = pal)   # good
  scale_color_viridis_c(name = NULL)             # good
  scale_size_continuous(name = NULL)             # good
  ```
- **Line charts with roughly ≤ 8 series**: use direct end-of-line labels instead of a legend
  - Place at each series' last available x-value — not the global max if a series ends early
  - Use `geom_text_repel()` with `segment.size = 0` (no connector lines), `hjust = 0`, `direction = "y"`
  - `nudge_x` is in data units — recalibrate per chart, never copy-paste from another
  - Expand right margin by roughly ≥ 0.22 to prevent clipping
  - Remove the legend: `theme(legend.position = "none")`
  ```r
  geom_text_repel(
    data         = \(d) slice_max(d, year, n = 1, by = country),
    aes(label    = country),
    nudge_x      = 1.5,          # in data units; ~5–10% of x range
    direction    = "y",
    segment.size = 0,            # no connector lines
    hjust        = 0,
    size         = 3.5
  ) +
  scale_x_continuous(expand = expansion(mult = c(0.02, 0.25))) +
  theme(legend.position = "none")  # direct labels replace the legend
  ```
- **Stacked area charts**: replace the legend with right-side labels at the midpoint of each final band
- **Maps and scatter plots**: keep the legend, suppress the title (`name = NULL`), position at `"bottom"`
- **Legends with many items** (15+): wrap into columns:
  ```r
  scale_fill_manual(
    name  = NULL,
    values = pal,
    guide = guide_legend(ncol = 4, byrow = TRUE)
  ) +
  theme(
    legend.position  = "bottom",
    legend.key.size  = unit(0.7, "lines"),
    legend.text      = element_text(size = rel(0.8))
  )
  ```

---

## Chart Type Rules

### Bar Charts
- Use **`geom_col()`** on pre-aggregated data — never `geom_bar()` on it
- Use **`coord_flip()`** when category labels are long — never tilt the text
- **Order bars by value**: `fct_reorder(category, value)`
- Use `width = 0.7` in `geom_col()`
- Avoid a single flat color for all bars — use a sequential fill or highlight bars of interest
- For many categories (> 15): filter to top N; remaining small categories may be grouped into "Other" only if "Other" would not become one of the largest bars
- Add direct value labels when some bars are very small or when precision matters:
  ```r
  geom_text(aes(label = scales::comma(value)), hjust = -0.15, size = 3)
  ```
- **Avoid stacked bars when one segment dominates** — use grouped bars or `facet_wrap()` instead
- Scale chart height with category count — never shrink fonts to compensate:
  ```r
  ggsave("output.png", width = 10, height = max(6, n_distinct(df$category) * 0.28), dpi = 300, bg = "white")
  ```

### Line Charts
- Omit `geom_point()` on dense series (≥ 10 observations) — the line is sufficient
- Add points on sparse series (< 8 observations) or irregular intervals to make gaps visible
- Use `linewidth = 0.9` for primary series; `linewidth = 0.4–0.6` for grey context lines
- **Sawtooth / jagged line** signals multiple rows per x value — aggregate before plotting:
  ```r
  df |> summarise(value = mean(value, na.rm = TRUE), .by = c(year, category))
  ```

### Scatter Plots
- Add `geom_smooth()` to show the trend; state the method and interval in the subtitle (e.g. "LOESS smooth, 95% CI")
- Use `coord_fixed()` so a 45° slope appears at 45°
- For > ~500 overlapping points: use `geom_hex()` or `geom_bin2d()`, or reduce `alpha`

### Stacked Area Charts
- Fill variable must be a **fixed set of categories** with exactly one row per (x, category) — use 0 for missing combinations, not NA
- Do not use stacked area when the category set changes over time (e.g. "top 5 each year") — use a fixed set or switch to a line chart
- Labels must appear on the right inside each band, positioned at the midpoint of the final stack segment
- Stack order follows the fill variable's factor level order — set levels explicitly before plotting; the `arrange()` in the label data frame must use the same order so `cumsum()` runs correctly

### Histograms & Distributions
- Add a density or frequency-polygon overlay so the shape is easier to read than bars alone:
  ```r
  geom_histogram(aes(y = after_stat(density)), bins = 30) +
  geom_density(color = "#0072B2", linewidth = 0.8)
  ```
- For distributions across many groups: prefer `ggridges::geom_density_ridges()` over overlapping density plots; limit to ≤ 6–8 groups or switch to faceted densities

### Never Use
- **Pie charts** — use an ordered horizontal bar chart instead
- **3D charts** — use a 2D equivalent
- **Dual y-axes** — use `facet_wrap()` or separate plots instead

---

## Layout & Facets

- **Too many overlapping lines**: use faint grey context lines (`linewidth = 0.4`) with a few highlighted series (`linewidth = 0.9`) and right-margin labels, or switch to `facet_wrap()`
- **Facet y-axis scales**: keep identical across panels by default; only use `scales = "free_y"` when within-panel variation is the point — and describe it in plain language in the subtitle
- **Facet strip labels**: for long names use `labeller = label_wrap_gen(width = 20)`; to show the variable name use `labeller = label_both`
- **Faceted bar charts** (many categories on x): each panel has little width, so x-axis labels crowd. Prefer `coord_flip()` so categories move to the y-axis; if you keep vertical bars, use `theme(axis.text.x = element_text(size = rel(0.75)))` for that plot only.
- **Natural pairs in facets** (e.g. Male/Female per entity): put paired panels side by side, not scattered; if one variant is negligible, consider one panel per entity with two lines instead

```r
facet_wrap(~ country, ncol = 3, labeller = label_wrap_gen(width = 20))
```

---

## Annotations

- **Reference lines and bands** are among the most useful annotations — add them when the data has a natural average, threshold, or notable time period:
  ```r
  # Mean reference line
  geom_hline(yintercept = mean(df$value, na.rm = TRUE),
             linetype = "dashed", color = "grey40", linewidth = 0.4)

  # Zero line (for charts that can go negative)
  geom_hline(yintercept = 0, color = "grey50", linewidth = 0.3)

  # Vertical marker for an event
  geom_vline(xintercept = 2008, linetype = "dotted", color = "grey40", linewidth = 0.4)

  # Shaded period band
  annotate("rect",
    xmin = as.Date("2020-03-01"), xmax = as.Date("2021-06-01"),
    ymin = -Inf, ymax = Inf,
    fill = "grey85", alpha = 0.4)
  ```
- **Always label reference elements** — a dashed line with no label is ambiguous
- **Layer reference elements before the main geom** so they sit behind the data
- **Do not annotate outliers or spikes automatically** — flag them to the user first and ask whether to label them

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
- **Diverging (above/below a midpoint)**: `scale_fill_distiller(palette = "RdBu", name = NULL)` — ensure the midpoint maps to white or light grey, not a saturated color
- **Continuous**: `scale_fill_viridis_c(name = NULL)`
- **Focus + context**: one highlight color, all other series in grey — avoid equal visual weight when the narrative has a specific focus:
  ```r
  df <- df |> mutate(highlight = ifelse(country == "Nigeria", "Nigeria", "Other"))

  scale_color_manual(values = c("Nigeria" = "#D55E00", "Other" = "grey80"), guide = "none")
  ```
- Each nominal category must have a **distinct color** — never reuse the same color for two different categories
- Match color to concept: loss/negative = red, gain/positive = green; never invert this
- For analyses with multiple charts sharing the same categories, define a **named color vector once** and reuse it across all charts:
  ```r
  region_colors <- c("Africa" = "#0072B2", "Asia" = "#D55E00", "Europe" = "#009E73")
  scale_fill_manual(values = region_colors, name = NULL)
  scale_color_manual(values = region_colors, name = NULL)
  ```
- **Redundant encoding for accessibility** — map both color and shape/linetype for scatter and line charts:
  ```r
  aes(color = group, linetype = group)  # lines
  aes(color = group, shape = group)     # points
  ```

---

## Maps

- Always use `theme_void()` for map backgrounds
- Always apply `coord_sf()` for sf-based maps; never use `coord_cartesian()` on spatial data
- **Two-layer pattern**: base layer `fill = "grey88"` for all features; data layer on top for non-NA values:
  ```r
  ggplot() +
    geom_sf(data = map_sf, fill = "grey88", color = "white", linewidth = 0.15) +
    geom_sf(data = filter(map_sf, !is.na(value)), aes(fill = value),
            color = "white", linewidth = 0.15)
  ```
- Set `na.value = "grey80"` — missing values must appear grey, not white
- **Polygon borders**: use thin borders (`linewidth = 0.15–0.2`) for admin/region maps; omit entirely (`color = NA, linewidth = 0`) for fine grids where borders would dominate
- **Right-skewed fill variables** (counts, fatalities): apply `trans = "log1p"` and back-transform tick labels; state the scale in the subtitle. A map that is mostly one color is miscalibrated.
  ```r
  scale_fill_viridis_c(
    name   = NULL,
    trans  = "log1p",
    labels = \(x) scales::comma(round(expm1(x))),
    na.value = "grey80"
  )
  ```
- **Excessive whitespace**: usually caused by a distant island stretching the bounding box — inspect with `sf::st_bbox(map_sf)` and clip with `coord_sf(xlim = ..., ylim = ..., expand = FALSE)`
- **Focus-region maps**: draw the full geography in grey first, then focus regions on top:
  ```r
  ggplot() +
    geom_sf(data = full_map_sf, fill = "grey92", color = "white", linewidth = 0.15) +
    geom_sf(data = focus_sf, aes(fill = value), color = "white", linewidth = 0.15)
  ```
- Position the legend at `"bottom"` with a horizontal colorbar to avoid overlapping the map:
  ```r
  theme(
    legend.position  = "bottom",
    legend.direction = "horizontal",
    legend.key.width = unit(2, "cm"),
    legend.key.height = unit(0.3, "cm")
  )
  ```

---

## Export

- **Always include `ggsave()`** with `bg = "white"` and `dpi = 300`:
  ```r
  ggsave("output.png", plot = last_plot(), width = 10, height = 6, dpi = 300, bg = "white")
  ```
- **Use `linewidth =`** not `size =` for lines (ggplot2 ≥ 3.4.0)
- **Aspect ratio defaults**: 3:2 (width:height) for time series; let geography dictate for maps via `coord_sf()`; use `coord_fixed()` for scatter plots so slopes are honest
- **Bar chart height**: scale with category count — never shrink fonts to compensate:
  ```r
  height = max(6, n_distinct(df$category) * 0.28)
  ```

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
    nudge_x      = 1.5,          # in data units; recalibrate per chart
    direction    = "y",
    segment.size = 0,            # no connector lines
    hjust        = 0,
    size         = 3.5
  ) +
  scale_x_continuous(expand = expansion(mult = c(0.02, 0.25))) +
  scale_y_continuous(labels = scales::comma) +
  theme_clean(base_size = 13, base_family = "sans") +   # theme_clean() always before theme()
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