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
TARGET_ID <- "961"       

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
