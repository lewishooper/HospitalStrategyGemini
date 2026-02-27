library(tidyverse)

# Load your keyword table and word frequency data
keywords <- read_csv("E:/HospitalStrategyGemini/Source/theme_keyword_candidates.csv")
# or however your current keyword table is structured

word_freq <- read.csv("E:/HospitalStrategyGemini/Output/corpus_word_frequency.csv")
  
keywords %>%
  filter(Decision == "keep") %>%
  select(Theme_ID, Theme_Name, Word, Type, n_occurrences, pct_directions) %>%
  arrange(Theme_ID, desc(n_occurrences)) %>%
  print(n = 100)
  
  
  str(word_freq)
  str(keywords)
  view(keywords)
  