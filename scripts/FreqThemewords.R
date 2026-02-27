# =============================================================================
# PHASE 1: Theme Keyword Frequency Validation
# Checks how often each theme keyword/phrase appears in the Analysis_Corpus
# =============================================================================

library(tidyverse)
library(stringr)
#rm(list=ls())
# =============================================================================
# STEP 1: Define the theme taxonomy
# =============================================================================

themes_raw <- tribble(
  ~Theme_ID, ~Theme,                          ~Include_Raw,
  1,  "Patient Care Excellence",              "Quality improvement, safety, patient experience, clinical outcomes, zero harm",
  2,  "Access & Capacity",                    "Wait times, patient flow, bed capacity, ED throughput, hours of operation",
  3,  "Health Equity & Social Accountability","Indigenous health, EDI, DEI, anti-racism, vulnerable populations, Francophone services",
  4,  "Population & Community Health",        "Health promotion, chronic disease management, OHT goals, mental health/addiction strategy",
  5,  "Workforce Sustainability",             "Recruitment, retention, burnout, wellness, leadership development",
  6,  "Financial Sustainability",             "Efficiency, funding models, cost savings, revenue generation",
  7,  "Digital Health & Innovation",          "HIS, EMR, AI, virtual care, data analytics, cyber security",
  8,  "Integration & Partnerships",           "System integration, OHT governance, cross-sector collaboration",
  9,  "Infrastructure & Environment",         "Capital redevelopment, new builds, facilities, parking, green hospital/sustainability",
  10, "Organizational Culture & Governance",  "Mission/Values, governance, accountability, community engagement, branding",
  11, "Research, Education & Academics",      "Research institutes, clinical trials, medical education, innovation labs"
)

# Parse Include_Raw into individual keyword rows
theme_keywords <- themes_raw %>%
  mutate(Keyword = str_split(Include_Raw, ",\\s*")) %>%
  unnest(Keyword) %>%
  mutate(
    Keyword = str_trim(Keyword),
    # Clean up any trailing punctuation
    Keyword = str_remove(Keyword, "[./]$")
  ) %>%
  filter(Keyword != "") %>%
  select(Theme_ID, Theme, Keyword)

cat("Total theme keywords to search:", nrow(theme_keywords), "\n")
print(theme_keywords, n = Inf)

# =============================================================================
# STEP 2: Load your hospital strategy data
# Assumes your dataframe is called `df` with an `Analysis_Corpus` column
# Replace this with your actual data loading step
# =============================================================================

 df <- readRDS("E:/HospitalStrategyGemini/Output/final_dataset.rds")
# OR if already loaded, just make sure it has Analysis_Corpus

# Combine all corpus text into one searchable vector (one row per strategic direction)
# Filter out NF/NA rows for cleaner counts
corpus_text <- df %>%
  filter(!is.na(Analysis_Corpus), Analysis_Corpus != "NF") %>%
  pull(Analysis_Corpus)

n_directions <- length(corpus_text)
n_hospitals  <- n_distinct(df$FAC)
cat("\nCorpus: ", n_directions, "strategic directions across", n_hospitals, "hospitals\n\n")

# =============================================================================
# STEP 3: Count keyword/phrase frequency across corpus
# =============================================================================
count_keyword <- function(keyword, corpus) {
  
  # Build the full string pattern FIRST, then apply regex() once around everything
  # This preserves ignore_case across the entire pattern including word boundaries
  pattern <- regex(
    paste0("\\b", str_escape(keyword), "\\b"),
    ignore_case = TRUE
  )
  
  n_directions_with   <- sum(str_detect(corpus, pattern), na.rm = TRUE)
  n_total_occurrences <- sum(str_count(corpus,  pattern), na.rm = TRUE)
  
  tibble(
    n_directions_with   = n_directions_with,
    n_total_occurrences = n_total_occurrences
  )
}


