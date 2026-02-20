# ============================================================
# FINANCIAL SUSTAINABILITY - Keyword Frequency by Year
# ============================================================

library(tidyverse)
library(ggplot2)

# ============================================================
# STEP 1: Build keyword-level frequency dataframe
# by Start_Year and Type, with an "All Types" aggregate
# ============================================================

build_theme_frequency_df <- function(df, theme_keywords) {
  
  # Clean and select needed columns
  df_clean <- df %>%
    filter(
      !is.na(Analysis_Corpus),
      str_trim(Analysis_Corpus) != "",
      !str_detect(str_trim(Analysis_Corpus), "^NF\\.?$"),
      !is.na(Start_Year)
    ) %>%
    select(FAC, Hospital_Name, Type, Start_Year, Analysis_Corpus)
  
  map_dfr(names(theme_keywords), function(theme) {
    keywords <- theme_keywords[[theme]]
    
    map_dfr(keywords, function(kw) {
      
      kw_lower  <- str_to_lower(kw)
      is_phrase <- str_detect(kw, "\\s")
      pattern   <- if (is_phrase) fixed(kw_lower) else 
        regex(paste0("\\b", regex_escape(kw_lower), "\\b"))
      
      # Per-row match count and word count
      row_data <- df_clean %>%
        mutate(
          kw_count   = str_count(str_to_lower(Analysis_Corpus), pattern),
          word_count = map_int(Analysis_Corpus, count_words)
        )
      
      # By Type and Year
      by_type <- row_data %>%
        group_by(Start_Year, Type) %>%
        summarise(
          Total_Matches  = sum(kw_count),
          Total_Words    = sum(word_count, na.rm = TRUE),
          N_Directions   = n(),
          .groups = "drop"
        ) %>%
        mutate(Group = Type)
      
      # Across all types (aggregate)
      all_types <- row_data %>%
        group_by(Start_Year) %>%
        summarise(
          Total_Matches  = sum(kw_count),
          Total_Words    = sum(word_count, na.rm = TRUE),
          N_Directions   = n(),
          .groups = "drop"
        ) %>%
        mutate(
          Group = "All Types",
          Type  = "All Types"
        )
      
      bind_rows(by_type, all_types) %>%
        mutate(
          Theme              = theme,
          Keyword            = kw,
          Normalized_Score   = if_else(Total_Words > 0, 
                                       Total_Matches / Total_Words, 
                                       NA_real_),
          Matches_Per_Direction = if_else(N_Directions > 0,
                                          Total_Matches / N_Directions,
                                          NA_real_)
        )
    })
  })
}

# ============================================================
# STEP 2: Run it
# ============================================================

theme_freq_df <- build_theme_frequency_df(df, theme_keywords)

# ============================================================
# STEP 3: Filter to Financial Sustainability, All Types
# Aggregate across all keywords in the theme by year
# ============================================================

finance_by_year <- theme_freq_df %>%
  filter(
    Theme == "FINANCIAL_SUSTAINABILITY",
    Group == "All Types"
  ) %>%
  group_by(Start_Year) %>%
  summarise(
    Total_Matches     = sum(Total_Matches),
    Total_Words       = sum(Total_Words) / n_distinct(Keyword),  # avoid inflating word count
    N_Directions      = first(N_Directions),
    Normalized_Score  = Total_Matches / (Total_Words),
    .groups = "drop"
  )

# Quick check
print(finance_by_year)

# ============================================================
# STEP 4: Plot - Financial Theme Emphasis by Year
# ============================================================

ggplot(finance_by_year, aes(x = Start_Year, y = Normalized_Score)) +
  
  # Confidence band via loess
  geom_smooth(method = "loess", span = 0.9,
              colour = "#1a6faf", fill = "#a8c8e8", alpha = 0.25,
              linewidth = 0.8) +
  
  # Actual data points sized by number of directions
  geom_point(aes(size = N_Directions), 
             colour = "#1a6faf", alpha = 0.85) +
  
  # Label each year's N
  geom_text(aes(label = paste0("n=", N_Directions)),
            vjust = -1.2, size = 3.2, colour = "grey40") +
  
  scale_x_continuous(breaks = sort(unique(finance_by_year$Start_Year))) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
  scale_size_continuous(range = c(3, 8), name = "# Directions") +
  
  labs(
    title    = "Financial Sustainability Theme: Strategic Emphasis by Plan Start Year",
    subtitle = "Normalized score = financial keyword occurrences ÷ total words in direction corpus",
    x        = "Plan Start Year",
    y        = "Normalized Keyword Frequency",
    caption  = paste0("Keywords: ", 
                      paste(theme_keywords$FINANCIAL_SUSTAINABILITY, collapse = ", "))
  ) +
  
  theme_minimal(base_size = 13) +
  theme(
    plot.title    = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(colour = "grey45", size = 10),
    plot.caption  = element_text(colour = "grey55", size = 7.5, hjust = 0),
    axis.text.x   = element_text(angle = 45, hjust = 1),
    legend.position = "bottom"
  )