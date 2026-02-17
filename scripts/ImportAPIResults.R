library(tidyr)
library(tidyverse)
library(readr)
library(readxl)
library(googledrive)
library(stringr)
#rm(list=ls())
#drive_auth()
#Yes# bring in, review and update the data from the Gemini API call in 
# process_strategies.R
source<-"E:/HospitalStrategyGemini/Source"
GDRive<-"G:/My Drive/StrategyResults"
DF<-read_csv("G:/My Drive/StrategyResults/Master_Strategy_Extract_20260216_1444.csv")
DF<-DF %>%
  rename(Hospital_Name="Hospital Name",FAC="Hospital FAC",Plan_dates="Plan Dates",Direction="Strategic Direction") %>%
  rename(Descriptive_text="Descriptive Text",Actions="Key Actions") %>%
  mutate(FAC=as.character(FAC))
DF<-DF %>%
  filter(Hospital_Name!=":---")
saveRDS(DF,"E:/HospitalStrategyGemini/Output/RawStrategyFeb2026.rds")

NumberofDirections<-DF %>%
  select(Hospital_Name,FAC) %>%
  group_by(Hospital_Name)%>%
  mutate(NumNames=n()) %>%
  unique()
         

### some fixes are needed
#southlake fac didn't come across
DF<-DF %>%
  mutate(FAC = ifelse(Hospital_Name=="Southlake Health", 736, FAC))

# the Name for Rural Roads didn't come across
# AND SOMEHOW RURAL ROADS WAS DUPICATED?
DF<-DF %>%
  mutate(Hospital_Name = ifelse(FAC=="684", "Rural Roads", Hospital_Name)) %>%
  filter(FAC!="NF")


# lets add in MOH Type at this point 
MOHFACAndName<-read_xlsx(file.path(source,"FACMOHHit.xlsx"))
FullFACList<-MOHFACAndName %>%
  select(1:3) %>%
  rename(FAC="Facility ID",MOH_Name=Facility,Type="Facility Type") %>%
  mutate(FAC=as.character(FAC))

DF<-left_join(DF,FullFACList,by="FAC")



# API mix up's replace with chat window corrections



### Note this is before MOH TYPE added
# FAC 597 Mississipi river Hospitals  
# API rolled actions into separete Steps but chat did correctly.

MRH<-read_csv(file.path(GDRive,"Master_Strategy_Extract_20260216_1605.csv"))%>%
  rename(Hospital_Name="Hospital Name",FAC="Hospital FAC",Plan_dates="Plan Dates",Direction="Strategic Direction") %>%
  rename(Descriptive_text="Descriptive Text",Actions="Key Actions") %>%
  mutate(FAC=as.character(FAC))%>%
  filter(Hospital_Name!=":---") %>%
  left_join(FullFACList,by="FAC")
DF<-DF %>%
  filter(FAC!=597)
DF<-rbind(DF,MRH)  


## FAC 656

Wellington<-read_csv(file.path(GDRive,"Master_Strategy_Extract_20260216_1620.csv"))%>%
  rename(Hospital_Name="Hospital Name",FAC="Hospital FAC",Plan_dates="Plan Dates",Direction="Strategic Direction") %>%
  rename(Descriptive_text="Descriptive Text",Actions="Key Actions") %>%
  mutate(FAC=as.character(FAC))%>%
  filter(Hospital_Name!=":---") %>%
  left_join(FullFACList,by="FAC")
DF<-DF %>%
  filter(FAC!=656)
DF<-rbind(DF,Wellington)
#627

Chapleau<-read_csv(file.path(GDRive,"Master_Strategy_Extract_20260216_1828.csv"))%>%
  rename(Hospital_Name="Hospital Name",FAC="Hospital FAC",Plan_dates="Plan Dates",Direction="Strategic Direction") %>%
  rename(Descriptive_text="Descriptive Text",Actions="Key Actions") %>%
  mutate(FAC=as.character(FAC))%>%
  filter(Hospital_Name!=":---") %>%
  left_join(FullFACList,by="FAC")
DF<-DF %>%
  filter(FAC!=627)
