# --- 1. CONSOLIDATE HOSPITAL TYPES ---
# Applying the specific rolls for Mental Health and Children's
final_dataset_cleaned <- final_dataset %>%
  mutate(Type = case_when(
    Type == "Specialty Mental Health Hospital" ~ "Chronic/Rehab Hospital",
    Type == "Specialty Children Hospital" ~ "Teaching Hospital",
    TRUE ~ Type
  ))

# --- 2. GENERATE HYBRID FACs ---
# Step A: Identify unique hospital names that have multiple original FACs
partnership_map <- final_dataset_cleaned %>%
  group_by(Hospital_Name) %>%
  summarize(
    FAC_Count = n_distinct(FAC),
    .groups = "drop"
  ) %>%
  filter(FAC_Count >= 2) %>%
  mutate(Strategic_FAC = 400 + row_number()) # Assign 400-series to partners

# Step B: Create the Hybrid_FAC column
final_viz_data <- final_dataset_cleaned %>%
  left_join(partnership_map, by = "Hospital_Name") %>%
  mutate(
    # Use 400-series if it exists, otherwise keep original FAC
    Hybrid_FAC = ifelse(!is.na(Strategic_FAC), Strategic_FAC, FAC)
  ) %>%
  # Deduplicate so each unique Strategic Entity (Hybrid_FAC) 
  # only contributes its directions once
  distinct(Hybrid_FAC, Direction, .keep_all = TRUE)

# --- 3. RECREATE THE OVERVIEW TABLE ---
overview_table <- final_viz_data %>%
  group_by(Type) %>%
  summarize(
    `Entity Count` = n_distinct(Hybrid_FAC),
    `Total Directions` = n(),
    `Avg Directions` = round(n() / n_distinct(Hybrid_FAC), 1),
    .groups = "drop"
  ) %>%
  arrange(desc(`Entity Count`))

# Displaying results
print("Strategic Entity Overview (Hybrid FAC Model):")
print(overview_table)

# Validation check for the 400-series
print("Sample of Hybrid FACs (Partnerships vs Standalones):")
final_viz_data %>% 
  distinct(Hospital_Name, FAC, Hybrid_FAC) %>% 
  filter(Hybrid_FAC >= 400 | row_number() <= 5) %>%
  print()