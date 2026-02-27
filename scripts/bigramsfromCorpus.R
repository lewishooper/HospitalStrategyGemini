library(tidytext)
library(tidyverse)
#rm(list=ls())
df<-readRDS("E:/HospitalStrategyGemini/Output/final_dataset.rds")

# Generate bigrams from hospital_df
# Using the same source column as your unigrams
bigrams <- df %>%
  select(FAC, Analysis_Corpus) %>%
  unnest_tokens(bigram, Analysis_Corpus, token = "ngrams", n = 2) %>%
  filter(!is.na(bigram)) %>%
  
  # Split bigram into two words for stop word filtering
  separate(bigram, into = c("word1", "word2"), sep = " ", remove = FALSE) %>%
  
  # Remove if EITHER word is a stop word
  filter(!word1 %in% stop_words$word) %>%
  filter(!word2 %in% stop_words$word) %>%
  
  # Remove if either word is in your custom healthcare boilerplate list
  # (use the same custom list you applied to unigrams)
  # filter(!word1 %in% custom_stopwords) %>%
  # filter(!word2 %in% custom_stopwords) %>%
  
  # Reunite for counting
  unite(bigram, word1, word2, sep = " ") %>%
  
  # Count occurrences and direction-level coverage
  group_by(bigram) %>%
  summarise(
    n_total_occurrences = n(),
    n_directions_with   = n_distinct(FAC),   # unique hospitals, or use row ID if you want unique directions
    .groups = "drop"
  ) %>%
  mutate(pct_directions = round(n_directions_with / n_distinct(df$FAC) * 100, 1)) %>%
  arrange(desc(n_total_occurrences)) %>%
  mutate(rank = row_number()) %>%
  select(rank, bigram, n_total_occurrences, n_directions_with, pct_directions)

# Print top 200
write_csv(head(bigrams,100),"E:/HospitalStrategyGemini/Output/bigrams100.csv")