DF<-rbind(DF,Chapleau)


#784
MHC<-read_csv(file.path(GDRive,"Master_Strategy_Extract_20260216_1847.csv")) %>%
rename(Hospital_Name="Hospital Name",FAC="Hospital FAC",Plan_dates="Plan Dates",Direction="Strategic Direction") %>%
  rename(Descriptive_text="Descriptive Text",Actions="Key Actions") %>%
  mutate(FAC=as.character(FAC))%>%
  filter(Hospital_Name!=":---") %>%
  left_join(FullFACList,by="FAC")
DF<-DF %>%
  filter(FAC!=784
         )
DF<-rbind(DF,MHC)
#739 Nipigon
Nipigon<-read_csv(file.path(GDRive,"Master_Strategy_Extract_20260216_1906.csv")) %>%
  rename(Hospital_Name="Hospital Name",FAC="Hospital FAC",Plan_dates="Plan Dates",Direction="Strategic Direction") %>%
  rename(Descriptive_text="Descriptive Text",Actions="Key Actions") %>%
  mutate(FAC=as.character(FAC))%>%
  filter(Hospital_Name!=":---") %>%
  left_join(FullFACList,by="FAC")
DF<-DF %>%
  filter(FAC!=739)
DF<-rbind(DF,Nipigon)




### End add in hospitals 

Missing<-anti_join(FullFACList,DF,by="FAC") %>%
  left_join(DF,by="FAC")

write_csv(Missing,"E:/HospitalStrategyGemini/Output/CheckMissing.csv")

DF<-left_join(DF,MOHFAC,by="FAC")
DF$FAC=as.character(DF$FAC)


DupDirections<-DF %>%
  group_by(FAC,Direction) %>%
  mutate(DirectionCount=n())

DoubleNF<-DF %>%
  filter(Actions=="NF")

### need to catch more dates
##  Manual review required

MissingDates<-DF %>%
  select(Hospital_Name,FAC,Plan_dates) %>%
  filter(Plan_dates=="NF") %>%
  unique()



### 
# Clean up the actions and organize for NLP
####
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
clean_df <- DF %>%
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
#glimpse(clean_df)


### ADD IN MANUALLY DISCOVERED DATES
library(readxl)
library(dplyr)

# 1. Load your Excel file with the found dates
# Replace 'path/to/your/file.xlsx' with your actual file path
new_dates_df <- read_excel("E:/HospitalStrategyGemini/Source/ManualStartEndDates.xlsx") %>%
  mutate(FAC=as.character(FAC)) %>%
  rename(Start_Date_new='New Start DATE',End_Date_new='End Date') %>%
  select(-Notes)

# Ensure column names match for a smooth join
# I am assuming your Excel columns are named: 'FAC', 'Start_Date', 'End_Date'
# If not, rename them here:
# new_dates_df <- new_dates_df %>% rename(FAC = `Your Excel Column Name`)

# 2. Update the main dataframe
DF_updated <- clean_df %>%
  # Join the new dates to the main dataframe
  left_join(new_dates_df, by = "FAC", suffix = c("", "_new")) %>%
  
  # Coalesce the columns: Take the original date; if it's missing, take the new one
  mutate(
    Start_Year = coalesce(as.numeric(Start_Year), as.numeric(Start_Date_new)),
    End_Year   = coalesce(as.numeric(End_Year),   as.numeric(End_Date_new))
  ) %>%
  
  # Remove the temporary "_new" columns from the join
  select(-ends_with("_new"))

# 3. Verification
# Check how many dates are still missing
print(paste("Missing Start Years:", sum(is.na(DF_updated$Start_Year))))
print(paste("Missing End Years:", sum(is.na(DF_updated$End_Year))))


### END MANUAL RECOVERY OF DATES

###
##Check for Self referential names()
library(tidytext)

# 1. Unnest the text into individual words
hospital_words <- clean_df %>%
  unnest_tokens(word, Analysis_Corpus) %>%
  count(Hospital_Name, word, sort = TRUE)

