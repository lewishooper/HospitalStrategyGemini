# ============================================================
# STEP 1: Flag whether each hospital has ANY finance keyword hits
# ============================================================

df_finance_flag <- df_finance %>%
  group_by(FAC, Hospital_Name, Type, Start_Year) %>%
  summarise(
    Total_Finance_Hits = sum(finance_hits),
    Has_Finance        = Total_Finance_Hits > 0,
    .groups = "drop"
  )

# ============================================================
# STEP 2: Aggregate - Field as a Whole
# ============================================================

finance_all_types <- df_finance_flag %>%
  group_by(Start_Year) %>%
  summarise(
    N_Hospitals_Total   = n_distinct(FAC),
    N_Hospitals_Finance = sum(Has_Finance),
    Pct_Hospitals       = N_Hospitals_Finance / N_Hospitals_Total,
    .groups = "drop"
  )

# ============================================================
# STEP 3: Aggregate - By Type
# ============================================================

finance_by_type <- df_finance_flag %>%
  group_by(Start_Year, Type) %>%
  summarise(
    N_Hospitals_Total   = n_distinct(FAC),
    N_Hospitals_Finance = sum(Has_Finance),
    Pct_Hospitals       = N_Hospitals_Finance / N_Hospitals_Total,
    .groups = "drop"
  )

# Filter sparse types
type_counts <- finance_by_type %>%
  group_by(Type) %>%
  summarise(Total = sum(N_Hospitals_Total), .groups = "drop") %>%
  filter(Total >= 3)

finance_by_type_filtered <- finance_by_type %>%
  filter(Type %in% type_counts$Type)

# ============================================================
# PLOT 1 - Overall, Hospitals Mentioning Finance by Year
# ============================================================

p1 <- ggplot(finance_all_types, aes(x = Start_Year, y = N_Hospitals_Finance)) +
  
  geom_point(aes(size = N_Hospitals_Total), colour = "#1a6faf", alpha = 0.85) +
  
  geom_text(aes(label = paste0(N_Hospitals_Finance, " of ", N_Hospitals_Total, " hospitals")),
            vjust = -1.4, size = 3.2, colour = "grey40") +
  
  scale_x_continuous(breaks = sort(unique(finance_all_types$Start_Year))) +
  scale_y_continuous(breaks = scales::pretty_breaks()) +
  scale_size_continuous(range = c(3, 8), name = "Total Hospitals\nThat Year") +
  
  labs(
    title    = "Financial Sustainability: Hospitals Including Finance in Strategic Plans by Year",
    subtitle = "Count of hospitals with at least one financial keyword in their strategic direction corpus",
    x        = "Plan Start Year",
    y        = "# Hospitals Mentioning Financial Keywords",
    caption  = paste0("Keywords: ", paste(finance_keywords, collapse = ", "))
  ) +
  
  theme_minimal(base_size = 13) +
  theme(
    plot.title      = element_text(face = "bold", size = 14),
    plot.subtitle   = element_text(colour = "grey45", size = 10),
    plot.caption    = element_text(colour = "grey55", size = 7.5, hjust = 0),
    axis.text.x     = element_text(angle = 45, hjust = 1),
    legend.position = "bottom"
  )

print(p1)

# ============================================================
# PLOT 2 - By Hospital Type, Faceted
# ============================================================

p2 <- ggplot(finance_by_type_filtered,
             aes(x = Start_Year, y = N_Hospitals_Finance, colour = Type)) +
  
  geom_point(aes(size = N_Hospitals_Total), alpha = 0.85) +
  
  geom_text(aes(label = paste0(N_Hospitals_Finance, " of ", N_Hospitals_Total)),
            vjust = -1.4, size = 2.8, colour = "grey40") +
  
  scale_x_continuous(breaks = \(x) seq(floor(min(x)), ceiling(max(x)), by = 2)) +
  scale_y_continuous(breaks = scales::pretty_breaks()) +
  scale_size_continuous(range = c(2, 7), name = "Total Hospitals\nThat Year") +
  
  facet_wrap(~ Type, ncol = 2, scales = "free_y") +
  
  labs(
    title    = "Financial Sustainability: Hospitals Including Finance in Strategic Plans by Year & Type",
    subtitle = "Count of hospitals with at least one financial keyword | label shows finance hospitals of total that year",
    x        = "Plan Start Year",
    y        = "# Hospitals Mentioning Financial Keywords",
    caption  = paste0("Keywords: ", paste(finance_keywords, collapse = ", "))
  ) +
  
  theme_minimal(base_size = 12) +
  theme(
    plot.title      = element_text(face = "bold", size = 14),
    plot.subtitle   = element_text(colour = "grey45", size = 10),
    plot.caption    = element_text(colour = "grey55", size = 7.5, hjust = 0),
    axis.text.x     = element_text(angle = 45, hjust = 1),
    legend.position = "none"
  )

print(p2)