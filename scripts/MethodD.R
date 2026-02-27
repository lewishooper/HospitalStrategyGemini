#method D
# ── Method D: Domain / Synonym Expansion ─────────────────────────────────────
# Rather than corpus mining, we're checking whether established Ontario health
# sector vocabulary adds signal beyond what we already have.
# 
# Reference frameworks:
#   - Ontario Health Annual Business Plan / Strategic Plan
#   - OHA (Ontario Hospital Association) strategic priorities
#   - Ontario's Roadmap to Wellness (mental health)
#   - Connecting People to Care (home & community)
#   - Ontario Health Teams framework vocabulary

# ── Step 1: Define candidate terms from domain frameworks ────────────────────
# These are terms used in Ontario Health / OHA published documents that
# plausibly map to our under-specified themes

method_d_candidates <- tribble(
  ~Theme_ID, ~Theme_Name,                     ~Word,              ~Source,
  # Theme 2 — Access & Capacity
  2L, "Access & Capacity",                    "wait",             "Ontario Health",
  2L, "Access & Capacity",                    "navigate",         "OHA",
  2L, "Access & Capacity",                    "virtual",          "Ontario Health",
  2L, "Access & Capacity",                    "urgent",           "Ontario Health",
  2L, "Access & Capacity",                    "throughput",       "OHA",
  2L, "Access & Capacity",                    "alternate",        "Ontario Health",
  # Theme 4 — Population & Community Health
  4L, "Population & Community Health",        "chronic",          "Ontario Health",
  4L, "Population & Community Health",        "determinants",     "Ontario Health",
  4L, "Population & Community Health",        "wellness",         "OHA",
  4L, "Population & Community Health",        "screening",        "Ontario Health",
  4L, "Population & Community Health",        "upstream",         "OHA",
  4L, "Population & Community Health",        "frail",            "Ontario Health",
  # Theme 6 — Financial Sustainability
  6L, "Financial Sustainability",             "revenue",          "OHA",
  6L, "Financial Sustainability",             "reserves",         "OHA",
  6L, "Financial Sustainability",             "cost",             "Ontario Health",
  6L, "Financial Sustainability",             "investment",       "Ontario Health",
  # Theme 11 — Research Education & Academics (secondary focus)
  11L,"Research, Education & Academics",      "discovery",        "Ontario Health",
  11L,"Research, Education & Academics",      "simulation",       "OHA",
  11L,"Research, Education & Academics",      "fellowship",       "OHA"
)

# ── Step 2: Check corpus presence for each candidate ─────────────────────────
final_dataset <- readRDS("E:/HospitalStrategyGemini/Output/final_dataset.rds")

corpus_text <- str_to_lower(paste(final_dataset$Analysis_Corpus, collapse = " "))

method_d_candidates <- method_d_candidates |>
  mutate(
    n_directions = map_int(Word, ~{
      sum(str_detect(str_to_lower(final_dataset$Analysis_Corpus),
                     paste0("\\b", .x, "\\b")), na.rm = TRUE)
    }),
    pct_directions = round(n_directions / nrow(final_dataset) * 100, 1)
  )

# ── Step 3: Review results ────────────────────────────────────────────────────
method_d_candidates |>
  arrange(Theme_ID, desc(n_directions)) |>
  print(n = 30)

write_csv(method_d_candidates, 
          "E:/HospitalStrategyGemini/Output/method_d_candidates.csv")