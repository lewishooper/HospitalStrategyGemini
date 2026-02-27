library(tidyverse)
library(quanteda)

# ── Load data ─────────────────────────────────────────────────────────────────
final_dataset     <- readRDS("E:/HospitalStrategyGemini/Output/final_dataset.rds")
StrategicKeywords <- readRDS("E:/HospitalStrategyGemini/Output/StrategicKeywordsv2.rds")

# ── Build corpus and tokens object ───────────────────────────────────────────
corp <- corpus(final_dataset, text_field = "Analysis_Corpus")
toks <- tokens(corp,
               remove_punct = TRUE,
               remove_numbers = TRUE,
               remove_symbols = TRUE) |>
  tokens_tolower()

# ── KWIC helper: get context words around a keyword ──────────────────────────
# Returns ranked frequency of words appearing within `window` tokens of keyword
get_context_words <- function(toks, keyword, window = 10, top_n = 30) {
  
  # Handle bigrams by converting to phrase pattern
  if (str_detect(keyword, " ")) {
    pat <- phrase(str_split(keyword, " ")[[1]])
  } else {
    pat <- keyword
  }
  
  kw <- kwic(toks, pattern = pat, window = window)
  
  if (nrow(kw) == 0) {
    message("No matches found for: ", keyword)
    return(tibble(word = character(), n = integer(), keyword = character()))
  }
  
  # Combine pre and post context, tokenize, count
  context_text <- c(kw$pre, kw$post)
  context_words <- unlist(str_split(str_to_lower(context_text), "\\s+"))
  
  # Remove stopwords and the keyword itself
  stopwords_en <- c(stopwords("en"), str_split(keyword, " ")[[1]],
                    "hospital", "health", "care", "will", "our", "we",
                    "the", "and", "for", "that", "with", "this", "are",
                    "been", "have", "from", "which", "their", "they")
  
  tibble(word = context_words) |>
    filter(!word %in% stopwords_en, nchar(word) > 2) |>
    count(word, sort = TRUE) |>
    slice_head(n = top_n) |>
    mutate(keyword = keyword)
}

# ── Run for priority under-specified themes (2, 4, 6) first ──────────────────
priority_keywords <- StrategicKeywords |>
  filter(Theme_ID %in% c(2, 4, 6), Decision == "keep") |>
  pull(Word)

kwic_results_priority <- map_dfr(priority_keywords, 
                                 ~get_context_words(toks, .x, window = 10))

# ── View results by theme ─────────────────────────────────────────────────────
# Theme 2 — Access & Capacity
Kwic30<-kwic_results_priority |>
  filter(keyword %in% filter(StrategicKeywords, Theme_ID == 2)$Word) |>
  count(word, wt = n, sort = TRUE) |>
  slice_head(n = 30) |>
  print()

# Theme 4 — Population & Community Health
kwic_results_priority |>
  filter(keyword %in% filter(StrategicKeywords, Theme_ID == 4)$Word) |>
  count(word, wt = n, sort = TRUE) |>
  slice_head(n = 30) |>
  print()

# Theme 6 — Financial Sustainability
kwic_results_priority |>
  filter(keyword %in% filter(StrategicKeywords, Theme_ID == 6)$Word) |>
  count(word, wt = n, sort = TRUE) |>
  slice_head(n = 30) |>
  print()

# ── Save priority results ─────────────────────────────────────────────────────
write_csv(kwic_results_priority, 
          "E:/HospitalStrategyGemini/Output/kwic_priority_themes_246.csv")


### ends top 3
## begins remaining 8

remaining_keywords <- StrategicKeywords |>
  filter(Theme_ID %in% c(1, 3, 5, 7, 8, 9, 10, 11), Decision == "keep") |>
  pull(Word)

kwic_results_remaining <- map_dfr(remaining_keywords,
                                  ~get_context_words(toks, .x, window = 10))

# Print all 30 for each theme
for (tid in c(1, 3, 5, 7, 8, 9, 10, 11)) {
  theme_words <- StrategicKeywords |> filter(Theme_ID == tid) |> pull(Word)
  theme_name  <- StrategicKeywords |> filter(Theme_ID == tid) |> pull(Theme_Name) |> unique()
  cat("\n\n── Theme", tid, "—", theme_name[1], "──\n")
  kwic_results_remaining |>
    filter(keyword %in% theme_words) |>
    count(word, wt = n, sort = TRUE) |>
    slice_head(n = 30) |>
    print(n = 30)
}

# Save
write_csv(kwic_results_remaining,
          "E:/HospitalStrategyGemini/Output/kwic_remaining_themes.csv")
