# =============================================================================
# THEME KEYWORD BALANCE CHECK
# Counts words and phrases per theme to assess taxonomy balance
# =============================================================================

theme_balance <- themes_raw %>%
  mutate(
    # Parse keywords exactly as in Phase 1
    Keywords = str_split(Include_Raw, ",\\s*")
  ) %>%
  unnest(Keywords) %>%
  mutate(
    Keywords = str_trim(Keywords),
    Keywords = str_remove(Keywords, "[./]$")
  ) %>%
  filter(Keywords != "") %>%
  mutate(
    # Classify each entry as single word vs multi-word phrase
    word_count  = str_count(Keywords, "\\S+"),
    entry_type  = if_else(word_count == 1, "Single Word", "Phrase")
  ) %>%
  group_by(Theme_ID, Theme) %>%
  summarise(
    n_total     = n(),
    n_words     = sum(entry_type == "Single Word"),
    n_phrases   = sum(entry_type == "Phrase"),
    all_keywords = paste(Keywords, collapse = " | "),
    .groups = "drop"
  ) %>%
  arrange(Theme_ID)

# Display summary table
cat("============================================================\n")
cat("KEYWORD COUNT BY THEME\n")
cat("============================================================\n")
print(
  theme_balance %>% select(Theme_ID, Theme, n_total, n_words, n_phrases),
  n = Inf
)

cat("\n============================================================\n")
cat("BALANCE DIAGNOSTICS\n")
cat("============================================================\n")
cat("Mean keywords per theme: ", round(mean(theme_balance$n_total), 1), "\n")
cat("Min keywords per theme:  ", min(theme_balance$n_total), 
    " —", theme_balance$Theme[which.min(theme_balance$n_total)], "\n")
cat("Max keywords per theme:  ", max(theme_balance$n_total), 
    " —", theme_balance$Theme[which.max(theme_balance$n_total)], "\n")
cat("Range:                   ", max(theme_balance$n_total) - min(theme_balance$n_total), "\n\n")

# Flag themes that are notably thin or heavy relative to the mean
mean_kw <- mean(theme_balance$n_total)
theme_balance %>%
  mutate(
    balance_flag = case_when(
      n_total < mean_kw * 0.6 ~ "Under-specified (< 60% of mean)",
      n_total > mean_kw * 1.4 ~ "Over-specified (> 140% of mean)",
      TRUE                    ~ "Within normal range"
    )
  ) %>%
  filter(balance_flag != "Within normal range") %>%
  select(Theme, n_total, balance_flag) %>%
  { if (nrow(.) == 0) cat("All themes within normal range.\n") else print(., n = Inf) }

# Detailed keyword listing for review
cat("\n============================================================\n")
cat("FULL KEYWORD LISTING BY THEME\n")
cat("============================================================\n")
theme_balance %>%
  select(Theme_ID, Theme, n_total, all_keywords) %>%
  pwalk(function(Theme_ID, Theme, n_total, all_keywords) {
    cat(sprintf("[%2d] %-45s (%d keywords)\n     %s\n\n", 
                Theme_ID, Theme, n_total, all_keywords))
  })

# Visual
theme_balance %>%
  mutate(Theme = fct_reorder(str_wrap(Theme, 30), n_total)) %>%
  ggplot(aes(x = n_total, y = Theme)) +
  geom_col(fill = "steelblue") +
  geom_vline(xintercept = mean(theme_balance$n_total), 
             linetype = "dashed", colour = "firebrick", linewidth = 0.8) +
  geom_text(aes(label = n_total), hjust = -0.3, size = 3.5) +
  annotate("text", x = mean(theme_balance$n_total) + 0.1, y = 1.5,
           label = paste("Mean =", round(mean(theme_balance$n_total), 1)),
           colour = "firebrick", hjust = 0, size = 3.5) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(
    title    = "Keyword Count per Strategic Theme",
    subtitle = "Dashed line = mean across all themes",
    x        = "Number of Keywords / Phrases",
    y        = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.major.y = element_blank())




## against themes Raw

