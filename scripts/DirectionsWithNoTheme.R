#No matches in plans and keywords
library(tidyverse)

final_dataset     <- readRDS("E:/HospitalStrategyGemini/Output/final_dataset.rds")
StrategicKeywords <- readRDS("E:/HospitalStrategyGemini/Output/StrategicKeywordsv2.rds")

# ── Build keyword lists: separate unigrams and bigrams ───────────────────────
keywords_unigram <- StrategicKeywords |>
  filter(Decision == "keep", Type == "word") |>
  pull(Word)

keywords_bigram <- StrategicKeywords |>
  filter(Decision == "keep", Type == "bigram") |>
  pull(Word)

# ── Match function: returns TRUE if any keyword found in text ────────────────
has_match <- function(text, unigrams, bigrams) {
  text_lower <- str_to_lower(text)
  
  # Check bigrams first (exact phrase match)
  bigram_match <- any(str_detect(text_lower, 
                                 fixed(bigrams)), na.rm = TRUE)
  
  # Check unigrams as whole words
  unigram_match <- any(str_detect(text_lower, 
                                  paste0("\\b", unigrams, "\\b")), na.rm = TRUE)
  
  bigram_match | unigram_match
}

# ── Apply to corpus ───────────────────────────────────────────────────────────
final_dataset <- final_dataset |>
  mutate(
    any_match = map_lgl(Analysis_Corpus, 
                        ~has_match(.x, keywords_unigram, keywords_bigram))
  )

# ── Summary ───────────────────────────────────────────────────────────────────
match_summary <- final_dataset |>
  count(any_match) |>
  mutate(pct = round(n / sum(n) * 100, 1))

print(match_summary)

# ── Extract unmatched directions for review ───────────────────────────────────
unmatched <- final_dataset |>
  filter(!any_match) |>
  select(FAC, Analysis_Corpus)

cat("\nUnmatched directions:", nrow(unmatched), "of", nrow(final_dataset), "\n")

# ── Save for review ───────────────────────────────────────────────────────────
write_csv(unmatched, "E:/HospitalStrategyGemini/Output/method_c_unmatched.csv")

# ── Quick word frequency on unmatched text — reveals vocabulary gaps ──────────
library(tidytext)

unmatched_freq <- unmatched |>
  unnest_tokens(word, Analysis_Corpus) |>
  filter(!word %in% stop_words$word,
         !word %in% c("hospital", "health", "care", "will", "our", "we"),
         nchar(word) > 2) |>
  count(word, sort = TRUE) |>
  slice_head(n = 50)

print(unmatched_freq, n = 50)

write_csv(unmatched_freq, "E:/HospitalStrategyGemini/Output/method_c_unmatched_freq.csv")