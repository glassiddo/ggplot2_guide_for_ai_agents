library(ggplot2)
library(dplyr)
library(tidyr)
library(ggrepel)
library(scales)
library(ggthemes)
library(forcats)
library(haven)
library(rnaturalearth)
library(rnaturalearthdata)
library(sf)

# ── Palette & helpers ─────────────────────────────────────────────────────────
okabe_ito <- c(
  "#E69F00", "#56B4E9", "#009E73", "#F0E442",
  "#0072B2", "#D55E00", "#CC79A7", "#000000"
)

region_levels <- c(
  "East Asia & Pacific",
  "Europe & Central Asia",
  "Latin America & Caribbean",
  "Middle East & North Africa",
  "North America",
  "South Asia",
  "Sub-Saharan Africa"
)
region_colors <- setNames(okabe_ito[1:7], region_levels)

base_theme <- function() {
  theme_clean(base_size = 13, base_family = "sans") +
    theme(
      axis.title.x        = element_blank(),
      axis.title.y        = element_blank(),
      panel.border        = element_blank(),
      legend.background   = element_blank(),
      legend.box.background = element_blank()
    )
}

out <- "wdi_plots"

# ── Load data ─────────────────────────────────────────────────────────────────
wdi <- read_dta("WDI Clean.dta") |>
  mutate(regionname = factor(regionname, levels = region_levels))


# ══════════════════════════════════════════════════════════════════════════════
# Plot 1 — Urban population (%) by region over time
# ══════════════════════════════════════════════════════════════════════════════
p1 <- wdi |>
  summarise(urb_pop = mean(urb_pop, na.rm = TRUE),
            .by = c(regionname, year)) |>
  filter(!is.na(regionname), !is.na(urb_pop)) |>
  ggplot(aes(x = year, y = urb_pop, color = regionname)) +
  geom_line(linewidth = 0.9) +
  geom_text_repel(
    data         = \(d) slice_max(d, year, n = 1, by = regionname),
    aes(label    = regionname),
    nudge_x      = 2,
    direction    = "y",
    segment.size = 0.3,
    hjust        = 0,
    size         = 3.2,
    show.legend  = FALSE
  ) +
  scale_x_continuous(breaks = seq(1970, 2025, 10),
                     expand = expansion(mult = c(0.02, 0.30))) +
  scale_y_continuous(labels = label_number(suffix = "%")) +
  scale_color_manual(values = region_colors, name = NULL) +
  base_theme() +
  theme(legend.position = "none") +
  labs(
    title    = "Urban population by world region, 1970–2024",
    subtitle = "Average share of population living in urban areas per region",
    caption  = "Source: World Bank World Development Indicators"
  )

ggsave(file.path(out, "wdi_01_urb_pop_by_region.png"),
       p1, width = 11, height = 6, dpi = 300, bg = "white")


# ══════════════════════════════════════════════════════════════════════════════
# Plot 2a — Employment share in agriculture by region over time
# ══════════════════════════════════════════════════════════════════════════════
p2a <- wdi |>
  summarise(empl_ag = mean(EmplShareAg, na.rm = TRUE),
            .by = c(regionname, year)) |>
  filter(!is.na(regionname), !is.na(empl_ag)) |>
  ggplot(aes(x = year, y = empl_ag, color = regionname)) +
  geom_line(linewidth = 0.9) +
  geom_text_repel(
    data         = \(d) slice_max(d, year, n = 1, by = regionname),
    aes(label    = regionname),
    nudge_x      = 2,
    direction    = "y",
    segment.size = 0.3,
    hjust        = 0,
    size         = 3.2,
    show.legend  = FALSE
  ) +
  scale_x_continuous(breaks = seq(1970, 2025, 10),
                     expand = expansion(mult = c(0.02, 0.30))) +
  scale_y_continuous(labels = label_number(suffix = "%")) +
  scale_color_manual(values = region_colors, name = NULL) +
  base_theme() +
  theme(legend.position = "none") +
  labs(
    title    = "Employment share in agriculture by region, 1991–2024",
    subtitle = "Average % of employed population working in agriculture",
    caption  = "Source: World Bank World Development Indicators"
  )

ggsave(file.path(out, "wdi_02_empl_ag_by_region.png"),
       p2a, width = 11, height = 6, dpi = 300, bg = "white")


