# Step 1: Unnest the comma-separated keywords into one row per keyword
strategic_themes_long <- strategic_themes_revised %>%
  mutate(keyword_lower = str_to_lower(Keywords)) %>%
  separate_rows(keyword_lower, sep = ",") %>%          # split on comma
  mutate(keyword_lower = str_squish(keyword_lower))    # clean up whitespace

# Quick check
cat("Total individual keywords:", nrow(strategic_themes_long), "\n")
print(strategic_themes_long %>% select(Theme, keyword_lower), n = 50)

# Step 2: Split into single-word vs phrase (same logic as before)
keywords_single <- strategic_themes_long %>%
  filter(!str_detect(keyword_lower, "\\s"))

keywords_phrase <- strategic_themes_long %>%
  filter(str_detect(keyword_lower, "\\s"))

cat("\nSingle-word keywords:", nrow(keywords_single), "\n")
cat("Multi-word phrases:", nrow(keywords_phrase), "\n")

# Step 3: Join to word_freq
word_freq_flagged <- word_freq %>%
  left_join(
    keywords_single %>%
      select(keyword_lower, Theme) %>%
      distinct(keyword_lower, .keep_all = TRUE),
    by = c("word" = "keyword_lower")
  ) %>%
  mutate(
    in_taxonomy   = !is.na(Theme),
    theme_matched = Theme
  ) %>%
  select(-Theme)

WrdFreqFlaged<-word_freq_flagged %>%
  relocate(word,rank,in_taxonomy,theme_matched)%>%
  select(word,rank,in_taxonomy,theme_matched) %>%
  arrange(theme_matched) %>% head(20)

