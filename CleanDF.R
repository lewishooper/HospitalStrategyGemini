library(tidyverse)
library(stringr)

# 1. Setup your function to clean the Actions column
# This replaces the HTML tags with semantic punctuation
clean_actions <- function(text) {
  text <- text %>%
    # Replace the double break (Item Separator) with a period and newline
    str_replace_all("<br><br>", ".\n") %>%
    # Replace the single break (Title-Detail Separator) with a colon
    str_replace_all("<br>", ": ") %>%
    # Remove any remaining HTML tags just in case
    str_remove_all("<[^>]+>") %>%
    # Trim whitespace
    str_trim()
  
  # Ensure it ends with a period if it's not empty
  if (nchar(text) > 0 && str_sub(text, -1) != ".") {
    text <- paste0(text, ".")
  }
  return(text)
}

# 2. Main Cleaning Pipeline
clean_df <- FullData %>%
  mutate(
    # --- Step A: Clean Structure ---
    # Apply the function to the Actions column
    Actions_Cleaned = map_chr(Actions, clean_actions),
    
    # --- Step B: Text Normalization ---
    # Convert Direction to Title Case (e.g., "Transformative Experiences")
    Direction = str_to_title(Direction),
    
    # --- Step C: Parse Dates ---
    # Split "2024-2028" into two numeric columns
    # We use 'extract' to be robust against different separators (hyphens, en-dashes)
    Start_Year = as.numeric(str_extract(Plan_dates, "^\\d{4}")),
    End_Year   = as.numeric(str_extract(Plan_dates, "\\d{4}$")),
    
    # --- Step D: Clean Hidden Characters ---
    # Replace non-breaking spaces (\xa0) and squash multiple spaces into one
    Descriptive_text = str_squish(Descriptive_text),
    Actions_Cleaned  = str_squish(Actions_Cleaned),
    
    # --- Step E: Create Full Context Corpus ---
    # Combine relevant columns into one "document"
    Analysis_Corpus = paste(
      replace_na(Direction, ""),
      replace_na(Descriptive_text, ""),
      replace_na(Actions_Cleaned, ""),
      sep = ". "
    )
  ) %>%
  # --- Step F: Remove Self-References (Hospital Name) ---
  rowwise() %>% 
  mutate(
    # Replace the specific hospital name with "the hospital" in the corpus
    # 'regex' with ignore_case = TRUE ensures we catch "UHN" and "uhn"
    Analysis_Corpus = str_replace_all(
      Analysis_Corpus, 
      regex(paste0("\\b", Hospital_Name, "\\b"), ignore_case = TRUE), 
      "the hospital"
    )
  ) %>%
  ungroup()

# View the result
glimpse(clean_df)
