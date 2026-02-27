# =============================================================================
# KEYWORD PRUNING: Drop zero-hit keywords from theme taxonomy
# Requires: keyword_freq from Phase 1 analysis
# =============================================================================

# =============================================================================
# STEP 1: Split into retained vs dropped
# =============================================================================

keyword_freq_split <- keyword_freq %>%
  mutate(retained = n_total_occurrences > 0)

# =============================================================================
# STEP 2: Dataframe 1 — Revised strategic themes (keywords with hits only)
# =============================================================================

strategic_themes_revised <- keyword_freq_split %>%
  filter(retained) %>%
  group_by(Theme_ID, Theme) %>%
  summarise(
    n_keywords_retained = n(),
    Keywords            = paste(Keyword, collapse = ", "),
    .groups             = "drop"
  ) %>%
  arrange(Theme_ID)

cat("============================================================\n")
cat("REVISED STRATEGIC THEMES (zero-hit keywords removed)\n")
cat("============================================================\n")
strategic_themes_revised %>%
  select(Theme_ID, Theme, n_keywords_retained, Keywords) %>%
  pwalk(function(Theme_ID, Theme, n_keywords_retained, Keywords) {
    cat(sprintf("[%2d] %-45s (%d keywords retained)\n     %s\n\n",
                Theme_ID, Theme, n_keywords_retained, Keywords))
  })

# =============================================================================
# STEP 3: Dataframe 2 — Dropped keywords with context
# =============================================================================

keywords_dropped <- keyword_freq_split %>%
  filter(!retained) %>%
  select(Theme_ID, Theme, Keyword, n_directions_with, n_total_occurrences) %>%
  arrange(Theme_ID)

cat("============================================================\n")
cat("DROPPED KEYWORDS (zero occurrences in corpus)\n")
cat("============================================================\n")
print(keywords_dropped, n = Inf)

# Summary of impact by theme
cat("\n============================================================\n")
cat("IMPACT SUMMARY BY THEME\n")
cat("============================================================\n")

keyword_freq_split %>%
  group_by(Theme_ID, Theme) %>%
  summarise(
    original_count  = n(),
    retained_count  = sum(retained),
    dropped_count   = sum(!retained),
    pct_retained    = round(100 * sum(retained) / n(), 1),
    dropped_keywords = paste(Keyword[!retained], collapse = ", "),
    .groups = "drop"
  ) %>%
  arrange(Theme_ID) %>%
  mutate(
    dropped_keywords = if_else(dropped_keywords == "", "—", dropped_keywords)
  ) %>%
  pwalk(function(Theme_ID, Theme, original_count, retained_count, 
                 dropped_count, pct_retained, dropped_keywords) {
    cat(sprintf("[%2d] %-45s  %d/%d retained (%s%%)\n",
                Theme_ID, Theme, retained_count, original_count, pct_retained))
    if (dropped_count > 0) {
      cat(sprintf("     Dropped: %s\n", dropped_keywords))
    }
    cat("\n")
  })

# =============================================================================
# STEP 4: Save both dataframes
# =============================================================================

# write_csv(strategic_themes_revised, "output/strategic_themes_revised.csv")
# write_csv(keywords_dropped,         "output/keywords_dropped.csv")

cat("============================================================\n")
cat(sprintf("SUMMARY: %d keywords retained, %d dropped across %d themes\n",
            sum(keyword_freq_split$retained),
            sum(!keyword_freq_split$retained),
            n_distinct(keyword_freq$Theme_ID)))
cat("============================================================\n")