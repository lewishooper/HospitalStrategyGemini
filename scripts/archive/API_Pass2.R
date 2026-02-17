library(tidyverse)
library(httr2)
library(jsonlite)

# --- 1. LOAD DATA ---
# Load your saved file from last night
filename <- "classified_strategies_20260212_2144.rds" 
full_df <- readRDS(filename)

# Split the data
good_rows <- full_df %>% filter(primary_theme != "PARSE_ERROR" & primary_theme != "FAIL")
bad_rows  <- full_df %>% filter(primary_theme == "PARSE_ERROR" | primary_theme == "FAIL")

print(paste("Rows to Repair:", nrow(bad_rows)))

# --- 2. CONFIGURATION ---
api_key <- Sys.getenv("GEMINI_API_KEY") 
model_url <- "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

# --- 3. THE REPAIR FUNCTION (With FULL Instructions) ---
classify_repair <- function(direction_title, direction_text) {
  
  # RESTORED THE FULL INSTRUCTION HERE
  system_instruction <- "
  ### ROLE: Senior Healthcare Strategic Analyst for Ontario.
  ### TASK: Classify into max 3 themes (Primary, Secondary, Tertiary).
  ### THEME DEFINITIONS:
  1. PATIENT CARE EXCELLENCE: Quality, safety, patient experience, clinical outcomes.
  2. ACCESS & CAPACITY: Wait times, flow, bed capacity, ED throughput. (Exclude: Virtual care)
  3. HEALTH EQUITY & SOCIAL ACCOUNTABILITY: Indigenous health, EDI, SDOH, vulnerable populations.
  4. POPULATION & COMMUNITY HEALTH: Prevention, wellness, chronic disease mgmt. (Exclude: OHT Governance)
  5. WORKFORCE SUSTAINABILITY: Recruitment, retention, burnout, wellness.
  6. FINANCIAL SUSTAINABILITY: Efficiency, funding, cost savings.
  7. DIGITAL HEALTH & INNOVATION: HIS, EMR, AI, virtual care, data. (Note: 'Innovation' without tech context implies Process Improvement -> Patient Care).
  8. INTEGRATION & PARTNERSHIPS: OHT (Ontario Health Teams) governance, system integration, cross-sector collaboration.
  9. INFRASTRUCTURE & ENVIRONMENT: Buildings, facilities, parking, green/sustainability.
  10. ORG CULTURE & GOVERNANCE: Mission/Values, leadership, accountability, brand.
  11. RESEARCH, EDUCATION & ACADEMICS: Discovery, clinical trials, teaching/students.
  
  ### RULES:
  - OHT mentions: Default to '8. INTEGRATION' unless a specific health outcome is the primary goal.
  - Innovation: If tech/data mentioned -> '7. DIGITAL'. If science/discovery -> '11. RESEARCH'.
  - Provide a clear Rationale.
  
  ### JSON OUTPUT FORMAT:
  {
    \"primary_theme\": \"Theme Name\",
    \"secondary_theme\": \"Theme Name (or null)\",
    \"tertiary_theme\": \"Theme Name (or null)\",
    \"rationale\": \"1-sentence explanation\",
    \"confidence\": \"High/Medium/Low\"
  }"
  
  user_prompt <- paste0("TITLE: ", direction_title, "\nTEXT: ", direction_text)
  
  # API CALL
  response <- request(model_url) %>%
    req_url_query(key = api_key) %>%
    req_body_json(list(
      contents = list(list(role = "user", parts = list(list(text = paste(system_instruction, user_prompt, sep="\n\n"))))),
      generationConfig = list(response_mime_type = "application/json")
    )) %>%
    req_retry(max_tries = 3) %>%
    req_error(is_error = function(resp) FALSE) %>%
    req_perform()
  
  if (resp_status(response) != 200) return(tibble(primary_theme = paste("ERROR", resp_status(response))))
  
  # --- ROBUST CLEANING (Fixing the Markdown Error) ---
  tryCatch({
    raw_text <- resp_body_json(response)$candidates[[1]]$content$parts[[1]]$text
    
    # Strip Markdown Code Blocks
    clean_text <- raw_text %>%
      str_remove_all("^```json") %>% 
      str_remove_all("^```") %>%     
      str_remove_all("```$") %>%     
      str_trim()                     
    
    fromJSON(clean_text) %>% as_tibble()
    
  }, error = function(e) tibble(primary_theme = "PARSE_ERROR_AGAIN"))
}

# Wrapper
classify_repair_safe <- possibly(classify_repair, otherwise = tibble(primary_theme = "FAIL"))

# --- 4. EXECUTE REPAIR ---
print("Starting Repair Loop...")

repaired_results <- bad_rows %>%
  select(FAC, Hospital_Name, Direction, Analysis_Corpus) %>%
  mutate(
    api_result = map2(Direction, Analysis_Corpus, function(d, c) {
      Sys.sleep(1.5)
      cat(".") 
      classify_repair_safe(d, c) # Note: we pass 'c' (Analysis_Corpus) here!
    })
  ) %>%
  unnest(api_result)

# --- 5. MERGE & SAVE ---
final_dataset <- bind_rows(good_rows, repaired_results)

# Clean up Theme Names (Standardize "1. Patient..." to "Patient...")
final_dataset <- final_dataset %>%
  mutate(
    primary_theme_clean = str_remove(primary_theme, "^\\d+\\.\\s+") %>% str_to_title()
  )

# Save Final
timestamp <- format(Sys.time(), "%Y%m%d_%H%M")
saveRDS(final_dataset, paste0("Strategy_Classified_REPAIRED_", timestamp, ".rds"))

print("✅ Repair Complete. Final Check:")
final_dataset %>% count(primary_theme_clean, sort = TRUE)
