# ==================================================================
# Step 3: Statistical Analysis
# Project: Oral Health and Chronic Disease Across U.S. Counties
# Input:  data/places_county_clean.csv   (made by clean_data.py)
# Output: charts/ folder with 3 PNG charts
# ==================================================================

library(tidyverse)

# ------------------------------------------------------------------
# 1. LOAD the clean data
# ------------------------------------------------------------------
df <- read_csv("data/places_county_clean.csv", show_col_types = FALSE)
df$dental_group <- factor(df$dental_group, levels = c("Low", "Medium", "High"))
cat("Counties loaded:", nrow(df), "\n\n")

# ------------------------------------------------------------------
# 2. DESCRIPTIVE STATISTICS: basic summaries
# ------------------------------------------------------------------
cat("---- Summary of key measures (%) ----\n")
print(summary(df[, c("dental_visit_pct", "teeth_lost_pct",
                     "diabetes_pct", "heart_disease_pct")]))

state_avg <- df %>%
  group_by(state) %>%
  summarise(avg_dental = round(mean(dental_visit_pct), 1)) %>%
  arrange(avg_dental)

cat("\n---- States with LOWEST average dental visit rates ----\n")
print(head(state_avg, 5))
cat("\n---- States with HIGHEST average dental visit rates ----\n")
print(tail(state_avg, 5))

# ------------------------------------------------------------------
# 3. CORRELATION: how strongly do measures move together? (-1 to +1)
# ------------------------------------------------------------------
cat("\n---- Correlation matrix ----\n")
measures <- df %>% select(dental_visit_pct, teeth_lost_pct, diabetes_pct,
                          heart_disease_pct, smoking_pct, obesity_pct,
                          uninsured_pct)
print(round(cor(measures), 2))

# ------------------------------------------------------------------
# 4. LINEAR REGRESSION
#    Model 1: dental visits alone
#    Model 2: dental visits + smoking, obesity, and lack of insurance
#    Comparing them shows how much of the link is explained by
#    these other factors (confounding).
# ------------------------------------------------------------------
model1 <- lm(diabetes_pct ~ dental_visit_pct, data = df)
model2 <- lm(diabetes_pct ~ dental_visit_pct + smoking_pct +
               obesity_pct + uninsured_pct, data = df)

cat("\n---- Model 1: Diabetes ~ Dental visits ----\n")
print(summary(model1))
cat("\n---- Model 2: Diabetes ~ Dental visits + Smoking + Obesity + Uninsured ----\n")
print(summary(model2))

cat("\nDental visit coefficient, Model 1:",
    round(coef(model1)["dental_visit_pct"], 3),
    "| Model 2:", round(coef(model2)["dental_visit_pct"], 3), "\n")

# ------------------------------------------------------------------
# 5. VISUALIZATION with ggplot2
# ------------------------------------------------------------------
dir.create("charts", showWarnings = FALSE)

# Chart 1: scatter plot, dental visits vs diabetes
p1 <- ggplot(df, aes(x = dental_visit_pct, y = diabetes_pct)) +
  geom_point(alpha = 0.3, color = "#2c7fb8", size = 1.2) +
  geom_smooth(method = "lm", color = "#d7301f", se = TRUE) +
  labs(title = "Counties with fewer dental visits have higher diabetes rates",
       subtitle = paste0("U.S. counties (n = ", nrow(df), "), CDC PLACES 2025, age-adjusted"),
       x = "Adults who visited a dentist in the past year (%)",
       y = "Adults with diagnosed diabetes (%)") +
  theme_minimal(base_size = 12)
ggsave("charts/1_dental_vs_diabetes.png", p1, width = 8, height = 5.5, dpi = 300)

# Chart 2: box plots, diabetes by dental visit group
p2 <- ggplot(df, aes(x = dental_group, y = diabetes_pct, fill = dental_group)) +
  geom_boxplot(alpha = 0.8, outlier.alpha = 0.3) +
  scale_fill_manual(values = c("Low" = "#d7301f", "Medium" = "#fdae61", "High" = "#2c7fb8")) +
  labs(title = "Diabetes prevalence by county dental visit level",
       x = "Dental visit level (thirds of counties)",
       y = "Adults with diagnosed diabetes (%)") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none")
ggsave("charts/2_diabetes_by_dental_group.png", p2, width = 7, height = 5.5, dpi = 300)

# Chart 3: scatter plot, tooth loss vs heart disease
p3 <- ggplot(df, aes(x = teeth_lost_pct, y = heart_disease_pct)) +
  geom_point(alpha = 0.3, color = "#7b3294", size = 1.2) +
  geom_smooth(method = "lm", color = "#1b7837", se = TRUE) +
  labs(title = "Complete tooth loss tracks closely with heart disease",
       subtitle = "Tooth loss measured in adults 65+; CDC PLACES 2025, age-adjusted",
       x = "Adults 65+ who lost all their teeth (%)",
       y = "Adults with coronary heart disease (%)") +
  theme_minimal(base_size = 12)
ggsave("charts/3_toothloss_vs_heart_disease.png", p3, width = 8, height = 5.5, dpi = 300)

cat("\nSaved 3 charts to the charts/ folder\n")