# 2. Calculate TF-IDF
# This highlights words unique to specific hospitals
hospital_tfidf <- hospital_words %>%
  bind_tf_idf(word, Hospital_Name, n) %>%
  arrange(desc(tf_idf))

# 3. View the top "unique" words for each hospital
#hospital_tfidf %>%
#  group_by(Hospital_Name) %>%
#  slice_max(tf_idf, n = 3) %>% # Look at top 3 unique words per hospital
#  ungroup() %>%
#  print(n = 20)

## Next step transfer to manual review process

library(tidyverse)
library(tidytext)

# --- 1. Extract High TF-IDF Terms (The "Unique" Words) ---
# Assuming 'hospital_tfidf' exists from your previous step
tfidf_candidates <- hospital_tfidf %>%
  group_by(Hospital_Name) %>%
  # Take the top 20 most unique words for each hospital
  slice_max(tf_idf, n = 20) %>% 
  ungroup() %>%
  mutate(Type="TF-IDF") %>%
  select(Hospital_Name, Term = word, Score = tf_idf, Type)

# --- 2. Extract Acronyms (The "Capitalized" Words) ---
# TF-IDF usually lowercases text, hiding acronyms. Let's find them in the raw text.
acronym_candidates <- clean_df %>%
  # Find all words with 2+ uppercase letters (e.g., "UHN", "PSFDH")
  mutate(Acronyms = str_extract_all(Analysis_Corpus, "\\b[A-Z]{2,}\\b")) %>%
  select(Hospital_Name, Acronyms) %>%
  unnest(Acronyms) %>%
  # Count how often they appear
  count(Hospital_Name, Acronyms, sort = TRUE) %>%
  rename(Term = Acronyms, Score = n) %>%
  mutate(Type = "Acronym")

# --- 3. Combine and Export ---
draft_crosswalk <- bind_rows(tfidf_candidates, acronym_candidates) %>%
  arrange(Hospital_Name, desc(Score))

# Save to CSV for you to open in Excel
#write_csv(draft_crosswalk, "E:/HospitalStrategyGemini/Source/draft_crosswalk_review.csv")

## Names found and recored as CrossWalkInternalNames
SelfReferral<-read.csv("E:/HospitalStrategyGemini/Source/CrossWalkInteralNames.csv")
hospital_ids <- clean_df %>%
  distinct(Hospital_Name, FAC)
Final_crosswalk<- SelfReferral %>%
  left_join(hospital_ids,by="Hospital_Name",relationship = "many-to-many") %>%
  relocate(FAC) %>%
  select(FAC,Hospital_Name,Term) %>%
  group_by(FAC)
crosswalk<-tibble(Final_crosswalk) %>%
  rename(Variation=Term)
# B. The Cleaning Function
apply_crosswalk <- function(corpus, fac_id, lookup_table) {
  # 1. Filter the lookup table for THIS hospital only
  terms_to_remove <- lookup_table %>%
    filter(FAC == fac_id) %>%
    pull(Variation)
  
  # 2. If no terms found, return original text
  if (length(terms_to_remove) == 0) return(corpus)
  
  # 3. Create a regex pattern that matches ANY of the variations
  # \\b ensures we match whole words (so "PSF" doesn't match inside "TOPSFIELD")
  # ignore_case = TRUE handles "psfdh" vs "PSFDH"
  pattern <- paste0("\\b(", paste(terms_to_remove, collapse = "|"), ")\\b")
  
  # 4. Replace with "THE_HOSPITAL" (or empty string "")
  str_replace_all(corpus, regex(pattern, ignore_case = TRUE), "THE_HOSPITAL")
}

# C. Apply it to the main dataframe
clean_df_final <- clean_df %>%
  rowwise() %>%
  mutate(
    Analysis_Corpus = apply_crosswalk(Analysis_Corpus, FAC, crosswalk)
  ) %>%
  ungroup()



saveRDS(DF,"E:/HospitalStrategyGemini/Output/StrategyFeb2026.rds")
saveRDS(clean_df,"E:/HospitalStrategyGemini/Output/CleanStrategyFeb2026.rds")

##
