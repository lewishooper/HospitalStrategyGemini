library(tidyverse)

# 1. Prepare the Era-based Data
era_data <- final_dataset %>%
  # Create the binary time split
  mutate(Era = case_when(
    Start_Year < 2021 ~ "Pre-Pandemic",
    Start_Year >= 2022 ~ "Post-Pandemic",
    TRUE ~ "Transition (2021)"
  )) %>%
  filter(Era != "Transition (2021)") %>% # Filter out 2021 to sharpen the contrast
  
  # Calculate % prevalence of each theme per era
  group_by(Era, primary_theme) %>%
  summarise(count = n(), .groups = 'drop') %>%
  group_by(Era) %>%
  mutate(pct = (count / n_distinct(final_dataset$FAC)) * 100) %>%
  
  # Pivot wide for the dumbbell geom_segment
  pivot_wider(id_cols = primary_theme, names_from = Era, values_from = pct) %>%
  mutate(Diff = `Post-Pandemic` - `Pre-Pandemic`) %>%
  filter(!is.na(Diff)) # Ensure we have data for both points

# 2. Build the Plot
ggplot(era_data, aes(y = reorder(primary_theme, `Post-Pandemic`))) +
  # The "Bar" of the dumbbell
  geom_segment(aes(x = `Pre-Pandemic`, xend = `Post-Pandemic`, 
                   yend = primary_theme), color = "#e0e0e0", size = 1.5) +
  # Pre-Pandemic Points
  geom_point(aes(x = `Pre-Pandemic`, color = "Pre-Pandemic"), size = 4) +
  # Post-Pandemic Points
  geom_point(aes(x = `Post-Pandemic`, color = "Post-Pandemic"), size = 4) +
  # Add labels for the 'Finance' change specifically
  geom_text(data = filter(era_data, primary_theme == "Financial Sustainability"),
            aes(x = `Post-Pandemic`, label = paste0("+", round(Diff, 1), "%")),
            nudge_x = 3, fontface = "bold", color = "#D55E00") +
  scale_color_manual(values = c("Pre-Pandemic" = "#56B4E9", "Post-Pandemic" = "#D55E00")) +
  labs(title = "The Shift in Ontario Hospital Priorities",
       subtitle = "Comparing primary_theme Prevalence: Pre-Pandemic (<2021) vs. Post-Pandemic (>=2022)",
       x = "% of Hospital Strategic Plans", y = "", color = "Era") +
  theme_minimal()