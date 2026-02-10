# ==============================================================================
# Script: Organize Files into Batch Folders
# Purpose: Copy files from source directory into numbered batch folders (10 per batch)
# ==============================================================================

# Load required libraries
library(dplyr)

# ==============================================================================
# Configuration
# ==============================================================================

# File paths
rds_file <- "E:/HospitalStrategyGemini/Source/AllFeb26PDFs.rds"
source_base <- "E:/Hospital_Strategic_Plans/strategic_plans"
dest_base <- "E:/HospitalStrategyGemini/BatchFolder"

# Batch size
files_per_batch <- 10

# ==============================================================================
# Main Processing
# ==============================================================================

# Read the RDS file
cat("Reading file list from RDS...\n")
file_data <- readRDS(rds_file)

# Display summary
cat(sprintf("Total files to process: %d\n", nrow(file_data)))
cat(sprintf("Files per batch: %d\n", files_per_batch))
cat(sprintf("Number of batches needed: %d\n\n", ceiling(nrow(file_data) / files_per_batch)))

# Create the main batch folder if it doesn't exist
if (!dir.exists(dest_base)) {
  dir.create(dest_base, recursive = TRUE)
  cat(sprintf("Created main batch folder: %s\n", dest_base))
}

# Initialize counters
total_copied <- 0
total_failed <- 0
failed_files <- list()

# Process each file
cat("\nStarting file copy process...\n")
cat("========================================\n\n")

for (i in 1:nrow(file_data)) {
  row <- file_data[i, ]
  
  # Calculate batch number for this file (0-indexed)
  batch_number <- (i - 1) %/% files_per_batch
  batch_folder_name <- sprintf("batch%d", batch_number)
  
  # Construct source path
  source_path <- file.path(source_base, row$subfolder_name, row$file_name)
  
  # Construct destination folder and path
  dest_folder <- file.path(dest_base, batch_folder_name)
  dest_path <- file.path(dest_folder, row$file_name)
  
  # Create batch folder if it doesn't exist
  if (!dir.exists(dest_folder)) {
    dir.create(dest_folder, recursive = TRUE)
    cat(sprintf("Created folder: %s\n", row$batch_folder))
  }
  
  # Check if source file exists
  if (!file.exists(source_path)) {
    cat(sprintf("  [%d/%d] ERROR: Source file not found: %s\n", 
                i, nrow(file_data), source_path))
    total_failed <- total_failed + 1
    failed_files[[length(failed_files) + 1]] <- list(
      index = i,
      path = source_path,
      reason = "Source file not found"
    )
    next
  }
  
  # Copy the file
  tryCatch({
    file.copy(source_path, dest_path, overwrite = TRUE)
    total_copied <- total_copied + 1
    
    # Progress update every 10 files
    if (i %% 10 == 0) {
      cat(sprintf("  [%d/%d] Copied to %s\n", i, nrow(file_data), batch_folder_name))
    }
  }, error = function(e) {
    cat(sprintf("  [%d/%d] ERROR copying file: %s\n", i, nrow(file_data), e$message))
    total_failed <- total_failed + 1
    failed_files[[length(failed_files) + 1]] <- list(
      index = i,
      path = source_path,
      reason = e$message
    )
  })
}

# ==============================================================================
# Summary Report
# ==============================================================================

cat("\n========================================\n")
cat("SUMMARY\n")
cat("========================================\n")
cat(sprintf("Total files processed: %d\n", nrow(file_data)))
cat(sprintf("Successfully copied: %d\n", total_copied))
cat(sprintf("Failed: %d\n", total_failed))
cat(sprintf("Batches created: %d\n", ceiling(nrow(file_data) / files_per_batch)))

# List batch folders with file counts
cat("\nBatch Distribution:\n")
for (batch_num in 0:(ceiling(nrow(file_data) / files_per_batch) - 1)) {
  start_idx <- batch_num * files_per_batch + 1
  end_idx <- min((batch_num + 1) * files_per_batch, nrow(file_data))
  file_count <- end_idx - start_idx + 1
  cat(sprintf("  batch%d: %d files\n", batch_num, file_count))
}

# Show failed files if any
if (total_failed > 0) {
  cat("\nFailed Files:\n")
  for (fail in failed_files) {
    cat(sprintf("  [%d] %s\n      Reason: %s\n", 
                fail$index, fail$path, fail$reason))
  }
}

cat("\n========================================\n")
cat("Process completed!\n")
cat(sprintf("Output location: %s\n", dest_base))
cat("========================================\n")