# =============================================================================
# THEME KEYWORD BALANCE CHECK
# Counts words and phrases per theme to assess taxonomy balance
# =============================================================================

theme_balance <- strategic_themes_revised %>%
  rename(Include_Raw=Keywords)%>%
  select(-n_keywords_retained) %>%
  mutate(
    # Parse keywords exactly as in Phase 1
    Keywords = str_split(Include_Raw, ",\\s*")
  ) %>%
  unnest(Keywords) %>%
  mutate(
    Keywords = str_trim(Keywords),
    Keywords = str_remove(Keywords, "[./]$")
  ) %>%
  filter(Keywords != "") %>%
  mutate(
    # Classify each entry as single word vs multi-word phrase
    word_count  = str_count(Keywords, "\\S+"),
    entry_type  = if_else(word_count == 1, "Single Word", "Phrase")
  ) %>%
  group_by(Theme_ID, Theme) %>%
  summarise(
    n_total     = n(),
    n_words     = sum(entry_type == "Single Word"),
    n_phrases   = sum(entry_type == "Phrase"),
    all_keywords = paste(Keywords, collapse = " | "),
    .groups = "drop"
  ) %>%
  arrange(Theme_ID)

# Display summary table
cat("============================================================\n")
cat("KEYWORD COUNT BY THEME\n")
cat("============================================================\n")
print(
  theme_balance %>% select(Theme_ID, Theme, n_total, n_words, n_phrases),
  n = Inf
)

cat("\n============================================================\n")
cat("BALANCE DIAGNOSTICS\n")
cat("============================================================\n")
cat("Mean keywords per theme: ", round(mean(theme_balance$n_total), 1), "\n")
cat("Min keywords per theme:  ", min(theme_balance$n_total), 
    " —", theme_balance$Theme[which.min(theme_balance$n_total)], "\n")
cat("Max keywords per theme:  ", max(theme_balance$n_total), 
    " —", theme_balance$Theme[which.max(theme_balance$n_total)], "\n")
cat("Range:                   ", max(theme_balance$n_total) - min(theme_balance$n_total), "\n\n")

# Flag themes that are notably thin or heavy relative to the mean
mean_kw <- mean(theme_balance$n_total)
theme_balance %>%
  mutate(
    balance_flag = case_when(
      n_total < mean_kw * 0.6 ~ "Under-specified (< 60% of mean)",
      n_total > mean_kw * 1.4 ~ "Over-specified (> 140% of mean)",
      TRUE                    ~ "Within normal range"
    )
  ) %>%
  filter(balance_flag != "Within normal range") %>%
  select(Theme, n_total, balance_flag) %>%
  { if (nrow(.) == 0) cat("All themes within normal range.\n") else print(., n = Inf) }

# Detailed keyword listing for review
cat("\n============================================================\n")
cat("FULL KEYWORD LISTING BY THEME\n")
cat("============================================================\n")
theme_balance %>%
  select(Theme_ID, Theme, n_total, all_keywords) %>%
  pwalk(function(Theme_ID, Theme, n_total, all_keywords) {
    cat(sprintf("[%2d] %-45s (%d keywords)\n     %s\n\n", 
                Theme_ID, Theme, n_total, all_keywords))
  })

# Visual
theme_balance %>%
  mutate(Theme = fct_reorder(str_wrap(Theme, 30), n_total)) %>%
  ggplot(aes(x = n_total, y = Theme)) +
  geom_col(fill = "steelblue") +
  geom_vline(xintercept = mean(theme_balance$n_total), 
             linetype = "dashed", colour = "firebrick", linewidth = 0.8) +
  geom_text(aes(label = n_total), hjust = -0.3, size = 3.5) +
  annotate("text", x = mean(theme_balance$n_total) + 0.1, y = 1.5,
           label = paste("Mean =", round(mean(theme_balance$n_total), 1)),
           colour = "firebrick", hjust = 0, size = 3.5) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(
    title    = "Keyword Count per Strategic Theme",
    subtitle = "Dashed line = mean across all themes",
    x        = "Number of Keywords / Phrases",
    y        = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.major.y = element_blank())



