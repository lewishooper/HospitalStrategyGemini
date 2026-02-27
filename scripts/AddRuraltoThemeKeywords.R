StrategicKeywordsv2 <- readRDS("E:/HospitalStrategyGemini/Output/StrategicKeywordsv2.rds") %>%
  filter(Word!="rural")

StrategicKeywordsv2 <- StrategicKeywordsv2 |>
  bind_rows(
    tibble(Theme_ID = 4L, Theme_Name = "Population & Community Health",
           Word = "rural", Type = "word", Rank = NA_integer_,
           Overlap_Risk = NA_character_, Overlap_Theme = NA_character_,
           n_occurrences = NA_integer_, pct_directions = NA_real_,
           Decision = "keep", Dup = FALSE, Count = NA_integer_)
  ) |>
  arrange(Theme_ID, Type, Word)

saveRDS(StrategicKeywordsv2, "E:/HospitalStrategyGemini/Output/StrategicKeywordsv2.rds")
write_csv(StrategicKeywordsv2, "E:/HospitalStrategyGemini/Output/StrategicKeywordsv2.csv")

# Confirm Theme 4 count
StrategicKeywordsv2 |> filter(Theme_ID == 4, Decision == "keep") |> count()
