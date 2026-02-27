# After your Excel review, load approved candidates
library(tidyverse)
keyword_candidates <- read_csv("E:/HospitalStrategyGemini/Source/theme_keyword_candidates.csv") %>%
  filter(tolower(Decision) !="drop")%>%  # or however you've flagged approvals
  rename(Theme=Theme_Name,Keywords=Word)




# Step 1: Collapse all candidate keywords to one string per theme
new_keywords_by_theme <- keyword_candidates %>%
  group_by(Theme_ID) %>%
  summarise(new_keywords = paste(Keywords, collapse = ", "), .groups = "drop")

# Step 2: Join and append to existing Keywords string
strategic_themes_updated <- strategic_themes_revised %>%
  left_join(new_keywords_by_theme, by = "Theme_ID") %>%
  mutate(
    Keywords = if_else(
      !is.na(new_keywords),
      paste(Keywords, new_keywords, sep = ", "),
      Keywords
    ),
    n_keywords_retained = str_count(Keywords, ",") + 1
  ) %>%
  select(-new_keywords)


# Confirm keyword counts increased where expected
strategic_themes_updated %>% 
  select(Theme_ID, Theme, n_keywords_retained) %>% 
  left_join(strategic_themes_revised %>% select(Theme_ID, old_count = n_keywords_retained), 
            by = "Theme_ID") %>%
  mutate(added = n_keywords_retained - old_count)
