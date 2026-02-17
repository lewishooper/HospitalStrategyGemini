library(tidyverse)

# --- 1. IDENTIFY PARTNERSHIPS & ASSIGN HYBRID FAC ---
# We find names with multiple FACs and assign a 400-series ID
partnership_mapping <- final_dataset %>%
  group_by(Hospital_Name) %>%
  summarise(FAC_Count = n_distinct(FAC), .groups = "drop") %>%
  filter(FAC_Count > 1) %>%
  mutate(Strategic_FAC = 400 + row_number())

# --- 2. PREPARE FINAL VIZ DATASET ---
final_viz_data <- final_dataset %>%
  left_join(partnership_mapping, by = "Hospital_Name") %>%
  mutate(
    # Use 400-series if it's a partner, otherwise keep original FAC
    Hybrid_FAC = ifelse(!is.na(Strategic_FAC), Strategic_FAC, FAC),
    
    # Consolidate Hospital Types as requested
    Type_Cleaned = case_when(
      Type == "Specialty Mental Health Hospital" ~ "Chronic/Rehab Hospital",
      Type == "Specialty Children Hospital" ~ "Teaching Hospital",
      TRUE ~ Type
    )
  ) %>%
  # Deduplicate: ensures each unique direction is counted only once per Strategic Entity
  distinct(Hybrid_FAC, Direction, .keep_all = TRUE)

# --- 3. AGGREGATE DATA FOR VISUALIZATION ---
type_summary <- final_viz_data %>%
  group_by(Type_Cleaned) %>%
  summarise(
    Total_Directions = n(),
    Entity_Count = n_distinct(Hybrid_FAC),
    .groups = "drop"
  ) %>%
  arrange(desc(Total_Directions))

# --- 4. GENERATE THE PLOT ---
ggplot(type_summary, aes(x = reorder(Type_Cleaned, Total_Directions), 
                         y = Total_Directions, 
                         fill = Type_Cleaned)) +
  geom_col(width = 0.7) +
  coord_flip() +
  geom_text(aes(label = Total_Directions), hjust = -0.2, size = 3.5) +
  labs(
    title = "Total Unique Strategic Directions by Hospital Type",
    subtitle = "Deduplicated by Strategic Entity (Partnerships vs. Standalones)",
    x = NULL,
    y = "Number of Directions",
    caption = "Note: Partnerships (e.g., MICs, Huron Perth) are treated as single Strategic Entities."
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold")
  ) +
  scale_fill_brewer(palette = "Set3")