# Apply to all keywords — this may take a moment on large corpus
keyword_freq <- theme_keywords %>%
  mutate(
    counts = map(Keyword, ~count_keyword(.x, corpus_text))
  ) %>%
  unnest(counts) %>%
  mutate(
    pct_directions = round(100 * n_directions_with / n_directions, 1)
  )

# =============================================================================
# STEP 4: Theme-level rollup
# =============================================================================

theme_freq <- keyword_freq %>%
  group_by(Theme_ID, Theme) %>%
  summarise(
    n_keywords             = n(),
    total_occurrences      = sum(n_total_occurrences),
    directions_any_keyword = NA_integer_,  # filled below
    top_keyword            = Keyword[which.max(n_total_occurrences)],
    top_keyword_hits       = max(n_total_occurrences),
    zero_hit_keywords      = sum(n_total_occurrences == 0),
    .groups = "drop"
  )

# For "directions with any keyword in theme" we need a corpus-level check
theme_freq <- theme_freq %>%
  left_join(
    theme_keywords %>%
      group_by(Theme_ID) %>%
      summarise(all_keywords = list(Keyword)) %>%
      mutate(
        directions_any_keyword = map_int(all_keywords, function(kws) {
          # Build escaped strings first, THEN wrap combined pattern in regex()
          escaped   <- str_escape(kws)
          patterns  <- paste0("\\b", escaped, "\\b")
          combined  <- paste(patterns, collapse = "|")
          sum(str_detect(corpus_text, regex(combined, ignore_case = TRUE)), na.rm = TRUE)
        })) %>%
      select(Theme_ID, directions_any_keyword),
    by = "Theme_ID"
  ) %>%
  mutate(
    directions_any_keyword = coalesce(directions_any_keyword.y, directions_any_keyword.x),
    pct_directions_covered = round(100 * directions_any_keyword / n_directions, 1)
  ) %>%
  select(-directions_any_keyword.x, -directions_any_keyword.y) %>%
  arrange(desc(total_occurrences))

# =============================================================================
# STEP 5: Display results
# =============================================================================

cat("\n============================================================\n")
cat("THEME-LEVEL FREQUENCY SUMMARY\n")
cat("============================================================\n")
print(theme_freq %>% 
        select(Theme_ID, Theme, total_occurrences, directions_any_keyword, 
               pct_directions_covered, top_keyword, top_keyword_hits, 
               zero_hit_keywords),
      n = Inf)

cat("\n============================================================\n")
cat("KEYWORD-LEVEL FREQUENCY DETAIL\n")
cat("============================================================\n")
print(keyword_freq %>%
        arrange(Theme_ID, desc(n_total_occurrences)) %>%
        select(Theme_ID, Theme, Keyword, n_directions_with, 
               pct_directions, n_total_occurrences),
      n = Inf)

# =============================================================================
# STEP 6: Flag potential issues
# =============================================================================

cat("\n============================================================\n")
cat("DIAGNOSTIC FLAGS\n")
cat("============================================================\n")

cat("\n--- Keywords with ZERO hits (consider replacing): ---\n")
keyword_freq %>%
  filter(n_total_occurrences == 0) %>%
  select(Theme, Keyword) %>%
  print(n = Inf)

cat("\n--- Themes with majority zero-hit keywords (weak theme signal): ---\n")
theme_freq %>%
  filter(zero_hit_keywords / n_keywords >= 0.5) %>%
  select(Theme, n_keywords, zero_hit_keywords) %>%
  print(n = Inf)

cat("\n--- Top 10 highest-frequency individual keywords: ---\n")
keyword_freq %>%
  arrange(desc(n_total_occurrences)) %>%
  slice_head(n = 10) %>%
  select(Theme, Keyword, n_total_occurrences, pct_directions) %>%
  print(n = Inf)

# =============================================================================
# STEP 7: Optional — save results
# =============================================================================

# write_csv(keyword_freq,  "output/phase1_keyword_frequency.csv")
# write_csv(theme_freq,    "output/phase1_theme_frequency.csv")