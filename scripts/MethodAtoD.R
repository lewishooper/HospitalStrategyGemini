# finalize Keywords post method D
# ── Method D: Consolidated final updates to StrategicKeywordsv2 ───────────────

StrategicKeywordsv2 <- readRDS("E:/HospitalStrategyGemini/Output/StrategicKeywordsv2.rds")

# Theme 2: swap barriers → virtual
StrategicKeywordsv2 <- StrategicKeywordsv2 |>
  filter(!(Theme_ID == 2 & Word == "barriers")) |>
  bind_rows(
    tibble(Theme_ID = 2L, Theme_Name = "Access & Capacity",
           Word = "virtual", Type = "word", Rank = NA_integer_,
           Overlap_Risk = NA_character_, Overlap_Theme = NA_character_,
           n_occurrences = NA_integer_, pct_directions = NA_real_,
           Decision = "keep", Dup = FALSE, Count = NA_integer_)
  )

# Theme 4: swap healthy → wellness
StrategicKeywordsv2 <- StrategicKeywordsv2 |>
  filter(!(Theme_ID == 4 & Word == "healthy")) |>
  bind_rows(
    tibble(Theme_ID = 4L, Theme_Name = "Population & Community Health",
           Word = "wellness", Type = "word", Rank = NA_integer_,
           Overlap_Risk = NA_character_, Overlap_Theme = NA_character_,
           n_occurrences = NA_integer_, pct_directions = NA_real_,
           Decision = "keep", Dup = FALSE, Count = NA_integer_)
  )

# Theme 6: swap efficiency → investment
StrategicKeywordsv2 <- StrategicKeywordsv2 |>
  filter(!(Theme_ID == 6 & Word == "efficiency")) |>
  bind_rows(
    tibble(Theme_ID = 6L, Theme_Name = "Financial Sustainability",
           Word = "investment", Type = "word", Rank = NA_integer_,
           Overlap_Risk = NA_character_, Overlap_Theme = NA_character_,
           n_occurrences = NA_integer_, pct_directions = NA_real_,
           Decision = "keep", Dup = FALSE, Count = NA_integer_)
  )

# Theme 11: swap training → discovery
StrategicKeywordsv2 <- StrategicKeywordsv2 |>
  filter(!(Theme_ID == 11 & Word == "training")) |>
  bind_rows(
    tibble(Theme_ID = 11L, Theme_Name = "Research, Education & Academics",
           Word = "discovery", Type = "word", Rank = NA_integer_,
           Overlap_Risk = NA_character_, Overlap_Theme = NA_character_,
           n_occurrences = NA_integer_, pct_directions = NA_real_,
           Decision = "keep", Dup = FALSE, Count = NA_integer_)
  )

# ── Final sort and save ───────────────────────────────────────────────────────
StrategicKeywordsv2 <- StrategicKeywordsv2 |>
  arrange(Theme_ID, Type, Word)

saveRDS(StrategicKeywordsv2, "E:/HospitalStrategyGemini/Output/StrategicKeywordsv2.rds")
write_csv(StrategicKeywordsv2, "E:/HospitalStrategyGemini/Output/StrategicKeywordsv2.csv")

# ── Final verification table ──────────────────────────────────────────────────
StrategicKeywordsv2 |>
  filter(Decision == "keep") |>
  group_by(Theme_ID, Theme_Name) |>
  summarise(n = n(), 
            keywords = paste(sort(Word), collapse = ", "),
            .groups = "drop") |>
  print(n = 11, width = 120)