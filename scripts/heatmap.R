# R Logic for Heatmap
library(tidyverse)



heatmap_data <- final_dataset %>%
  group_by(Type, Standardized_Theme) %>%
  summarise(count = n(), .groups = 'drop') %>%
  group_by(Type) %>%
  mutate(freq = count / sum(count) * 100)

ggplot(heatmap_data, aes(x = Type, y = Standardized_Theme, fill = freq)) +
  geom_tile() +
  scale_fill_viridis_c(name = "% Prevalence") +
  labs(title = "Strategic Priorities by Hospital Type",
       subtitle = "Relative Frequency (Corrected for Anchor FACs)") +
  theme_minimal()