# ══════════════════════════════════════════════════════════════════════════════
# Plot 2b — Employment share in services by region over time
# ══════════════════════════════════════════════════════════════════════════════
p2b <- wdi |>
  summarise(empl_serv = mean(EmplShareServ, na.rm = TRUE),
            .by = c(regionname, year)) |>
  filter(!is.na(regionname), !is.na(empl_serv)) |>
  ggplot(aes(x = year, y = empl_serv, color = regionname)) +
  geom_line(linewidth = 0.9) +
  geom_text_repel(
    data         = \(d) slice_max(d, year, n = 1, by = regionname),
    aes(label    = regionname),
    nudge_x      = 2,
    direction    = "y",
    segment.size = 0.3,
    hjust        = 0,
    size         = 3.2,
    show.legend  = FALSE
  ) +
  scale_x_continuous(breaks = seq(1970, 2025, 10),
                     expand = expansion(mult = c(0.02, 0.30))) +
  scale_y_continuous(labels = label_number(suffix = "%")) +
  scale_color_manual(values = region_colors, name = NULL) +
  base_theme() +
  theme(legend.position = "none") +
  labs(
    title    = "Employment share in services by region, 1991–2024",
    subtitle = "Average % of employed population working in services",
    caption  = "Source: World Bank World Development Indicators"
  )

ggsave(file.path(out, "wdi_03_empl_serv_by_region.png"),
       p2b, width = 11, height = 6, dpi = 300, bg = "white")


# ══════════════════════════════════════════════════════════════════════════════
# Plot 3 — Employment-to-population ratio in SSA:
#           Tanzania and Ghana highlighted
# ══════════════════════════════════════════════════════════════════════════════
ssa_etp <- wdi |>
  filter(regionname == "Sub-Saharan Africa",
         !is.na(EmpltoPopRatio)) |>
  mutate(
    highlight = case_when(
      countryname == "Tanzania" ~ "Tanzania",
      countryname == "Ghana"    ~ "Ghana",
      TRUE                      ~ "Other"
    )
  )

highlight_colors <- c(
  "Tanzania" = "#D55E00",
  "Ghana"    = "#0072B2",
  "Other"    = "grey82"
)

p3 <- ggplot(ssa_etp, aes(x = year, y = EmpltoPopRatio,
                           group = countryname, color = highlight)) +
  geom_line(
    data      = \(d) filter(d, highlight == "Other"),
    linewidth = 0.4, alpha = 0.7
  ) +
  geom_line(
    data      = \(d) filter(d, highlight != "Other"),
    linewidth = 1.1
  ) +
  geom_text_repel(
    data         = \(d) d |>
      filter(highlight != "Other") |>
      slice_max(year, n = 1, by = countryname),
    aes(label    = countryname),
    nudge_x      = 2,
    direction    = "y",
    segment.size = 0.3,
    hjust        = 0,
    size         = 3.8
  ) +
  scale_x_continuous(breaks = seq(1990, 2025, 5),
                     expand = expansion(mult = c(0.02, 0.22))) +
  scale_y_continuous(labels = label_number(suffix = "%")) +
  scale_color_manual(values = highlight_colors, guide = "none") +
  base_theme() +
  labs(
    title    = "Employment-to-population ratio in Sub-Saharan Africa",
    subtitle = "Tanzania and Ghana highlighted; all other SSA countries in grey",
    caption  = "Source: World Bank World Development Indicators"
  )

ggsave(file.path(out, "wdi_04_ssa_empl_pop_highlight.png"),
       p3, width = 11, height = 6, dpi = 300, bg = "white")


# ══════════════════════════════════════════════════════════════════════════════
# Plot 4 — Employment share in agriculture across SSA in 2010:
#           4a) Choropleth map   4b) Lollipop chart
# ══════════════════════════════════════════════════════════════════════════════
ssa_2010 <- wdi |>
  filter(regionname == "Sub-Saharan Africa",
         year == 2010,
         !is.na(EmplShareAg)) |>
  select(country_code, countryname, EmplShareAg)

# Shorten long country names for the lollipop
ssa_2010 <- ssa_2010 |>
  mutate(
    label = case_when(
      countryname == "Congo, Dem. Rep."              ~ "DR Congo",
      countryname == "Congo, Rep."                   ~ "Congo Rep.",
      countryname == "Central African Republic"      ~ "CAR",
      countryname == "Sao Tome and Principe"         ~ "Sao Tome",
      countryname == "Tanzania"                      ~ "Tanzania",
      countryname == "Equatorial Guinea"             ~ "Eq. Guinea",
      countryname == "South Africa"                  ~ "South Africa",
      .default = countryname
    )
  )

## 4a — Map ──────────────────────────────────────────────────────────────────
africa_sf <- ne_countries(continent = "Africa", returnclass = "sf")

