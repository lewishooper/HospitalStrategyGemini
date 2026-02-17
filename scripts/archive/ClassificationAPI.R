library(tidyverse)
library(httr2)
library(jsonlite)
# Step 1 Setup and API
# --- CONFIGURATION ---
# Replace this with your actual Gemini API key
# Ideally, store this in your .Renviron file as GOOGLE_API_KEY
api_key <- Sys.getenv("GEMINI_API_KEY") 

# If you haven't set it in the environment, uncomment and paste here (not recommended for sharing):
# api_key <- "YOUR_ACTUAL_API_KEY_HERE"

# The Model Endpoint (using 2,0 flash
model_url <- "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"


# step Define the system Prompt
system_instruction <- "
### ROLE
You are a Senior Healthcare Strategic Analyst for Ontario. Classify the strategic direction provided into the following framework.

### THEME DEFINITIONS
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

### RULES
- OHT mentions: Default to '8. INTEGRATION' unless a specific health outcome is the primary goal.
- Innovation: If tech/data mentioned -> '7. DIGITAL'. If science/discovery -> '11. RESEARCH'.
- Assign up to 3 themes (Primary, Secondary, Tertiary).
- Provide a clear Rationale.

### JSON OUTPUT FORMAT
{
  \"primary_theme\": \"Theme Name\",
  \"secondary_theme\": \"Theme Name (or null)\",
  \"tertiary_theme\": \"Theme Name (or null)\",
  \"rationale\": \"1-sentence explanation\",
  \"confidence\": \"High/Medium/Low\"
}"
# step 3
classify_direction <- function(direction_title, direction_text) {
  
  # Construct the user prompt
  user_prompt <- paste0(
    "DIRECTION TITLE: ", direction_title, "\n",
    "DESCRIPTION & ACTIONS: ", direction_text
  )
  
  # Build the request body
  body <- list(
    contents = list(
      list(role = "user", parts = list(list(text = paste(system_instruction, user_prompt, sep = "\n\n"))))
    ),
    generationConfig = list(
      response_mime_type = "application/json" # Forces JSON output
    )
  )
  
  # Make the API call with error handling
  response <- request(model_url) %>%
    req_url_query(key = api_key) %>%
    req_body_json(body) %>%
    # Retry automatically on transient errors (429, 500, 503)
    req_retry(max_tries = 3) %>% 
    req_error(is_error = function(resp) FALSE) %>% # Prevent R error stop, handle manually
    req_perform()
  
  # Check status
  if (resp_status(response) != 200) {
    warning(paste("API Error:", resp_status(response)))
    return(tibble(primary_theme = "ERROR", rationale = paste("Status", resp_status(response))))
  }
  
  # Parse content
  tryCatch({
    text_content <- resp_body_json(response)$candidates[[1]]$content$parts[[1]]$text
    parsed_json <- fromJSON(text_content)
    return(as_tibble(parsed_json))
  }, error = function(e) {
    return(tibble(primary_theme = "PARSE_ERROR", rationale = as.character(e)))
  })
}
#4 The loop
# Create a Safe Version of the function (so one failure doesn't crash the whole loop)
# --- #4 THE LOOP (UPDATED WITH PROGRESS TRACKING) ---

# Create a Safe Version of the function (so one failure doesn't crash the whole loop)
classify_safe <- possibly(classify_direction, otherwise = tibble(primary_theme = "FAIL"))

print(paste("Starting Classification on", nrow(clean_df_final), "rows..."))

results_df <- clean_df_final %>%
  # Select only the columns we need for the API + ID
  select(FAC, Hospital_Name, Direction, Analysis_Corpus) %>%
  mutate(
    api_result = map2(Direction, Analysis_Corpus, function(d, c) {
      
      # 1. TIMING: Sleep 1.5 seconds to be safe with rate limits
      Sys.sleep(1.5) 
      
      # 2. PROGRESS: Print a dot to the console so you know it's working
      cat(".") 
      
      # 3. EXECUTE: Call the safe function
      classify_safe(d, c)
    })
  ) %>%
  # Unnest the JSON columns back into the main dataframe
  unnest(api_result)

print("\nClassification Complete.")

# --- #5 SAVE TO RDS ---

# Save with a timestamp so you don't overwrite previous runs
timestamp <- format(Sys.time(), "%Y%m%d_%H%M")
filename <- paste0("classified_strategies_", timestamp, ".rds")

saveRDS(results_df, file = filename)

print(paste("✅ Saved to:", filename))

# --- INSPECTION ---
# Quick inspection of the results
print("Top Primary Themes Identified:")
results_df %>% 
  count(primary_theme, sort = TRUE) %>%
  print()

results_df %>% 
  select(Direction, primary_theme, confidence, rationale) %>% 
  head(10) %>%
  print()