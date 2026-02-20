# ============================================================
# FINANCIAL SUSTAINABILITY - Correct Normalization
# Numerator:   total financial keyword hits across all directions
# Denominator: total words across all directions (counted once)
# ============================================================

# ============================================================
# STEP 1: Build per-direction financial keyword counts
# ============================================================

finance_keywords <- theme_keywords[["FINANCIAL_SUSTAINABILITY"]]

df_finance <- df %>%
  filter(
    !is.na(Analysis_Corpus),
    str_trim(Analysis_Corpus) != "",
    !str_detect(str_trim(Analysis_Corpus), "^NF\\.?$"),
    !is.na(Start_Year)
  ) %>%
  select(FAC, Hospital_Name, Type, Start_Year, Analysis_Corpus) %>%
  mutate(
    # Total words in this direction's corpus (denominator)
    word_count = map_int(Analysis_Corpus, count_words),
    
    # Sum of ALL finance keyword hits for this direction (numerator)
    finance_hits = map_int(Analysis_Corpus, function(text) {
      sum(map_int(finance_keywords, function(kw) {
        kw_lower  <- str_to_lower(kw)
        is_phrase <- str_detect(kw, "\\s")
        pattern   <- if (is_phrase) fixed(kw_lower) else
          regex(paste0("\\b", regex_escape(kw_lower), "\\b"))
        str_count(str_to_lower(text), pattern)
      }))
    })
  )

# ============================================================
# STEP 2: Aggregate - Field as a whole (All Types)
# ============================================================

finance_all_types <- df_finance %>%
  group_by(Start_Year) %>%
  summarise(
    Total_Finance_Hits = sum(finance_hits),
    Total_Words        = sum(word_count, na.rm = TRUE),
    N_Directions       = n(),
    N_Hospitals        = n_distinct(FAC),
    .groups = "drop"
  ) %>%
  mutate(
    Normalized_Score = Total_Finance_Hits / Total_Words,
    Group = "All Types"
  )

# ============================================================
# STEP 3: Aggregate - By Type
# ============================================================

finance_by_type <- df_finance %>%
  group_by(Start_Year, Type) %>%
  summarise(
    Total_Finance_Hits = sum(finance_hits),
    Total_Words        = sum(word_count, na.rm = TRUE),
    N_Directions       = n(),
    N_Hospitals        = n_distinct(FAC),
    .groups = "drop"
  ) %>%
  mutate(
    Normalized_Score = Total_Finance_Hits / Total_Words,
    Group = Type
  )

# ============================================================
# STEP 4: Plot 1 - Field as a Whole
# ============================================================

p1 <- ggplot(finance_all_types, aes(x = Start_Year, y = Normalized_Score)) +
  
  geom_smooth(method = "loess", span = 0.9,
              colour = "#1a6faf", fill = "#a8c8e8", alpha = 0.25,
              linewidth = 0.8) +
  
  geom_point(aes(size = N_Hospitals),
             colour = "#1a6faf", alpha = 0.85) +
  
  geom_text(aes(label = paste0("n=", N_Hospitals)),
            vjust = -1.4, size = 3.2, colour = "grey40") +
  
  scale_x_continuous(breaks = sort(unique(finance_all_types$Start_Year))) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
  scale_size_continuous(range = c(3, 8), name = "# Hospitals") +
  
  labs(
    title    = "Financial Sustainability: Strategic Emphasis Across Ontario Hospitals",
    subtitle = "Normalized score = total financial keyword occurrences ÷ total words in all plans (all types)",
    x        = "Plan Start Year",
    y        = "Normalized Keyword Frequency",
    caption  = paste0("Keywords: ", paste(finance_keywords, collapse = ", "))
  ) +
  
  theme_minimal(base_size = 13) +
  theme(
    plot.title    = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(colour = "grey45", size = 10),
    plot.caption  = element_text(colour = "grey55", size = 7.5, hjust = 0),
    axis.text.x   = element_text(angle = 45, hjust = 1),
    legend.position = "bottom"
  )

print(p1)

# ============================================================
# STEP 5: Plot 2 - Faceted by Hospital Type
# ============================================================

# Only include types with sufficient data across years
type_counts <- finance_by_type %>%
  group_by(Type) %>%
  summarise(Total_Hospitals = sum(N_Hospitals), .groups = "drop") %>%
  filter(Total_Hospitals >= 3)   # exclude sparse types

finance_by_type_filtered <- finance_by_type %>%
  filter(Type %in% type_counts$Type)

p2 <- ggplot(finance_by_type_filtered, 
             aes(x = Start_Year, y = Normalized_Score, colour = Type)) +
  
  geom_point(method = "loess", span = 0.9, alpha = 0.15,
              aes(fill = Type), linewidth = 0.8) +
  
  geom_point(aes(size = N_Hospitals), alpha = 0.85) +
  
  geom_text(aes(label = paste0("n=", N_Hospitals)),
            vjust = -1.4, size = 2.8, colour = "grey40") +
  
  scale_x_continuous(breaks = \(x) seq(floor(min(x)), ceiling(max(x)), by = 2)) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
  scale_size_continuous(range = c(2, 7), name = "# Hospitals") +
  
  facet_wrap(~ Type, ncol = 2, scales = "free_y") +
  
  labs(
    title    = "Financial Sustainability: Strategic Emphasis by Hospital Type",
    subtitle = "Normalized score = total financial keyword occurrences ÷ total words in all plans (within type)",
    x        = "Plan Start Year",
    y        = "Normalized Keyword Frequency",
    caption  = paste0("Keywords: ", paste(finance_keywords, collapse = ", "))
  ) +
  
  theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(colour = "grey45", size = 10),
    plot.caption  = element_text(colour = "grey55", size = 7.5, hjust = 0),
    axis.text.x   = element_text(angle = 45, hjust = 1),
    legend.position = "none"    # facet labels are sufficient
  )

print(p2)