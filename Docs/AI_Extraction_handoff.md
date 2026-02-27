This project is a process to download and analyze the hospital strategies.  
The steps taken so far are detailed below.

1) gather strategic plans from ontario hospitals websites, as a pdf
2) Using an API disaggregate those strategic plans into a dataframe consisting of 
  a) the Hospital Name,an FAC(which is a unique identifier),each single direction, a text description of that Direction(if available),And actions related to that direction(if available
  b) Each Direction is a single row, and the actions for that Direcion are concatenated with a separator <br>
3) analysis of the directions both in aggregate and for each hospital

At this point in the project we have achieved steps 1 and 2
The hospital strategic plans are available as a separate file "G:\My Drive\Strategies"
The following script is critical to this process and is how the Gemini API is used in step2

What follows are three documents critical to the process
1) The "Process_strategies.R" which was used to extract the elements needed in step 2
2) the Extraction protocol 
3) a sample of the output called FullData which is the working database used for step 3
# ==============================================================================
# STRATEGIC PLAN EXTRACTION ENGINE (FINAL PRODUCTION VERSION)
# ==============================================================================

library(pdftools)
library(tidyverse)
library(fs)
library(httr2)
library(jsonlite)
library(base64enc)

# 1. CONFIGURATION ------------------------------------------------------------

input_folder  <- "G:/My Drive/Strategies"
output_folder <- "G:/My Drive/StrategyResults"

# RUN_MODE: "specific", "test_batch" (3 files), or "full"
RUN_MODE  <- "specific"   
TARGET_ID <- "684"       

# Ensure output directory exists
fs::dir_create(output_folder)

# 2. PROMPT -------------------------------------------------------------------
# Defines the extraction logic from your text file
prompt_file <- "E:/HospitalStrategyGemini/ExtractactionProtocol.txt"

if(!file.exists(prompt_file)) stop("Prompt file not found! Check the path in Section 2.")

extraction_prompt <- paste(readLines(prompt_file, warn = FALSE), collapse = "\n")

# 3. HELPER FUNCTION ----------------------------------------------------------
# 3. HELPER FUNCTION (UPDATED FOR SCANNED PDFS) -------------------------------

process_hospital_plan <- function(file_path) {
  
  # A. Metadata
  filename <- path_file(file_path)
  fac_code <- str_extract(filename, "(?<=_)\\d{3}(?=_|\\.pdf)")
  
  # B. Read PDF as BINARY (Base64) - Solves the "Scanned PDF" issue
  # We do NOT use pdftools::pdf_text anymore. We let Gemini see the file.
  base64_string <- tryCatch({
    # Read raw bytes
    raw_data <- readBin(file_path, "raw", file.info(file_path)$size)
    # Convert to Base64 (requires base64enc package)
    base64enc::base64encode(raw_data)
  }, error = function(e) return(NULL))
  
  if(is.null(base64_string)) { warning(paste("File Read Failed:", filename)); return(NULL) }
  
  # Construct the Prompt with METADATA (Text Part)
  # Note: We don't include the PDF content in the text string anymore.
  prompt_text <- paste0(
    extraction_prompt, "\n\n",
    "METADATA - HOSPITAL FAC ID: ", fac_code
  )
  
  # C. Call Gemini API (Multimodal Request)
  api_key <- Sys.getenv("GEMINI_API_KEY")
  if (api_key == "") stop("API Key missing!")
  
  # Using gemini-1.5-pro (Best for document reasoning/OCR)
  req <- request("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent") %>%
    req_url_query(key = api_key) %>%
    req_headers("Content-Type" = "application/json") %>%
    req_body_json(list(
      contents = list(
        list(
          role = "user",
          parts = list(
            # Part 1: The Text Instructions
            list(text = prompt_text),
            # Part 2: The Actual PDF File (Inline Data)
            list(
              inline_data = list(
                mime_type = "application/pdf",
                data = base64_string
              )
            )
          )
        )
      )
    ))
  
  # Perform request
  response <- tryCatch({
    req_perform(req)
  }, error = function(e) {
    if (!is.null(e$resp)) {
      warning(paste("API Error [", filename, "]:", resp_body_string(e$resp)))
    } else {
      warning(paste("Network Error [", filename, "]:", e$message))
    }
    return(NULL)
  })
  
  if(is.null(response)) return(NULL)
  
  # D. Parse Output (Standard Logic)
  resp_json <- resp_body_json(response)
  
  if(is.null(resp_json$candidates)) {
    warning(paste("Success but no content for:", filename))
    return(NULL)
  }
  
  raw_text <- resp_json$candidates[[1]]$content$parts[[1]]$text
  
  # Clean Markdown table format
  clean_text <- raw_text %>%
    str_remove_all("```markdown") %>%
    str_remove_all("```") %>%
    str_trim() %>%
    str_replace_all("(?m)^\\|", "") %>%
    str_replace_all("(?m)\\|$", "")
  
  # Parse table
  parsed_data <- tryCatch({
    read_delim(clean_text, delim = "|", trim_ws = TRUE, show_col_types = FALSE) %>%
      filter(!str_detect(`Hospital Name`, "^\\s*-+")) %>%
      select(where(~!all(is.na(.)))) %>%
      mutate(`Hospital FAC` = fac_code)
  }, error = function(e) {
    warning(paste("Table Parsing Error for:", filename))
    return(NULL)
  })
  
  return(parsed_data)
}


