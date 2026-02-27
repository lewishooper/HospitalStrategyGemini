#Build New Strategy Theme Keywords
# Based on review of frequencies of words and bigrams in the final_dataset.rds
library(tidyverse)
#rm(list=ls())
# ── Build the keyword definitions from the Session 3 finalized table ──────────
# Type: "word" = single token; "bigram" = two-token phrase (added this session)
# Bold items in the summary = newly added bigrams → Type = "bigram"

keyword_defs <- tribble(
  ~Theme_ID, ~Theme_Name,                          ~Word,                    ~Type,
  1L, "Patient Care Excellence",                   "quality",                "word",
  1L, "Patient Care Excellence",                   "safety",                 "word",
  1L, "Patient Care Excellence",                   "safe",                   "word",
  1L, "Patient Care Excellence",                   "clinical",               "word",
  1L, "Patient Care Excellence",                   "outcomes",               "word",
  1L, "Patient Care Excellence",                   "improvement",            "word",
  1L, "Patient Care Excellence",                   "patient care",           "bigram",
  1L, "Patient Care Excellence",                   "patient experience",     "bigram",
  2L, "Access & Capacity",                         "transitions",            "word",
  2L, "Access & Capacity",                         "expand",                 "word",
  2L, "Access & Capacity",                         "access",                 "word",
  2L, "Access & Capacity",                         "capacity",               "word",
  2L, "Access & Capacity",                         "timely",                 "word",
  3L, "Health Equity & Social Accountability",     "equity",                 "word",
  3L, "Health Equity & Social Accountability",     "diversity",              "word",
  3L, "Health Equity & Social Accountability",     "inclusion",              "word",
  3L, "Health Equity & Social Accountability",     "indigenous",             "word",
  3L, "Health Equity & Social Accountability",     "equitable",              "word",
  3L, "Health Equity & Social Accountability",     "belonging",              "word",
  3L, "Health Equity & Social Accountability",     "health equity",          "bigram",
  3L, "Health Equity & Social Accountability",     "anti racism",            "bigram",
  4L, "Population & Community Health",             "communities",            "word",
  4L, "Population & Community Health",             "healthy",                "word",
  4L, "Population & Community Health",             "population",             "word",
  4L, "Population & Community Health",             "primary",                "word",
  4L, "Population & Community Health",             "populations",            "word",
  5L, "Workforce Sustainability",                  "teams",                  "word",
  5L, "Workforce Sustainability",                  "workforce",              "word",
  5L, "Workforce Sustainability",                  "workplace",              "word",
  5L, "Workforce Sustainability",                  "recruitment",            "word",
  5L, "Workforce Sustainability",                  "retain",                 "word",
  5L, "Workforce Sustainability",                  "retention",              "word",
  5L, "Workforce Sustainability",                  "professional development","bigram",
  6L, "Financial Sustainability",                  "financial",              "word",
  6L, "Financial Sustainability",                  "sustainability",         "word",
  6L, "Financial Sustainability",                  "operational",            "word",
  6L, "Financial Sustainability",                  "funding",                "word",
  6L, "Financial Sustainability",                  "efficiency",             "word",
  7L, "Digital Health & Innovation",               "innovation",             "word",
  7L, "Digital Health & Innovation",               "innovative",             "word",
  7L, "Digital Health & Innovation",               "data",                   "word",
  7L, "Digital Health & Innovation",               "digital",                "word",
  7L, "Digital Health & Innovation",               "systems",                "word",
  7L, "Digital Health & Innovation",               "digital health",         "bigram",
  7L, "Digital Health & Innovation",               "artificial intelligence","bigram",
  8L, "Integration & Partnerships",                "partners",               "word",
  8L, "Integration & Partnerships",                "partnerships",           "word",
  8L, "Integration & Partnerships",                "integrated",             "word",
  8L, "Integration & Partnerships",                "collaboration",          "word",
  8L, "Integration & Partnerships",                "integration",            "word",
  8L, "Integration & Partnerships",                "collaborative",          "word",
  8L, "Integration & Partnerships",                "integrated care",        "bigram",
  8L, "Integration & Partnerships",                "community partners",     "bigram",
  9L, "Infrastructure & Environment",              "infrastructure",         "word",
  9L, "Infrastructure & Environment",              "building",               "word",
  9L, "Infrastructure & Environment",              "equipment",              "word",
  9L, "Infrastructure & Environment",              "environmental",          "word",
  9L, "Infrastructure & Environment",              "facilities",             "word",
  10L,"Organizational Culture & Governance",       "culture",                "word",
  10L,"Organizational Culture & Governance",       "engagement",             "word",
  10L,"Organizational Culture & Governance",       "accountability",         "word",
  10L,"Organizational Culture & Governance",       "organizational",         "word",
  10L,"Organizational Culture & Governance",       "values",                 "word",
  10L,"Organizational Culture & Governance",       "governance",             "word",
  11L,"Research, Education & Academics",           "learning",               "word",
  11L,"Research, Education & Academics",           "training",               "word",
  11L,"Research, Education & Academics",           "education",              "word",
  11L,"Research, Education & Academics",           "academic",               "word",
  11L,"Research, Education & Academics",           "research innovation",    "bigram",
  11L,"Research, Education & Academics",           "academic health",        "bigram",
  11L,"Research, Education & Academics",           "clinical research",      "bigram"
)

# ── Add remaining schema columns to match existing `keywords` structure ───────
# Columns: Theme_ID, Theme_Name, Word, Type, Rank, Overlap_Risk, Overlap_Theme,
#          n_occurrences, pct_directions, Decision, Dup, Count
# Frequency stats (n_occurrences, pct_directions, Count) left NA here —
# they should be joined from word_freq after loading final_dataset.rds

StrategicKeywordsv2 <- keyword_defs |>
  mutate(
    Rank          = row_number(),
    Overlap_Risk  = NA_character_,
    Overlap_Theme = NA_character_,
    n_occurrences = NA_integer_,
    pct_directions= NA_real_,
    Decision      = "keep",
    Dup           = FALSE,
    Count         = NA_integer_
  ) |>
  select(Theme_ID, Theme_Name, Word, Type, Rank, Overlap_Risk, Overlap_Theme,
         n_occurrences, pct_directions, Decision, Dup, Count)

# ── Save ──────────────────────────────────────────────────────────────────────
saveRDS(StrategicKeywordsv2, "E:/HospitalStrategyGemini/Output/StrategicKeywordsv2.rds")

# Quick check
StrategicKeywordsv2 |> count(Theme_ID, Theme_Name) |> print(n = 11)