ssa_map <- africa_sf |>
  left_join(ssa_2010, by = c("iso_a3" = "country_code"))

p4a <- ggplot() +
  geom_sf(data = africa_sf, fill = "grey88", color = "white",
          linewidth = 0.15) +
  geom_sf(data = filter(ssa_map, !is.na(EmplShareAg)),
          aes(fill = EmplShareAg), color = "white", linewidth = 0.15) +
  geom_sf(data = filter(ssa_map, is.na(EmplShareAg)),
          fill = "grey75", color = "white", linewidth = 0.15) +
  scale_fill_distiller(
    palette   = "YlOrRd",
    direction = 1,
    name      = NULL,
    labels    = label_number(suffix = "%"),
    guide     = guide_colorbar(
      barwidth  = unit(6, "cm"),
      barheight = unit(0.4, "cm"),
      title.position = "top"
    )
  ) +
  coord_sf() +
  theme_void(base_family = "sans") +
  theme(
    legend.position  = "bottom",
    legend.direction = "horizontal",
    plot.title       = element_text(face = "bold", size = 15),
    plot.subtitle    = element_text(size = 12),
    plot.caption     = element_text(color = "grey50", size = 9)
  ) +
  labs(
    title    = "Employment share in agriculture, Sub-Saharan Africa 2010",
    subtitle = "Grey = no data",
    caption  = "Source: World Bank World Development Indicators"
  )

ggsave(file.path(out, "wdi_05_ssa_empl_ag_2010_map.png"),
       p4a, width = 8, height = 9, dpi = 300, bg = "white")

## 4b — Lollipop ─────────────────────────────────────────────────────────────
p4b <- ssa_2010 |>
  mutate(label = fct_reorder(label, EmplShareAg)) |>
  ggplot(aes(x = EmplShareAg, y = label)) +
  geom_segment(aes(x = 0, xend = EmplShareAg, yend = label),
               color = "grey70", linewidth = 0.6) +
  geom_point(color = "#0072B2", size = 2.8) +
  scale_x_continuous(labels = label_number(suffix = "%"),
                     expand = expansion(mult = c(0, 0.05))) +
  base_theme() +
  labs(
    title    = "Employment share in agriculture, Sub-Saharan Africa 2010",
    subtitle = "% of employed population working in agriculture",
    caption  = "Source: World Bank World Development Indicators"
  )

n_ssa <- nrow(ssa_2010)
h_lollipop <- max(6, n_ssa * 0.28)

ggsave(file.path(out, "wdi_06_ssa_empl_ag_2010_lollipop.png"),
       p4b, width = 9, height = h_lollipop, dpi = 300, bg = "white")


# ══════════════════════════════════════════════════════════════════════════════
# Plot 5 — Top and bottom countries in urbanisation over time
# ══════════════════════════════════════════════════════════════════════════════
# Rank by most recent year with data per country
latest_urb <- wdi |>
  filter(!is.na(urb_pop)) |>
  slice_max(year, n = 1, by = countryname) |>
  select(countryname, urb_latest = urb_pop)

top5 <- latest_urb |> slice_max(urb_latest, n = 5, with_ties = FALSE) |> pull(countryname)
bot5 <- latest_urb |> slice_min(urb_latest, n = 5, with_ties = FALSE) |> pull(countryname)

focus_countries <- c(top5, bot5)

urb_ts <- wdi |>
  filter(countryname %in% focus_countries, !is.na(urb_pop)) |>
  mutate(
    group    = ifelse(countryname %in% top5, "Most urbanised", "Least urbanised"),
    col_key  = paste0(group, ": ", countryname)
  )

# Build 10-color palette: 5 warm for top, 5 cool for bottom
top_colors <- c("#D55E00", "#E69F00", "#CC79A7", "#F0E442", "#000000")
bot_colors <- c("#0072B2", "#56B4E9", "#009E73", "#8DC3A7", "#7B8EAB")

top_pal <- setNames(top_colors, paste0("Most urbanised: ", top5))
bot_pal <- setNames(bot_colors, paste0("Least urbanised: ", bot5))
full_pal <- c(top_pal, bot_pal)