# 4. EXECUTION (Robust Loop) --------------------------------------------------

# Get all PDF files
all_files <- dir_ls(input_folder, glob = "*.pdf")

# Robust File Filtering Logic
if (RUN_MODE == "specific" || RUN_MODE == "single") {
  files_to_process <- all_files[str_detect(all_files, TARGET_ID)]
  if(length(files_to_process) == 0) stop(paste("No file found for ID:", TARGET_ID))
  
} else if (RUN_MODE == "test_batch") {
  files_to_process <- head(all_files, 3)
  
} else {
  # Full Batch
  files_to_process <- all_files
}

cat("RUN_MODE:", RUN_MODE, "\n")
cat("Files to process:", length(files_to_process), "\n\n")

# Initialize Master List
results_list <- list()
temp_backup_file <- path(output_folder, "temp_extraction_backup.rds")

# LOOP START
for (i in seq_along(files_to_process)) {
  
  file_path <- files_to_process[i]
  file_name <- path_file(file_path)
  
  cat(sprintf("[%d/%d] Processing: %s ... ", i, length(files_to_process), file_name))
  
  # 1. CRASH PROTECTION (Try-Catch Wrapper)
  tryCatch({
    
    # Run the extraction
    extraction_result <- process_hospital_plan(file_path)
    
    # Store result (if successful)
    if (!is.null(extraction_result)) {
      results_list[[file_path]] <- extraction_result
      
      # Save individual CSV immediately as a hard backup
      fac_code <- str_extract(file_name, "(?<=_)\\d{3}")
      write_csv(extraction_result, path(output_folder, paste0("Result_", fac_code, ".csv")))
      cat("DONE.\n")
    } else {
      cat("SKIPPED (Error/Null).\n")
    }
    
  }, error = function(e) {
    cat("CRASHED -> ", e$message, "\n")
  })
  
  # 2. INCREMENTAL BACKUP (Every 5 files)
  if (i %% 5 == 0) {
    saveRDS(results_list, temp_backup_file)
    cat("--- (Backup Saved) ---\n")
  }
  
  # 3. RATE LIMITING (Polite Pause)
  # Sleep 5 seconds between files to stay under RPM limits
  if (i < length(files_to_process)) {
    Sys.sleep(5) 
  }
}

# 5. AGGREGATE ----------------------------------------------------------------

cat("\nAggregating Results...\n")

# Combine all dataframes in the list
master_table <- bind_rows(results_list)

if(nrow(master_table) > 0) {
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M")
  final_path <- path(output_folder, paste0("Master_Strategy_Extract_", timestamp, ".csv"))
  
  write_csv(master_table, final_path)
  cat("\nSUCCESS! Master file saved to:\n", final_path, "\n")
  print(master_table)
} else {
  cat("\nWARNING: No data was extracted from the selected files.\n")
  }
  
  
