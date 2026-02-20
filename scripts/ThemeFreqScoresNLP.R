# ============================================================
# Phase 1: Theme Keyword Frequency Scoring
# Hospital Strategic Plans - Ontario
# ============================================================
#rm(list=ls())
library(tidyverse)
library(tidytext)
library(textstem)      # for lemmatize_words()
library(SnowballC)     # for wordStem()
library(stringr)

# ============================================================
# STEP 1: Define Theme Keywords
# Tokenized from the "Include" column of the theme table
# ============================================================

theme_keywords <- list(
  WORKFORCE_SUSTAINABILITY = c(
    "recruitment", "recruit", "retention", "retain", "burnout", "wellness",
    "leadership", "development", "staff", "workforce", "staffing",
    "human resources", "hhr", "health human resources", "well-being", "wellbeing",
    "psychological safety", "recognition", "attract", "engage", "engagement"
  ),
  RESEARCH_EDUCATION_ACADEMICS = c(
    "research", "education", "academic", "clinical trial", "medical education",
    "innovation lab", "knowledge translation", "discovery", "translational",
    "grant", "institute", "teaching"
  ),
  POPULATION_COMMUNITY_HEALTH = c(
    "health promotion", "chronic disease", "oht", "ontario health team",
    "mental health", "addiction", "substance use", "community health",
    "prevention", "population health", "primary care", "public health"
  ),
  PATIENT_CARE_EXCELLENCE = c(
    "quality", "safety", "patient experience", "clinical outcome", "zero harm",
    "best practice", "person centred", "person-centred", "family centred",
    "family-centred", "patient safety", "quality improvement", "safe care",
    "excellence", "standard"
  ),
  ORGANIZATIONAL_CULTURE_GOVERNANCE = c(
    "mission", "values", "governance", "accountability", "community engagement",
    "branding", "culture", "transparency", "strategic", "leadership",
    "engagement", "vision", "organizational", "stewardship"
  ),
  INTEGRATION_PARTNERSHIPS = c(
    "integration", "partnership", "collaborate", "collaboration", "oht",
    "ontario health team", "cross-sector", "system integration", "partner",
    "alliance", "coalition", "continuum"
  ),
  INFRASTRUCTURE_ENVIRONMENT = c(
    "capital", "redevelopment", "infrastructure", "facilities", "parking",
    "green", "sustainability", "build", "construction", "renovation",
    "environment", "campus", "expansion", "beds", "mri", "equipment"
  ),
  HEALTH_EQUITY_SOCIAL_ACCOUNTABILITY = c(
    "indigenous", "equity", "edi", "dei", "diversity", "inclusion",
    "anti-racism", "racism", "francophone", "marginalized", "racialized",
    "vulnerable", "social accountability", "cultural safety", "culturally safe",
    "reconciliation", "health equity"
  ),
  FINANCIAL_SUSTAINABILITY = c(
    "efficiency", "funding", "cost", "revenue", "financial", "fiscal",
    "resource", "budget", "investment", "savings", "sustainability",
    "accountability", "performance", "business", "viable"
  ),
  DIGITAL_HEALTH_INNOVATION = c(
    "digital", "emr", "electronic medical record", "his", "health information",
    "ai", "artificial intelligence", "virtual care", "data analytics",
    "cyber", "technology", "innovation", "informatics", "telehealth",
    "remote care", "automation"
  ),
  ACCESS_CAPACITY = c(
    "wait time", "patient flow", "bed capacity", "throughput", "access",
    "capacity", "hours of operation", "timely", "appropriate care",
    "emergency department", "ed", "surgical", "backlog", "demand"
  )
)

# ============================================================
# STEP 2: Helper function - count keyword matches in text
# Uses whole-word matching, case-insensitive
# Multi-word phrases checked first, then single words
# ============================================================

count_theme_matches <- function(text, keywords) {
  if (is.na(text) || str_trim(text) == "" || str_trim(text) == "NF" || str_trim(text) == "NF.") {
    return(0L)
  }
  
  text_lower <- str_to_lower(text)
  
  # Separate multi-word phrases from single words
  multi_word  <- keywords[str_detect(keywords, "\\s")]
  single_word <- keywords[!str_detect(keywords, "\\s")]
  
  count <- 0L
  
  # Count multi-word phrase matches
  for (phrase in multi_word) {
    matches <- str_count(text_lower, fixed(phrase))
    count <- count + matches
  }
  
  # Count single-word matches using word boundaries
  for (word in single_word) {
    pattern <- paste0("\\b", regex_escape(word), "\\b")
    matches <- str_count(text_lower, regex(pattern))
    count <- count + matches
  }
  
  return(count)
}

# Helper: escape special regex characters in keywords
regex_escape <- function(x) {
  str_replace_all(x, "([\\.\\^\\$\\*\\+\\?\\(\\)\\[\\]\\{\\}\\|\\\\])", "\\\\\\1")
}

# ============================================================
# STEP 3: Count total words in Analysis_Corpus
# ============================================================

count_words <- function(text) {
  if (is.na(text) || str_trim(text) == "" || str_trim(text) == "NF" || str_trim(text) == "NF.") {
    return(NA_integer_)
  }
  # Split on whitespace
  length(unlist(str_split(str_trim(text), "\\s+")))
}

# ============================================================
# STEP 4: Load your data
# Replace this with your actual data loading method
# e.g., df <- read_csv("your_file.csv") or load from SQLite
# ============================================================

# df <- read_csv("hospital_strategy_data.csv")   # <-- replace as needed

# For now, assuming df is already loaded in your environment
# Required columns: FAC, Hospital_Name, Direction, Analysis_Corpus
df<-readRDS("E:/HospitalStrategyGemini/Output/CleanDFFinal.rds")
# ============================================================
# STEP 5: Apply scoring
# ============================================================

score_directions <- function(df, theme_keywords) {
  
  theme_names <- names(theme_keywords)
  
  results <- df %>%
    select(FAC, Hospital_Name, Direction, Analysis_Corpus) %>%
    mutate(
      word_count = map_int(Analysis_Corpus, count_words)
    )
  
  # Calculate raw counts for each theme
  for (theme in theme_names) {
    keywords <- theme_keywords[[theme]]
    col_name_raw   <- paste0("raw_", theme)
    col_name_score <- paste0("Score_", theme)
    
    results <- results %>%
      mutate(
        !!col_name_raw := map_int(Analysis_Corpus, ~count_theme_matches(.x, keywords)),
        !!col_name_score := case_when(
          is.na(word_count) | word_count == 0 ~ NA_real_,
          TRUE ~ as.double(.data[[col_name_raw]]) / word_count
        )
      )
  }
  
  return(results)
}

# ============================================================
# STEP 6: Run scoring and produce final output
# ============================================================

scored_df <- score_directions(df, theme_keywords)

# Final output table: FAC, Hospital_Name, Direction, Score columns only
output_cols <- c("FAC", "Hospital_Name", "Direction", 
                 paste0("Score_", names(theme_keywords)))

final_output <- scored_df %>%
  select(all_of(output_cols)) %>%
  rename_with(~ str_replace(.x, "Score_", "Score_for_"), starts_with("Score_"))

# Preview
print(final_output)

# Optional: export
# write_csv(final_output, "theme_scores_phase1.csv")

# ============================================================
# DIAGNOSTIC: Check raw counts alongside scores (optional)
# ============================================================

# scored_df %>%
#   select(FAC, Hospital_Name, Direction, word_count,
#          starts_with("raw_"), starts_with("Score_")) %>%
#   View()