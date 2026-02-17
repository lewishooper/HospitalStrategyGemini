library(tidyverse)
library(httr2)
library(stringr)

# --- 1. PREP THE DATA ---
# Load your file (if not already loaded)
# full_df <- readRDS("your_latest_file.rds")

# Isolate the Stubborn 88 (NUCLEAR_FAIL or PARSE_ERROR)
stubborn_rows <- full_df %>% 
  filter(str_detect(primary_theme, "NUCLEAR_FAIL") | str_detect(primary_theme, "PARSE_ERROR"))

print(paste("Switching to Text Mode for", nrow(stubborn_rows), "rows."))

# --- 2. THE TEXT-MODE FUNCTION ---
classify_text_mode <- function(direction_title, direction_text) {
  
  # SYSTEM INSTRUCTION: No JSON. Just simple lines.
  system_instruction <- "
  ### ROLE: Senior Healthcare Analyst.
  ### TASK: Classify strategic directions.
  ### FORMAT: return exactly 3 lines. Do NOT use JSON.
  Primary: [Insert Theme Name]
  Secondary: [Insert Theme Name or None]
  Rationale: [Insert one sentence explanation]
  
  ### THEMES:
  1. PATIENT CARE, 2. ACCESS, 3. EQUITY, 4. POPULATION, 5. WORKFORCE, 
  6. FINANCIAL, 7. DIGITAL, 8. INTEGRATION, 9. INFRASTRUCTURE, 10. CULTURE, 11. RESEARCH
  "
  
  # CLEAN INPUT: Remove 'NF' noise before sending
  clean_text <- str_replace_all(direction_text, "\\bNF\\b", " ") %>% str_squish()
  user_prompt <- paste0("TITLE: ", direction_title, "\nTEXT: ", clean_text)
  
  # API CALL
  response <- request("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent") %>%
    req_url_query(key = Sys.getenv("GEMINI_API_KEY")) %>%
    req_body_json(list(
      contents = list(list(role = "user", parts = list(list(text = paste(system_instruction, user_prompt, sep="\n\n")))))
    )) %>%
    req_retry(max_tries = 3) %>%
    req_error(is_error = function(resp) FALSE) %>%
    req_perform()
  
  # --- MANUAL TEXT PARSING ---
  tryCatch({
    raw_text <- resp_body_json(response)$candidates[[1]]$content$parts[[1]]$text
    
    # Extract values using Regex (much more forgiving than JSON)
    p_theme <- str_extract(raw_text, "(?<=Primary: ).*") %>% str_trim()
    s_theme <- str_extract(raw_text, "(?<=Secondary: ).*") %>% str_trim()
    rat     <- str_extract(raw_text, "(?<=Rationale: ).*") %>% str_trim()
    
    # handle cases where regex misses (rare)
    if (is.na(p_theme)) p_theme <- "MANUAL_REVIEW"
    
    tibble(
      primary_theme = p_theme,
      secondary_theme = s_theme,
      rationale = rat,
      confidence = "High" # Default for this batch
    )
    
  }, error = function(e) {
    tibble(primary_theme = "TEXT_PARSE_FAIL", rationale = as.character(e))
  })
}

# --- 3. EXECUTE REPAIR ---
text_mode_results <- stubborn_rows %>%
  select(FAC, Hospital_Name, Direction, Analysis_Corpus) %>%
  mutate(
    api_result = map2(Direction, Analysis_Corpus, function(d, c) {
      Sys.sleep(1.5)
      cat(".")
      classify_text_mode(d, c)
    })
  ) %>%
  unnest(api_result)

# --- 4. FINAL MERGE ---
# Get the rows that were already good
good_rows <- full_df %>% 
  filter(!str_detect(primary_theme, "NUCLEAR_FAIL") & 
           !str_detect(primary_theme, "PARSE_ERROR") & 
           !str_detect(primary_theme, "FAIL"))

# Combine
final_complete_dataset <- bind_rows(good_rows, text_mode_results)

# --- 5. CLEANUP THEME NAMES ---
# Standardize "1. Patient Care" -> "Patient Care Excellence"
final_complete_dataset <- final_complete_dataset %>%
  mutate(
    # Remove numbers (1.) and generic text
    primary_theme_clean = str_remove(primary_theme, "^\\d+\\.\\s+") %>% 
      str_remove("\\*\\*") %>% # Remove bold markdown if present
      str_to_title() %>% 
      str_trim()
  )

# SAVE
timestamp <- format(Sys.time(), "%Y%m%d_%H%M")
saveRDS(final_complete_dataset, paste0("Strategy_Final_Complete_", timestamp, ".rds"))

print("✅ Repair Complete.")
final_complete_dataset %>% count(primary_theme_clean, sort = TRUE)