The extraction protocol that is referrenced is 
The Strict Extraction Prompt
Role: You are a strict Data Extraction Engine. You are NOT a creative writer.
Task: Analyze the provided Strategic Plan PDF and extract specific data points into a table.
Rules for Extraction (Read Carefully):
1. Verbatim Extraction: Extract text exactly as it appears in the document. Do not summarize, rephrase, or prettify the text.
2. No Hallucinated Titles: When listing actions or priorities, do NOT create bold "titles" or "headers" for the bullet points if they do not exist in the source text. (e.g., If the text says "Enhance access to care," do NOT write "Access: Enhance access to care").
3. "NF" Protocol: If a specific data point (like a descriptive sentence for a direction) is not explicitly present in the text near the header, you must output NF (Not Found). Do not infer descriptions from other parts of the document like the CEO's letter.
4. Descriptive Text: Only include "Descriptive Text" if there is a specific sentence or paragraph accompanying the Strategic Direction headline that explains it. If the direction is just a standalone word (e.g., "People"), mark the description as NF.
Required Table Columns:
* Hospital Name (Exact name from cover)
* Hospital FAC ( extract from file Name)
* Plan Dates (Range, or NF)
* Strategic Direction (The high-level pillar)
* Descriptive Text (The sub-text for that pillar, or NF)
* Key Actions (The specific bullet points/priorities under that direction. Verbatim only.)

All library dependencies are listed in the source file
Current State As of Feb 10th, 2026
this script works well for almost all of the hospitals
Known issues are FAC 800 Hawksbury hospital which does not parse and. A physical copy of the plan is requested but is not yet availalbe
Rural Roads hosptials 684 824 the pdf is not structured correctly however the data was right??
A manual update have been done for 4 hospitals.

Sample Dataframe follows
Hospital_Name	FAC	Plan_dates	Direction	Descriptive_text	Actions	Type
UHN	947	2024-2028	TRANSFORMATIVE EXPERIENCES	We will create extraordinary, integrated health care experiences that are seamless, compassionate and centered around the patient, family and TeamUHN members. Every individual – whether receiving care or delivering it – deserves an environment that supports their needs. Our aspiration is to create a system that puts people first, empowers our staff, and delivers on our promises at every touchpoint.	Integrated Care<br>Break down barriers and create a unified, seamless health care experience that travels with the patient, wherever they go.<br><br>TeamUHN Experience<br>Build an environment where our team members are empowered, valued and ready to take bold action, day in and day out.<br><br>Lead in Education<br>Create world-class educational experiences that prepare the next generation of clinicians and scientists to push the limits of possibility.	Teaching Hospital
UHN	947	2024-2028	SOLUTIONS BEYOND BOUNDARIES	UHN is leading the charge for radical innovation. That means investing in discovery like never before. New opportunities and solutions abound, and UHN must nurture and convert those.	Accelerate Research and Innovation<br>Create bold, breakthrough science-driven solutions to the world, improving outcomes for patients and health care systems globally.<br><br>Set Global Health Standards<br>Share our research, knowledge and innovations globally to redefine best practices and elevate health outcomes everywhere.<br><br>Transform Health Education<br>Focus on team-based, collaborative education that prepares learners for a rapidly evolving and exciting landscape.	Teaching Hospital
UHN	947	2024-2028	ALIGNMENT FOR IMPACT	To create lasting change, we will align our resources, partnerships and technologies where they will have the greatest impact. UHN is called to drive real, transformative solutions that leverage the privilege of caring for patients, educating the health care providers and students of tomorrow, pursuing discovery and adoption. The future is here – and UHN is bringing it to life.	High-Impact Partnerships<br>Forge strategic alliances that will amplify our efforts and drive widespread, meaningful results.<br><br>Harness Technology to Revolutionize Care<br>Integrate AI and digital tools to enhance the precision, speed and personalization of treatment, from diagnosis to recovery.<br><br>Build a Thriving Health Care Ecosystem<br>Foster an interconnected system that accelerates progress and ensures sustainable improvements in health worldwide and addresses the translation, adoption and commercialization of scientific discoveries for people in Canada and around the world.	Teaching Hospital