p5 <- urb_ts |>
  ggplot(aes(x = year, y = urb_pop, color = col_key, group = countryname)) +
  geom_line(linewidth = 0.9) +
  geom_text_repel(
    data         = \(d) slice_max(d, year, n = 1, by = countryname),
    aes(label    = countryname),
    nudge_x      = 2,
    direction    = "y",
    segment.size = 0.3,
    hjust        = 0,
    size         = 3.2
  ) +
  scale_x_continuous(breaks = seq(1970, 2025, 10),
                     expand = expansion(mult = c(0.02, 0.28))) +
  scale_y_continuous(labels = label_number(suffix = "%")) +
  scale_color_manual(values = full_pal, name = NULL) +
  base_theme() +
  theme(legend.position = "none") +
  labs(
    title    = "Most and least urbanised countries, 1970–2024",
    subtitle = "Top 5 (warm) and bottom 5 (cool) countries by urbanisation rate",
    caption  = "Source: World Bank World Development Indicators"
  )

ggsave(file.path(out, "wdi_07_top_bottom_urb_pop.png"),
       p5, width = 12, height = 6, dpi = 300, bg = "white")


# ══════════════════════════════════════════════════════════════════════════════
# Plots 6a & 6b — Urban population vs GDP per capita (scatter)
#   Cross-section: country averages 2000–2020
# ══════════════════════════════════════════════════════════════════════════════
scatter_base <- wdi |>
  filter(year >= 2000, year <= 2020,
         !is.na(urb_pop), !is.na(gdp_pc), gdp_pc > 0) |>
  summarise(
    urb_pop = mean(urb_pop, na.rm = TRUE),
    gdp_pc  = mean(gdp_pc,  na.rm = TRUE),
    .by     = c(countryname, regionname)
  ) |>
  filter(!is.na(regionname))

## 6a — Color by region ───────────────────────────────────────────────────────
p6a <- scatter_base |>
  ggplot(aes(x = gdp_pc, y = urb_pop)) +
  geom_point(aes(color = regionname), alpha = 0.75, size = 2.2) +
  geom_smooth(
    method    = "loess",
    se        = TRUE,
    color     = "grey30",
    fill      = "grey80",
    linewidth = 0.7
  ) +
  scale_x_log10(labels = label_dollar(scale_cut = cut_short_scale())) +
  scale_y_continuous(labels = label_number(suffix = "%")) +
  scale_color_manual(values = region_colors, name = NULL) +
  base_theme() +
  theme(legend.position = "bottom") +
  labs(
    title    = "Urban population vs GDP per capita, 2000–2020 average",
    subtitle = "Each point is a country average; log scale on x-axis; LOESS smooth, 95% CI",
    caption  = "Source: World Bank World Development Indicators"
  )

ggsave(file.path(out, "wdi_08_scatter_urb_gdp_regions.png"),
       p6a, width = 10, height = 7, dpi = 300, bg = "white")

## 6b — SSA highlighted ───────────────────────────────────────────────────────
scatter_ssa <- scatter_base |>
  mutate(
    ssa = ifelse(regionname == "Sub-Saharan Africa",
                 "Sub-Saharan Africa", "Other regions")
  )

p6b <- scatter_ssa |>
  ggplot(aes(x = gdp_pc, y = urb_pop)) +
  geom_point(
    data      = \(d) filter(d, ssa == "Other regions"),
    color     = "grey75",
    alpha     = 0.45, size = 2
  ) +
  geom_point(
    data      = \(d) filter(d, ssa == "Sub-Saharan Africa"),
    color     = "#CC79A7",
    alpha     = 0.85, size = 2.5
  ) +
  geom_smooth(
    method    = "loess",
    se        = TRUE,
    color     = "grey30",
    fill      = "grey80",
    linewidth = 0.7
  ) +
  scale_x_log10(labels = label_dollar(scale_cut = cut_short_scale())) +
  scale_y_continuous(labels = label_number(suffix = "%")) +
  annotate("text", x = Inf, y = -Inf,
           label = "Pink = Sub-Saharan Africa",
           hjust = 1.05, vjust = -0.5,
           size = 3.5, color = "#CC79A7") +
  base_theme() +
  theme(legend.position = "none") +
  labs(
    title    = "Urban population vs GDP per capita: Sub-Saharan Africa",
    subtitle = "Sub-Saharan Africa highlighted; log scale on x-axis; LOESS smooth, 95% CI",
    caption  = "Source: World Bank World Development Indicators"
  )

ggsave(file.path(out, "wdi_09_scatter_urb_gdp_ssa.png"),
       p6b, width = 10, height = 7, dpi = 300, bg = "white")


# ══════════════════════════════════════════════════════════════════════════════
# Plots 7a & 7b — GDP sector composition over time (world)
# ══════════════════════════════════════════════════════════════════════════════

