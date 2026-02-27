# Diagnose the Keywords column
strategic_themes_revised %>%
  mutate(keyword_lower = str_to_lower(str_trim(Keywords))) %>%
  select(keyword_lower) %>%
  mutate(
    has_space    = str_detect(keyword_lower, "\\s"),
    nchar        = nchar(keyword_lower),
    first_5chars = str_sub(keyword_lower, 1, 5)
  ) %>%
  print(n = 30)


# Print top 200 words with rank - we'll use this as our mining pool
ts<-word_freq %>%
  arrange(rank) %>%
  select(word, rank, n_occurrences, pct_directions) %>%
  head(200)



library(tibble)

# Build comprehensive candidate table - all 11 themes
# Columns: Theme_ID, Theme_Name, Word, Type, Rank, n_occurrences, 
#          pct_directions, Overlap_Risk, Overlap_Theme, Decision

candidates <- tribble(
  ~Theme_ID, ~Theme_Name,                          ~Word,            ~Type,              ~Rank, ~Overlap_Risk, ~Overlap_Theme,
  
  # Theme 1 - Patient Care Excellence
  1, "Patient Care Excellence",                    "quality",        "candidate",        1,     "low",         NA,
  1, "Patient Care Excellence",                    "safety",         "existing_keyword", 8,     "low",         NA,
  1, "Patient Care Excellence",                    "safe",           "candidate",        16,    "low",         NA,
  1, "Patient Care Excellence",                    "experience",     "candidate",        5,     "medium",      "Theme 10 - Culture",
  1, "Patient Care Excellence",                    "excellence",     "candidate",        35,    "low",         NA,
  1, "Patient Care Excellence",                    "outcomes",       "candidate",        27,    "low",         NA,
  1, "Patient Care Excellence",                    "clinical",       "candidate",        24,    "medium",      "Theme 11 - Research",
  1, "Patient Care Excellence",                    "improvement",    "candidate",        36,    "low",         NA,
  1, "Patient Care Excellence",                    "centred",        "candidate",        79,    "low",         NA,
  1, "Patient Care Excellence",                    "person",         "candidate",        88,    "low",         NA,
  
  # Theme 2 - Access & Capacity
  2, "Access & Capacity",                          "access",         "candidate",        7,     "low",         NA,
  2, "Access & Capacity",                          "capacity",       "candidate",        55,    "low",         NA,
  2, "Access & Capacity",                          "timely",         "candidate",        133,   "low",         NA,
  2, "Access & Capacity",                          "expand",         "candidate",        66,    "medium",      "Multiple themes",
  2, "Access & Capacity",                          "transitions",    "candidate",        154,   "medium",      "Theme 8 - Integration",
  
  # Theme 3 - Health Equity & Social Accountability
  3, "Health Equity & Social Accountability",      "equity",         "candidate",        15,    "low",         NA,
  3, "Health Equity & Social Accountability",      "indigenous",     "existing_keyword", 60,    "low",         NA,
  3, "Health Equity & Social Accountability",      "diversity",      "candidate",        30,    "low",         NA,
  3, "Health Equity & Social Accountability",      "inclusion",      "candidate",        45,    "low",         NA,
  3, "Health Equity & Social Accountability",      "inclusive",      "candidate",        54,    "low",         NA,
  3, "Health Equity & Social Accountability",      "diverse",        "candidate",        62,    "low",         NA,
  3, "Health Equity & Social Accountability",      "equitable",      "candidate",        69,    "low",         NA,
  3, "Health Equity & Social Accountability",      "belonging",      "candidate",        150,   "low",         NA,
  3, "Health Equity & Social Accountability",      "reconciliation", "candidate",        172,   "medium",      "Theme 4 - Population",
  3, "Health Equity & Social Accountability",      "culturally",     "candidate",        185,   "low",         NA,
  3, "Health Equity & Social Accountability",      "social",         "candidate",        85,    "medium",      "Theme 4 - Population",
  
  # Theme 4 - Population & Community Health
  4, "Population & Community Health",              "communities",    "candidate",        11,    "low",         NA,
  4, "Population & Community Health",              "mental",         "candidate",        49,    "low",         NA,
  4, "Population & Community Health",              "population",     "candidate",        97,    "low",         NA,
  4, "Population & Community Health",              "healthy",        "candidate",        94,    "medium",      "Theme 5 - Workforce",
  4, "Population & Community Health",              "populations",    "candidate",        162,   "low",         NA,
  4, "Population & Community Health",              "primary",        "candidate",        153,   "low",         NA,
  4, "Population & Community Health",              "social",         "candidate",        85,    "medium",      "Theme 3 - Equity",
  
  # Theme 5 - Workforce Sustainability
  5, "Workforce Sustainability",                   "recruitment",    "existing_keyword", 119,   "low",         NA,
  5, "Workforce Sustainability",                   "retention",      "existing_keyword", 173,   "low",         NA,
  5, "Workforce Sustainability",                   "wellness",       "existing_keyword", 89,    "low",         NA,
  5, "Workforce Sustainability",                   "people",         "candidate",        2,     "medium",      "Generic",
  5, "Workforce Sustainability",                   "leadership",     "candidate",        31,    "medium",      "Theme 10 - Culture",
  5, "Workforce Sustainability",                   "workforce",      "candidate",        92,    "low",         NA,
  5, "Workforce Sustainability",                   "teams",          "candidate",        43,    "low",         NA,
  5, "Workforce Sustainability",                   "talent",         "candidate",        197,   "low",         NA,
  5, "Workforce Sustainability",                   "attract",        "candidate",        184,   "low",         NA,
  5, "Workforce Sustainability",                   "retain",         "candidate",        136,   "low",         NA,
  5, "Workforce Sustainability",                   "workplace",      "candidate",        103,   "low",         NA,
  
  # Theme 6 - Financial Sustainability
  6, "Financial Sustainability",                   "efficiency",     "existing_keyword", 139,   "low",         NA,
  6, "Financial Sustainability",                   "financial",      "candidate",        42,    "low",         NA,
  6, "Financial Sustainability",                   "funding",        "candidate",        113,   "low",         NA,
  6, "Financial Sustainability",                   "sustainability", "candidate",        58,    "high",        "Theme 9 - Infrastructure",
  6, "Financial Sustainability",                   "resources",      "candidate",        18,    "medium",      "Generic",
  6, "Financial Sustainability",                   "operational",    "candidate",        104,   "low",         NA,
  6, "Financial Sustainability",                   "responsible",    "candidate",        163,   "low",         NA,
  
  # Theme 7 - Digital Health & Innovation
  7, "Digital Health & Innovation",                "innovation",     "candidate",        14,    "low",         NA,
  7, "Digital Health & Innovation",                "technology",     "candidate",        38,    "low",         NA,
  7, "Digital Health & Innovation",                "data",           "candidate",        41,    "low",         NA,
  7, "Digital Health & Innovation",                "digital",        "candidate",        64,    "low",         NA,
  7, "Digital Health & Innovation",                "innovative",     "candidate",        37,    "low",         NA,
  7, "Digital Health & Innovation",                "systems",        "candidate",        110,   "medium",      "Generic",
  7, "Digital Health & Innovation",                "tools",          "candidate",        107,   "medium",      "Generic",
  7, "Digital Health & Innovation",                "emr",            "existing_keyword", 1811,  "low",         NA,
  
  # Theme 8 - Integration & Partnerships
  8, "Integration & Partnerships",                 "partners",       "candidate",        3,     "low",         NA,
  8, "Integration & Partnerships",                 "partnerships",   "candidate",        6,     "low",         NA,
  8, "Integration & Partnerships",                 "integrated",     "candidate",        26,    "low",         NA,
  8, "Integration & Partnerships",                 "collaboration",  "candidate",        59,    "low",         NA,
  8, "Integration & Partnerships",                 "collaborate",    "candidate",        74,    "low",         NA,
  8, "Integration & Partnerships",                 "integration",    "candidate",        95,    "low",         NA,
  8, "Integration & Partnerships",                 "collaborative",  "candidate",        124,   "low",         NA,
  8, "Integration & Partnerships",                 "partner",        "candidate",        126,   "low",         NA,
  8, "Integration & Partnerships",                 "partnership",    "candidate",        145,   "low",         NA,
  8, "Integration & Partnerships",                 "relationships",  "candidate",        147,   "medium",      "Theme 5 - Workforce",
  8, "Integration & Partnerships",                 "transitions",    "candidate",        154,   "medium",      "Theme 2 - Access",
  8, "Integration & Partnerships",                 "continuum",      "candidate",        200,   "medium",      "Theme 2 - Access",
  8, "Integration & Partnerships",                 "regional",       "candidate",        98,    "low",         NA,
  
  # Theme 9 - Infrastructure & Environment
  9, "Infrastructure & Environment",               "infrastructure", "candidate",        51,    "low",         NA,
  9, "Infrastructure & Environment",               "environment",    "candidate",        28,    "medium",      "Theme 10 - Culture",
  9, "Infrastructure & Environment",               "equipment",      "candidate",        141,   "low",         NA,
  9, "Infrastructure & Environment",               "environmental",  "candidate",        151,   "low",         NA,
  9, "Infrastructure & Environment",               "capital",        "candidate",        155,   "low",         NA,
  9, "Infrastructure & Environment",               "physical",       "candidate",        158,   "low",         NA,
  9, "Infrastructure & Environment",               "facilities",     "existing_keyword", 188,   "low",         NA,
  9, "Infrastructure & Environment",               "sustainability", "candidate",        58,    "high",        "Theme 6 - Financial",
  9, "Infrastructure & Environment",               "building",       "candidate",        123,   "low",         NA,
  
  # Theme 10 - Organizational Culture & Governance
  10, "Organizational Culture & Governance",       "culture",        "candidate",        4,     "low",         NA,
  10, "Organizational Culture & Governance",       "governance",     "existing_keyword", 288,   "low",         NA,
  10, "Organizational Culture & Governance",       "accountability", "existing_keyword", 93,    "low",         NA,
  10, "Organizational Culture & Governance",       "values",         "candidate",        160,   "low",         NA,
  10, "Organizational Culture & Governance",       "organizational", "candidate",        117,   "low",         NA,
  10, "Organizational Culture & Governance",       "learning",       "candidate",        29,    "medium",      "Theme 11 - Research",
  10, "Organizational Culture & Governance",       "leadership",     "candidate",        31,    "medium",      "Theme 5 - Workforce",
  10, "Organizational Culture & Governance",       "engagement",     "candidate",        44,    "low",         NA,
  
  # Theme 11 - Research, Education & Academics
  11, "Research, Education & Academics",           "education",      "candidate",        39,    "low",         NA,
  11, "Research, Education & Academics",           "academic",       "candidate",        122,   "low",         NA,
  11, "Research, Education & Academics",           "knowledge",      "candidate",        116,   "medium",      "Generic",
  11, "Research, Education & Academics",           "medical",        "candidate",        157,   "medium",      "Theme 1 - Patient Care",
  11, "Research, Education & Academics",           "learning",       "candidate",        29,    "medium",      "Theme 10 - Culture",
  11, "Research, Education & Academics",           "training",       "candidate",        76,    "medium",      "Theme 5 - Workforce"
)

# Join frequency data from word_freq
candidates_with_freq <- candidates %>%
  left_join(
    word_freq %>% select(word, n_occurrences, pct_directions),
    by = c("Word" = "word")
  ) %>%
  mutate(Decision = NA_character_)   # blank column for your Excel review

# Export to CSV
write_csv(candidates_with_freq, "E:/HospitalStrategyGemini/Output/theme_keyword_candidates.csv")

cat("Exported", nrow(candidates_with_freq), "candidate rows across 11 themes\n")
