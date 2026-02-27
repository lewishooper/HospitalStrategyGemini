# ── Consolidated StrategicKeywordsv2 updates ─────────────────────────────────

StrategicKeywordsv2 <- readRDS("E:/HospitalStrategyGemini/Output/StrategicKeywordsv2.rds")

# Theme 3: swap belonging → reconciliation
StrategicKeywordsv2 <- StrategicKeywordsv2 |>
  filter(!(Theme_ID == 3 & Word == "belonging")) |>
  bind_rows(
    tibble(Theme_ID = 3L, Theme_Name = "Health Equity & Social Accountability",
           Word = "reconciliation", Type = "word", Rank = NA_integer_,
           Overlap_Risk = NA_character_, Overlap_Theme = NA_character_,
           n_occurrences = NA_integer_, pct_directions = NA_real_,
           Decision = "keep", Dup = FALSE, Count = NA_integer_)
  )

# Theme 5: add well-being
StrategicKeywordsv2 <- StrategicKeywordsv2 |>
  bind_rows(
    tibble(Theme_ID = 5L, Theme_Name = "Workforce Sustainability",
           Word = "well-being", Type = "word", Rank = NA_integer_,
           Overlap_Risk = NA_character_, Overlap_Theme = NA_character_,
           n_occurrences = NA_integer_, pct_directions = NA_real_,
           Decision = "keep", Dup = FALSE, Count = NA_integer_)
  )

# Theme 7: add analytics
StrategicKeywordsv2 <- StrategicKeywordsv2 |>
  bind_rows(
    tibble(Theme_ID = 7L, Theme_Name = "Digital Health & Innovation",
           Word = "analytics", Type = "word", Rank = NA_integer_,
           Overlap_Risk = NA_character_, Overlap_Theme = NA_character_,
           n_occurrences = NA_integer_, pct_directions = NA_real_,
           Decision = "keep", Dup = FALSE, Count = NA_integer_)
  )

# Theme 9: add physical and capital (capital flagged for overlap)
StrategicKeywordsv2 <- StrategicKeywordsv2 |>
  bind_rows(
    tibble(Theme_ID = 9L, Theme_Name = "Infrastructure & Environment",
           Word = c("physical", "capital"),
           Type = "word", Rank = NA_integer_,
           Overlap_Risk  = c(NA_character_, "moderate"),
           Overlap_Theme = c(NA_character_, "6"),
           n_occurrences = NA_integer_, pct_directions = NA_real_,
           Decision = "keep", Dup = FALSE, Count = NA_integer_)
  )

# Theme 10: add leadership (flagged for overlap) and transparency
StrategicKeywordsv2 <- StrategicKeywordsv2 |>
  bind_rows(
    tibble(Theme_ID = 10L, Theme_Name = "Organizational Culture & Governance",
           Word = c("leadership", "transparency"),
           Type = "word", Rank = NA_integer_,
           Overlap_Risk  = c("moderate", NA_character_),
           Overlap_Theme = c("5",        NA_character_),
           n_occurrences = NA_integer_, pct_directions = NA_real_,
           Decision = "keep", Dup = FALSE, Count = NA_integer_)
  )

# Theme 11: add knowledge
StrategicKeywordsv2 <- StrategicKeywordsv2 |>
  bind_rows(
    tibble(Theme_ID = 11L, Theme_Name = "Research, Education & Academics",
           Word = "knowledge", Type = "word", Rank = NA_integer_,
           Overlap_Risk = NA_character_, Overlap_Theme = NA_character_,
           n_occurrences = NA_integer_, pct_directions = NA_real_,
           Decision = "keep", Dup = FALSE, Count = NA_integer_)
  )

# Theme 2, 4, 6: add the priority theme expansions from earlier
new_priority <- tribble(
  ~Theme_ID, ~Theme_Name,                        ~Word,
  2L, "Access & Capacity",                       "mental",
  2L, "Access & Capacity",                       "flow",
  2L, "Access & Capacity",                       "barriers",
  4L, "Population & Community Health",           "aging",
  4L, "Population & Community Health",           "prevention",
  4L, "Population & Community Health",           "vulnerable",
  6L, "Financial Sustainability",                "stewardship",
  6L, "Financial Sustainability",                "fiscal",
  6L, "Financial Sustainability",                "resources"
) |>
  mutate(Type = "word", Rank = NA_integer_,
         Overlap_Risk = NA_character_, Overlap_Theme = NA_character_,
         n_occurrences = NA_integer_, pct_directions = NA_real_,
         Decision = "keep", Dup = FALSE, Count = NA_integer_)

StrategicKeywordsv2 <- bind_rows(StrategicKeywordsv2, new_priority) |>
  arrange(Theme_ID, Type, Word)

# ── Verify counts per theme ───────────────────────────────────────────────────
StrategicKeywordsv2 |>
  filter(Decision == "keep") |>
  count(Theme_ID, Theme_Name) |>
  print(n = 11)

# ── Save ──────────────────────────────────────────────────────────────────────
saveRDS(StrategicKeywordsv2, "E:/HospitalStrategyGemini/Output/StrategicKeywordsv2.rds")
write_csv(StrategicKeywordsv2, "E:/HospitalStrategyGemini/Output/StrategicKeywordsv2.csv")

cat("Saved. Rows:", nrow(StrategicKeywordsv2), "\n")