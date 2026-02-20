# ============================================================
# KEYWORD VALIDITY DIAGNOSTIC
# Total occurrences of each word/phrase across all directions
# Output: Theme | Keyword | Total_Matches | Directions_Matched
# ============================================================

score_keywords <- function(df, theme_keywords) {
  
  # Ensure NF-only corpus rows are excluded
  corpus_clean <- df %>%
    filter(!is.na(Analysis_Corpus),
           str_trim(Analysis_Corpus) != "",
           !str_detect(str_trim(Analysis_Corpus), "^NF\\.?$")) %>%
    pull(Analysis_Corpus)
  
  n_directions <- length(corpus_clean)
  
  keyword_results <- map_dfr(names(theme_keywords), function(theme) {
    
    keywords <- theme_keywords[[theme]]
    
    map_dfr(keywords, function(kw) {
      
      kw_lower   <- str_to_lower(kw)
      is_phrase  <- str_detect(kw, "\\s")
      
      if (is_phrase) {
        pattern <- fixed(kw_lower)
      } else {
        pattern <- regex(paste0("\\b", regex_escape(kw_lower), "\\b"))
      }
      
      # Total occurrences across all corpus rows
      total_matches <- sum(str_count(str_to_lower(corpus_clean), pattern))
      
      # Number of distinct directions where keyword appears at least once
      directions_matched <- sum(str_detect(str_to_lower(corpus_clean), pattern))
      
      tibble(
        Theme            = theme,
        Keyword          = kw,
        Total_Matches    = total_matches,
        Directions_Matched = directions_matched,
        Pct_Directions   = round(directions_matched / n_directions * 100, 1)
      )
    })
  })
  
  return(keyword_results)
}

# ============================================================
# RUN AND VIEW
# ============================================================

keyword_validity <- score_keywords(df, theme_keywords)

# View sorted by theme, then descending matches
keyword_validity %>%
  arrange(Theme, desc(Total_Matches)) %>%
  print(n = Inf)

# Optional: flag zero-hit keywords (candidates for removal or revision)
keyword_validity %>%
  filter(Total_Matches == 0) %>%
  arrange(Theme) %>%
  print(n = Inf)

# Optional: export
# write_csv(keyword_validity %>% arrange(Theme, desc(Total_Matches)),
#           "keyword_validity_check.csv")

ThemeScores<-keyword_validity %>%
  select(Theme,Total_Matches) %>%
  group_by(Theme) %>%
  reframe(total=sum(Total_Matches))

ggplot(ThemeScores,aes(x=reorder(Theme,total),y=total))+geom_col() +coord_flip()
       