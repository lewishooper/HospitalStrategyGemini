library(tidyverse)

# --- 1. DATA PREP (Standardize Secondary) ---
# We ensure the Secondary axis uses the exact same definitions as the Primary
heatmap_ready_df <- final_dataset %>%
  mutate(
    # Clean the raw text
    sec_clean = str_remove_all(secondary_theme, "^\\d+\\.\\s*") %>% 
      str_remove_all("\\*") %>% 
      str_trim() %>% 
      str_to_title(),
    
    # Map to Official Categories
    Secondary_Standardized = case_when(
      str_detect(sec_clean, "Patient Care") ~ "Patient Care Excellence",
      str_detect(sec_clean, "Access") ~ "Access & Capacity",
      str_detect(sec_clean, "Equity") ~ "Health Equity & Social Accountability",
      str_detect(sec_clean, "Population") ~ "Population & Community Health",
      str_detect(sec_clean, "Workforce") ~ "Workforce Sustainability",
      str_detect(sec_clean, "Financial") ~ "Financial Sustainability",
      str_detect(sec_clean, "Digital") ~ "Digital Health & Innovation",
      str_detect(sec_clean, "Integration|Oht|Partner") ~ "Integration & Partnerships",
      str_detect(sec_clean, "Infrastructure") ~ "Infrastructure & Environment",
      str_detect(sec_clean, "Culture|Governance") ~ "Org Culture & Governance",
      str_detect(sec_clean, "Research|Education") ~ "Research, Education & Academics",
      TRUE ~ "None" # Group nulls/reviews together to clean the chart
    )
  ) %>%
  # Filter out rows where there is NO secondary theme (optional, keeps chart dense)
  filter(Secondary_Standardized != "None")

# --- 2. COUNT MATRIX ---
# We count every pair (e.g., Primary: Digital + Secondary: Access = 5 times)
matrix_data <- heatmap_ready_df %>%
  count(Standardized_Theme, Secondary_Standardized) %>%
  # This line ensures 0s are plotted as blank/grey squares rather than missing
  complete(Standardized_Theme, Secondary_Standardized, fill = list(n = 0))

# --- 3. PLOT ---
ggplot(matrix_data, aes(x = Secondary_Standardized, y = Standardized_Theme, fill = n)) +
  
  # The Heatmap Tiles
  geom_tile(color = "white", size = 0.5) + 
  
  # The Numbers (Only show if > 0 to avoid clutter)
  geom_text(aes(label = ifelse(n > 0, n, "")), size = 3, color = "black") +
  
  # Color Scale (Light Blue -> Dark Blue is professional for reports)
  scale_fill_gradient(low = "#e6f5ff", high = "#004c8c") +
  
  # Labels
  labs(
    title = "Strategic Intersections: Primary Drivers vs. Secondary Goals",
    subtitle = "Vertical Axis = The Strategy (Driver) | Horizontal Axis = The Outcome (Supported)",
    x = "Secondary Theme (Outcome)",
    y = "Primary Theme (Driver)",
    fill = "Frequency"
  ) +
  
  # Styling
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 9), # Angled for readability
    axis.text.y = element_text(face = "bold", size = 10),
    panel.grid = element_blank(), # Remove grid lines (tiles are the grid)
    plot.title = element_text(face = "bold", size = 14)
  )