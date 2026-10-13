# ggplot2 Plotting Guide for AI Agents

An opinionated house style for clear charts in R. Use it to make visual and
analytical decisions; consult current package documentation for syntax.

This guide began as a distillation of [Saloni Dattani's guide to data
visualization](https://www.scientificdiscovery.dev/p/salonis-guide-to-data-visualization)
and developed through repeated review of AI-generated ggplot2 charts. It is a
working house style, not a comprehensive summary of visualization research.

## Decision order

When rules compete, use this order:

1. Represent the data truthfully.
2. Make the chart's main question easy to answer.
3. Preserve legibility and accessibility in the intended output.
4. Apply this house style consistently.

Treat the rules below as strong defaults. Depart from them when the data,
audience, or requested format gives a concrete reason, and mention material
departures to the user.

## Collaboration

Work iteratively with the user. For an open-ended request, briefly offer the
main analytical stories or chart directions and ask which matters before
plotting. Also ask when the quantity, denominator, aggregation, weighting,
comparison, audience, or framing cannot be inferred safely. After the first
render, explain the main choices briefly and ask for feedback before producing
a larger suite or materially different version. Do not interrupt for routine
cosmetic decisions.

## Before plotting

Inspect the data and infer reasonable defaults. Ask the user only when an
unresolved choice would materially change the meaning of the chart, such as:

- the primary comparison is unclear;
- counts versus shares, rates, or per-capita values would tell different stories;
- aggregation requires a substantive weighting choice;
- filtering, grouping into "Other", or normalizing categories could change the result;
- uncertainty intervals or sample sizes may materially affect interpretation but
  cannot be established from the available data;
- the source, unit, or meaning of a variable cannot be established.

## Analytical choices

Choose the quantity before the chart. Decide whether the question concerns total
volume, intensity, frequency, rate, share, or change. Raw counts describe total
burden; comparisons of intensity may require a denominator such as time,
population, area, exposure, or reporting units.

Check whether groups or observations have unequal exposure. Normalize when those
differences are not part of the question.

A caption should disclose unavoidable limitations. It is not a substitute for
choosing a better measure when the necessary information is available.

Ensure titles, legends, annotations, and summaries describe the same
aggregation. Do not mix totals, rates, and averages without making the
distinction explicit.

## Core style

- Remove elements that do not add information.
- Prefer comparisons by position over comparisons that depend only on color.
- Remove axis titles when the title, subtitle, or surrounding context identifies
  both measures unambiguously. Add one back if omission would make the chart
  unclear when viewed on its own.
- Never rotate axis text. Shorten or wrap labels, use horizontal bars, facet, or
  choose a different layout.
- Translate raw variable names into concise human-readable labels.
- Format numbers for their meaning and scale; never show values such as
  `1000000` when `1,000,000` or `1M` is clearer.
- Prefer direct labels to a legend when a small number of series can be labeled
  without collisions.
- Use a restrained sans-serif type hierarchy.
- Prefer simple chart types unless a more complex form makes the comparison
  materially easier.

## Choose the chart from the question

| Analytical question | Guidance |
|---|---|
| Change over time | Line chart |
| Ranked values | Lollipop, dot plot, or horizontal bars |
| Distribution | No universal default: choose based on whether the question concerns range, outliers, modality, density, or group comparison |
| Two time points | Slope chart or paired dot plot |
| Part-to-whole | Stacked bar/area for a few stable categories; otherwise consider shares as lines or facets |
| Relationship between two variables | Scatter plot |
| Values by geographic unit | Map when spatial pattern matters; ranked or faceted chart when comparison matters |

Avoid pie charts and 3D charts. Never use dual y-axes: prefer vertically aligned
facets with a shared x-axis and separate y-scales, or use separate plots. Avoid
stacked displays when many segments or subtle differences make comparison
difficult. Use heatmaps for dense matrices or when broad patterns are the main
question; prefer lines or direct comparisons for a small number of time series.

## Theme and typography

Use `ggthemes::theme_clean()` as the default base when `ggthemes` is available,
then apply project-specific overrides afterward. Fall back to a minimal ggplot2
theme rather than adding a dependency solely for the theme.

## Titles, labels, and sources

- Ask whether the user wants a technically precise title or a more meaningful,
  editorial title when that choice affects the tone. Either must remain
  defensible from the displayed measure and uncertainty.
- Use the subtitle for units, dates, transformations, and important caveats.
- Keep titles concise; wrap deliberately when needed.
- Shorten or wrap long category labels instead of rotating them.
- Do not silently merge differently spelled categories. Normalize them only when
  they are known to represent the same thing.
- Use human-readable language throughout, including subtitles and notes; do not
  expose raw variable names unless the intended audience needs them.
- Include a human-readable source when it is known. Never invent one.
- Do not narrate obvious encodings such as "X highlighted in red."

## Axes and scales

- Bar charts must start at zero.
- Show years as integers and dates with an appropriate date scale.
- Use natural order for ordinal categories and time units; use magnitude order
  for ranked comparisons.
- Use facets or separate plots for variables on incompatible scales.
- Consider a log scale for strongly right-skewed values and disclose it plainly.
- Preserve missing-data gaps by default. Do not interpolate or replace missing
  values with zero without substantive justification.

Common number formats:

```r
scale_y_continuous(labels = scales::label_comma())
scale_y_continuous(
  labels = scales::label_number(scale_cut = scales::cut_short_scale())
)

# Proportions stored as 0–1
scale_y_continuous(labels = scales::label_percent(accuracy = 1))

# Percentage points stored as 0–100
scale_y_continuous(
  labels = scales::label_number(accuracy = 1, suffix = "%")
)
```

## Legends and direct labels

- Suppress legend titles when the categories are self-explanatory.
- Direct-label a small number of lines at each series' final observed x-value.
- Match label color to series color.
- Reserve space for labels and disable panel clipping when labels extend beyond
  the plotting panel.
- Keep legends for maps, dense scatter plots, or displays where direct labels
  would collide.

Choose nudges and margins from the chart's actual range and label lengths; do
not copy fixed values blindly.

## Color

- Use color to encode meaning or establish focus, not merely to decorate.
- Use the Okabe–Ito palette as the qualitative default. On white backgrounds,
  avoid yellow for thin marks.
- Do not default to `scale_*_viridis_*()`. Viridis is useful for ordered
  continuous values, especially when perceptual uniformity matters, but it often
  adds an unnecessary multi-hue treatment or fits the subject poorly. Choose a
  sequential or diverging scale that matches the variable and the chart's purpose.
- Use one highlight color and grey context when one series is the focus.
- Assign stable, named colors when categories recur across charts.
- Never reuse one color for different nominal categories in the same figure.
- Use red for loss or negative outcomes and green for gain or positive outcomes;
  do not invert that convention.
- Because red–green differences may be inaccessible, also distinguish important
  outcomes through labels, position, shape, arrows, or line type.
- For diverging data, use an explicit, substantively meaningful midpoint.

## Chart-specific guidance

### Bars, dots, and lollipops

- Use `geom_col()` for pre-aggregated values.
- Prefer horizontal layouts when category labels are long.
- Order by magnitude unless the categories have a natural order.
- Use a single restrained color when color does not encode another variable;
  highlight selectively when the analytical question calls for it.
- Avoid stacked bars with many segments or when individual segment comparisons
  matter more than totals.

### Lines

- Use points for sparse or irregular observations; omit them on dense series.
- Aggregate unintended duplicate rows per x/group before drawing lines.
- Let missing values break the line unless interpolation is substantively valid.
- Use faint context lines and emphasize only the series central to the question.

### Scatter plots

- Add a fitted trend only when estimating a relationship is part of the question.
- State the method and uncertainty interval when a fit is shown.
- Use transparency, hex bins, or 2D bins when overplotting obscures density.
- Use a fixed aspect ratio only when equal x/y units or a 45° reference line has
  substantive meaning.

### Distributions

- There is no universal default. Choose the form from what the viewer needs to
  compare: observations, range, quartiles, outliers, modality, density, or
  differences between groups.
- Histograms expose counts and binning; density and violin plots emphasize shape;
  box plots emphasize robust summaries; ridgelines and facets support repeated
  group comparisons. Use these properties to decide rather than applying a fixed
  hierarchy.
- Do not obscure small samples behind smooth density estimates.

### Facets

- Keep scales common when cross-panel magnitudes matter.
- Use free scales only when within-panel variation is the intended comparison,
  and disclose that choice.
- Wrap long facet labels.

## Annotations

- Put reference bands and lines behind the data and label what they mean.
- Add annotations that help answer the main question.
- Do not automatically explain every outlier or spike; first check whether it is
  a data-quality issue, expected variation, or a substantively important event.
- Show material uncertainty, but keep it visually subordinate to the comparison
  unless uncertainty is itself the subject. Do not derive uncertainty for a
  difference or change without the information needed to do so.

## Maps

- Use a map when location or spatial pattern is part of the question, not merely
  because the data contains country or region names.
- Use `coord_sf()` for `sf` data and `theme_void()` when axes add no information.
- Draw geographic context first, then the observed data.
- Give missing areas an explicit neutral appearance so they do not resemble zero.
- Keep polygon borders thin; omit borders for very fine grids.
- For strongly skewed values, consider a justified transformation such as log,
  log1p, or pseudo-log. Keep legend labels interpretable in the original units
  and disclose the transformation.

## Data integrity

Before rendering, verify:

- the unit of observation;
- aggregation and weighting choices;
- duplicate keys at the plotting level;
- the distinction between zero, missing, and structurally absent values;
- whether percentages are stored as proportions or percentage points;
- whether estimates need uncertainty intervals or sample sizes to be interpreted;
- whether filtering or top-N selection changes the intended claim;
- whether labels and sources accurately describe the constructed data.

Do not solve an analytical ambiguity with a visual styling choice.

## Export and visual check

Export with explicit dimensions and inspect the rendered result.

Check for clipped titles or labels, collisions, unreadable text, weak contrast,
misleading scales, excessive empty space, and legends that could be replaced by
clearer labels. Revise the chart after inspection rather than treating successful
execution as completion.

Align titles, plotting panels, legends, and captions to a coherent visual grid.
Keep captions brief, wrap them to the plotting width, and align their left and
right extent with the plot rather than leaving a detached block. Across a suite,
keep only charts that answer materially different questions.
