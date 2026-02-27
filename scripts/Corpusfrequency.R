# =============================================================================
# OVERALL CORPUS WORD FREQUENCY ANALYSIS
# Strips stop words, lowercases, counts all tokens across Analysis_Corpus
# =============================================================================

library(tidyverse)
library(tidytext)
library(stringr)

# =============================================================================
# STEP 1: Prep the corpus
# =============================================================================

corpus_df <- df %>%
  filter(!is.na(Analysis_Corpus), 
         str_to_upper(Analysis_Corpus) != "NF") %>%
  select(FAC, Hospital_Name, Analysis_Corpus) %>%
  mutate(doc_id = row_number())

cat("Corpus: ", nrow(corpus_df), "strategic directions\n")
cat("Hospitals:", n_distinct(corpus_df$FAC), "\n\n")

# =============================================================================
# STEP 2: Custom additions to stop words
# =============================================================================
# tidytext's stop_words covers most common English words.
# We add healthcare/strategic plan boilerplate that adds no analytical signal.

custom_stops <- tibble(word = c(
  # Strategic plan filler
  "will", "ensure", "continue", "support", "provide", "develop",
  "improve", "enhance", "build", "work", "focus", "achieve",
  "including", "across", "based", "use", "using", "used",
  # Common healthcare boilerplate
  "care", "health", "hospital", "services", "patients", "patient",
  "team", "staff", "community", "organization", "strategic",
  # Numeric / punctuation artifacts
  "nf", "br", "1", "2", "3", "4", "5"
))

# Combined stop word list (tidytext provides ~1,000 words from multiple lexicons)
all_stops <- bind_rows(
  get_stopwords(language = "en", source = "snowball"),
  get_stopwords(language = "en", source = "stopwords-iso"),
  custom_stops
) %>%
  distinct(word)

cat("Total stop words (combined):", nrow(all_stops), "\n\n")

# =============================================================================
# STEP 3: Tokenize and clean
# =============================================================================

tokens <- corpus_df %>%
  # Lowercase everything before tokenizing so abbreviations are caught
  mutate(Analysis_Corpus = str_to_lower(Analysis_Corpus)) %>%
  
  # Remove HTML artifacts common in your corpus
  mutate(Analysis_Corpus = str_remove_all(Analysis_Corpus, "<br>|&amp;|&nbsp;")) %>%
  
  # Remove punctuation runs but KEEP hyphens (e.g. person-centred, well-being)
  mutate(Analysis_Corpus = str_remove_all(Analysis_Corpus, "[^a-z0-9\\s\\-]")) %>%
  
  # Tokenize to one word per row
  unnest_tokens(output = word, input = Analysis_Corpus, 
                token = "words",
                to_lower = TRUE) %>%     # already lowercased but belt-and-suspenders
  
  # Remove pure numeric tokens
  filter(!str_detect(word, "^\\d+$")) %>%
  
  # Remove very short tokens (single letters, most are artifacts)
  filter(str_length(word) > 1) %>%
  
  # Remove stop words
  anti_join(all_stops, by = "word")

cat("Total tokens after cleaning:", nrow(tokens), "\n")
cat("Unique words:", n_distinct(tokens$word), "\n\n")

# =============================================================================
# STEP 4: Word frequency counts
# =============================================================================

word_freq <- tokens %>%
  count(word, sort = TRUE, name = "n_occurrences") %>%
  mutate(
    rank             = row_number(),
    pct_of_tokens    = round(100 * n_occurrences / nrow(tokens), 2),
    cumulative_pct   = round(cumsum(pct_of_tokens), 1)
  )

# Also count: how many distinct strategic directions contain this word
word_direction_coverage <- tokens %>%
  distinct(doc_id, word) %>%
  count(word, name = "n_directions") %>%
  mutate(pct_directions = round(100 * n_directions / nrow(corpus_df), 1))

word_freq <- word_freq %>%
  left_join(word_direction_coverage, by = "word")

# =============================================================================
# STEP 5: Display results
# =============================================================================

cat("============================================================\n")
cat("TOP 50 WORDS IN ANALYSIS CORPUS\n")
cat("============================================================\n")
print(word_freq %>% slice_head(n = 50), n = 50)

cat("\n============================================================\n")
cat("WORDS APPEARING IN 50%+ OF STRATEGIC DIRECTIONS\n")
cat("============================================================\n")
word_freq %>%
  filter(pct_directions >= 50) %>%
  print(n = Inf)

cat("\n============================================================\n")
cat("LONG TAIL: WORDS APPEARING ONLY ONCE\n")
cat("============================================================\n")
cat("Hapax legomena (appear exactly once):", 
    sum(word_freq$n_occurrences == 1), "words\n")

cat("These represent", 
    round(100 * sum(word_freq$n_occurrences == 1) / nrow(word_freq), 1),
    "% of unique vocabulary\n\n")

# =============================================================================
# STEP 6: Save outputs
# =============================================================================

 write_csv(word_freq, "E:/HospitalStrategyGemini/Output/corpus_word_frequency.csv")

# Optional: quick visual of top 30
word_freq %>%
  slice_head(n = 30) %>%
  mutate(word = fct_reorder(word, n_occurrences)) %>%
  ggplot(aes(x = n_occurrences, y = word)) +
  geom_col(fill = "steelblue") +
  geom_text(aes(label = n_occurrences), hjust = -0.2, size = 3) +
  labs(
    title    = "Top 30 Words in Ontario Hospital Strategic Plans",
    subtitle = paste0("Corpus: ", nrow(corpus_df), " strategic directions"),
    x        = "Total Occurrences",
    y        = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.major.y = element_blank())