## 7a — Stacked area of sector SHARES (world average) ─────────────────────────
sector_share_world <- wdi |>
  filter(!is.na(share_va_ag), !is.na(share_va_ind), !is.na(share_va_serv)) |>
  summarise(
    Agriculture = mean(share_va_ag,   na.rm = TRUE),
    Industry    = mean(share_va_ind,  na.rm = TRUE),
    Services    = mean(share_va_serv, na.rm = TRUE),
    .by         = year
  ) |>
  pivot_longer(cols = c(Agriculture, Industry, Services),
               names_to = "sector", values_to = "share") |>
  mutate(
    sector = factor(sector, levels = c("Agriculture", "Industry", "Services"))
  )

# Palette for sectors
sector_colors <- c(
  "Agriculture" = "#009E73",
  "Industry"    = "#E69F00",
  "Services"    = "#0072B2"
)

# Right-side labels at band midpoint for last year
label_data_7a <- sector_share_world |>
  filter(year == max(year)) |>
  arrange(factor(sector, levels = c("Agriculture", "Industry", "Services"))) |>
  mutate(
    cum_share = cumsum(share),
    mid_share = cum_share - share / 2
  )

p7a <- sector_share_world |>
  ggplot(aes(x = year, y = share, fill = sector)) +
  geom_area(position = "stack", alpha = 0.85) +
  geom_text(
    data    = label_data_7a,
    aes(x   = max(sector_share_world$year) + 0.5,
        y   = mid_share,
        label = sector,
        color = sector),
    hjust   = 0,
    size    = 3.8,
    fontface = "bold",
    inherit.aes = FALSE
  ) +
  scale_x_continuous(breaks = seq(1970, 2025, 10),
                     expand = expansion(mult = c(0.02, 0.18))) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  scale_fill_manual(values  = sector_colors, name = NULL) +
  scale_color_manual(values = sector_colors, guide = "none") +
  base_theme() +
  theme(legend.position = "none") +
  labs(
    title    = "Global GDP composition by sector, 1970–2024",
    subtitle = "Average share of value added across countries; Agriculture, Industry, Services",
    caption  = "Source: World Bank World Development Indicators"
  )

ggsave(file.path(out, "wdi_10_gdp_shares_stacked.png"),
       p7a, width = 11, height = 6, dpi = 300, bg = "white")


## 7b — Stacked area of sector ABSOLUTE totals (world sum) ──────────────────
sector_abs_world <- wdi |>
  filter(!is.na(gdp_ag_cd), !is.na(gdp_ind_cd), !is.na(gdp_serv_cd)) |>
  summarise(
    Agriculture = sum(gdp_ag_cd,   na.rm = TRUE),
    Industry    = sum(gdp_ind_cd,  na.rm = TRUE),
    Services    = sum(gdp_serv_cd, na.rm = TRUE),
    .by         = year
  ) |>
  pivot_longer(cols = c(Agriculture, Industry, Services),
               names_to = "sector", values_to = "gdp_usd") |>
  mutate(
    sector  = factor(sector, levels = c("Agriculture", "Industry", "Services")),
    gdp_usd = gdp_usd / 1e12  # express in trillions
  )

label_data_7b <- sector_abs_world |>
  filter(year == max(year)) |>
  arrange(factor(sector, levels = c("Agriculture", "Industry", "Services"))) |>
  mutate(
    cum_val = cumsum(gdp_usd),
    mid_val = cum_val - gdp_usd / 2
  )

p7b <- sector_abs_world |>
  ggplot(aes(x = year, y = gdp_usd, fill = sector)) +
  geom_area(position = "stack", alpha = 0.85) +
  geom_text(
    data    = label_data_7b,
    aes(x   = max(sector_abs_world$year) + 0.5,
        y   = mid_val,
        label = sector,
        color = sector),
    hjust   = 0,
    size    = 3.8,
    fontface = "bold",
    inherit.aes = FALSE
  ) +
  scale_x_continuous(breaks = seq(1970, 2025, 10),
                     expand = expansion(mult = c(0.02, 0.18))) +
  scale_y_continuous(labels = label_number(suffix = "T", prefix = "$")) +
  scale_fill_manual(values  = sector_colors, name = NULL) +
  scale_color_manual(values = sector_colors, guide = "none") +
  base_theme() +
  theme(legend.position = "none") +
  labs(
    title    = "World GDP by sector, 1970–2024",
    subtitle = "Sum of value added across reporting countries; current USD trillions",
    caption  = "Source: World Bank World Development Indicators"
  )

ggsave(file.path(out, "wdi_11_gdp_absolute_stacked.png"),
       p7b, width = 11, height = 6, dpi = 300, bg = "white")


message("All 11 plots saved to wdi_plots/")
