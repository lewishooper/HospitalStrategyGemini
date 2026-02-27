library(tidyverse)
library(tidytext)
library(textstem)

# ── Step 1: Prepare theme keywords — separate string into long format ─────────
theme_keywords <- strategic_themes_updated %>%
  select(Theme_ID, Theme, Keywords) %>%
  separate_rows(Keywords, sep = ",\\s*") %>%
  mutate(keyword_lemma = lemmatize_words(str_to_lower(Keywords))) %>%
  filter(!str_detect(keyword_lemma, "\\s")) %>%   # single-word only
  select(Theme_ID, Theme, keyword_lemma) %>%
  distinct()

# ── Step 2: Corpus word count per direction (raw, pre-processing) ─────────────
corpus_length <- df %>%
  select(FAC, Direction, Analysis_Corpus) %>%
  unnest_tokens(word, Analysis_Corpus) %>%
  count(FAC, Direction, name = "corpus_wordcount")

# ── Step 3: Tokenize, lemmatize, remove stop words ───────────────────────────
corpus_tokens <- df %>%
  select(FAC, Direction, Analysis_Corpus) %>%
  unnest_tokens(word, Analysis_Corpus) %>%
  anti_join(stop_words, by = "word") %>%
  mutate(word_lemma = lemmatize_words(word))

# ── Step 4: Match tokens against theme keywords ───────────────────────────────
theme_scores_long <- corpus_tokens %>%
  inner_join(theme_keywords, by = c("word_lemma" = "keyword_lemma"),
             relationship = "many-to-many") %>%
  count(FAC, Direction, Theme, name = "raw_count")

# ── Step 5: Pivot wide — one column per theme ─────────────────────────────────
theme_scores_wide <- theme_scores_long %>%
  pivot_wider(
    names_from  = Theme,
    values_from = raw_count,
    values_fill = 0,
    names_prefix = "raw_"
  )

# ── Step 6: Join back to df, compute normalized scores ───────────────────────
df_baseline <- df %>%
  left_join(corpus_length, by = c("FAC", "Direction")) %>%
  left_join(theme_scores_wide, by = c("FAC", "Direction")) %>%
  mutate(across(starts_with("raw_"), ~replace_na(., 0))) %>%
  mutate(across(
    starts_with("raw_"),
    ~ round(. / corpus_wordcount * 1000, 2),
    .names = "{str_replace(.col, 'raw_', 'n1k_')}"
  )) %>%
  mutate(short_corpus_flag = corpus_wordcount < 20)

# ── Step 7: Save baseline ─────────────────────────────────────────────────────
write_csv(df_baseline, "phase1_theme_scores_baseline_v1.csv")