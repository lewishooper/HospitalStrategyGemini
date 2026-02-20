# ==============================================================================
# STRATEGIC PLAN CLASSIFIER - PRODUCTION VERSION (FINAL)
# ==============================================================================
# Purpose: Classify hospital strategic directions into 11 standardized themes.
# Method:  Uses Gemini 2.0 Flash via API in "Text Mode" (most robust).
# Inputs:  'clean_df_final' (Dataframe with Direction & Analysis_Corpus)
# Outputs: 'Strategy_Master_Dataset.rds' in E:/HospitalStrategyGemini/Output/
# ==============================================================================
#rm(list=ls())
library(tidyverse)
library(httr2)
library(stringr)

# --- 1. CONFIGURATION ---
api_key <- Sys.getenv("GEMINI_API_KEY") 
model_url <- "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
output_dir <- "E:/HospitalStrategyGemini/Output/"


clean_df_final<-readRDS("E:/HospitalStrategyGemini/Output/CleanDFFinal.rds")


# Define the canonical themes list (The "Source of Truth")
THEME_DEFINITIONS <- "
1. PATIENT CARE EXCELLENCE (Quality, safety, experience)
2. ACCESS & CAPACITY (Wait times, flow. Exclude: Virtual)
3. HEALTH EQUITY & SOCIAL ACCOUNTABILITY (Indigenous, EDI, SDOH)
4. POPULATION & COMMUNITY HEALTH (Wellness, chronic disease. Exclude: Acute)
5. WORKFORCE SUSTAINABILITY (Recruitment, retention, wellness)
6. FINANCIAL SUSTAINABILITY (Efficiency, cost)
7. DIGITAL HEALTH & INNOVATION (AI, EMR, Virtual. If science -> Research)
8. INTEGRATION & PARTNERSHIPS (OHTs, system integration)
9. INFRASTRUCTURE & ENVIRONMENT (Builds, facilities)
10. ORG CULTURE & GOVERNANCE (Mission/Values, leadership)
11. RESEARCH, EDUCATION & ACADEMICS (Discovery, teaching)
"

# --- 2. THE ROBUST CLASSIFICATION FUNCTION ---
classify_strategy <- function(direction_title, direction_text) {
  
  # A. Clean Input (Handles "NF" and "NF.")
  clean_text <- str_replace_all(direction_text, "\\bNF\\.?\\b", " ") %>% str_squish()
  
  # B. Construct Prompt (Text Mode - No JSON)
  system_instruction <- paste0(
    "### ROLE: Senior Healthcare Analyst.\n",
    "### TASK: Classify into max 3 themes.\n",
    "### THEMES:", THEME_DEFINITIONS, "\n",
    "### RULES:\n",
    "- Default OHT to 'INTEGRATION'.\n",
    "- Innovation: Tech->DIGITAL, Science->RESEARCH.\n",
    "### OUTPUT FORMAT (Strictly 3 lines):\n",
    "Primary: [Exact Theme Name]\n",
    "Secondary: [Exact Theme Name or None]\n",
    "Rationale: [One sentence explanation]"
  )
  
  user_prompt <- paste0("TITLE: ", direction_title, "\nTEXT: ", clean_text)
  
  # C. API Call (Exponential Backoff included)
  response <- request(model_url) %>%
    req_url_query(key = api_key) %>%
    req_body_json(list(
      contents = list(list(role = "user", parts = list(list(text = paste(system_instruction, user_prompt, sep="\n\n")))))
    )) %>%
    req_retry(max_tries = 3, backoff = function(i) 2^i) %>% 
    req_error(is_error = function(resp) FALSE) %>%
    req_perform()
  
  # D. Robust Parsing (Regex instead of JSON)
  if (resp_status(response) != 200) return(tibble(primary_theme = "API_ERROR", rationale = paste("Status", resp_status(response))))
  
  tryCatch({
    raw_text <- resp_body_json(response)$candidates[[1]]$content$parts[[1]]$text
    
    # Extract fields using Lookbehind Regex
    p_theme <- str_extract(raw_text, "(?<=Primary: ).*") %>% str_trim()
    s_theme <- str_extract(raw_text, "(?<=Secondary: ).*") %>% str_trim()
    rat     <- str_extract(raw_text, "(?<=Rationale: ).*") %>% str_trim()
    
    # Fallback if regex fails (rare)
    if (is.na(p_theme)) p_theme <- "MANUAL_REVIEW"
    
    tibble(primary_theme = p_theme, secondary_theme = s_theme, rationale = rat)
    
  }, error = function(e) tibble(primary_theme = "PARSE_ERROR", rationale = as.character(e)))
}

# Wrapper to prevent crashing
classify_safe <- possibly(classify_strategy, otherwise = tibble(primary_theme = "FAIL"))

# --- 3. EXECUTION LOOP ---
print(paste("Starting classification on", nrow(clean_df_final), "strategies..."))

raw_results <- clean_df_final %>%
   select(FAC, Hospital_Name, Direction, Analysis_Corpus) %>%
  mutate(
    api_result = map2(Direction, Analysis_Corpus, function(d, c) {
      Sys.sleep(1.5) # Safety buffer
      cat(".")       # Progress dot
      classify_safe(d, c)
    })
  ) %>%
  unnest(api_result)

# --- 4. POST-PROCESSING (Fix Vocabulary Drift) ---
print("\nStandardizing Themes...")

final_dataset <- raw_results %>%
  mutate(
    # Clean the Raw Theme (Remove numbers, bolding, extra spaces)
    theme_clean = str_remove_all(primary_theme, "^\\d+\\.\\s*") %>% 
      str_remove_all("\\*") %>% 
      str_trim() %>% 
      str_to_title(),
    
    # Map to Official Categories
    Standardized_Theme = case_when(
      str_detect(theme_clean, "Patient Care") ~ "Patient Care Excellence",
      str_detect(theme_clean, "Access") ~ "Access & Capacity",
      str_detect(theme_clean, "Equity") ~ "Health Equity & Social Accountability",
      str_detect(theme_clean, "Population") ~ "Population & Community Health",
      str_detect(theme_clean, "Workforce") ~ "Workforce Sustainability",
      str_detect(theme_clean, "Financial") ~ "Financial Sustainability",
      str_detect(theme_clean, "Digital") ~ "Digital Health & Innovation",
      str_detect(theme_clean, "Integration|OHT|Partner") ~ "Integration & Partnerships",
      str_detect(theme_clean, "Infrastructure") ~ "Infrastructure & Environment",
      str_detect(theme_clean, "Culture|Governance") ~ "Org Culture & Governance",
      str_detect(theme_clean, "Research|Education") ~ "Research, Education & Academics",
      TRUE ~ "Review Required" # Flags anything that didn't match
    )
  )

# --- 5. SAVE ---
# Create directory if missing
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

timestamp <- format(Sys.time(), "%Y%m%d_%H%M")
saveRDS(final_dataset, paste0(output_dir, "Strategy_Master_Dataset_", timestamp, ".rds"))
final_dataset<-readRDS(file.path(output_dir,"Strategy_Master_Dataset_20260218_1035.rds"))
print(paste("✅ SUCCESS! Saved to:", output_dir))
print("Final Distribution:")
final_dataset %>% count(Standardized_Theme, sort = TRUE)

## Need to add back the Type and MOH name, and dates.
AddTypeAndDates<-clean_df_final %>%
  select(FAC,MOH_Name,Type,Start_Year,End_Year) %>%
  unique()
final_dataset<-left_join(final_dataset,AddTypeAndDates,by="FAC")
