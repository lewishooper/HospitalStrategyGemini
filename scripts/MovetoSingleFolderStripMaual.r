# Strategic Plan PDF Management Script
# Purpose: Copy PDFs from batch folders and clean up manual filenames

library(fs)
library(purrr)

# Function 1: Copy all PDFs from StrategyBatches subfolders to Strategies folder
copy_batch_pdfs <- function(
    source_dir = "G:/My Drive/StrategyBatches",
    dest_dir = "G:/My Drive/Strategies"
) {
  
  cat("Starting PDF copy process...\n")
  cat("Source directory:", source_dir, "\n")
  cat("Destination directory:", dest_dir, "\n\n")
  
  # Check if source directory exists
  if (!dir.exists(source_dir)) {
    stop("Source directory does not exist: ", source_dir)
  }
  
  # Create destination directory if it doesn't exist
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
    cat("Created destination directory\n")
  }
  
  # Find all PDF files in subfolders
  pdf_files <- list.files(
    source_dir,
    pattern = "\\.pdf$",
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = TRUE
  )
  
  cat("Found", length(pdf_files), "PDF files\n\n")
  
  if (length(pdf_files) == 0) {
    cat("No PDF files found to copy.\n")
    return(invisible(NULL))
  }
  
  # Copy each file
  results <- map_dfr(pdf_files, function(file_path) {
    filename <- basename(file_path)
    dest_path <- file.path(dest_dir, filename)
    
    tryCatch({
      # Check if file already exists
      if (file.exists(dest_path)) {
        cat("SKIP (exists):", filename, "\n")
        return(data.frame(file = filename, status = "skipped", error = NA))
      }
      
      # Copy file
      file.copy(file_path, dest_path)
      cat("COPIED:", filename, "\n")
      return(data.frame(file = filename, status = "copied", error = NA))
      
    }, error = function(e) {
      cat("ERROR:", filename, "-", e$message, "\n")
      return(data.frame(file = filename, status = "error", error = e$message))
    })
  })
  
  # Summary
  cat("\n=== SUMMARY ===\n")
  cat("Total files found:", length(pdf_files), "\n")
  cat("Copied:", sum(results$status == "copied"), "\n")
  cat("Skipped (already exists):", sum(results$status == "skipped"), "\n")
  cat("Errors:", sum(results$status == "error"), "\n")
  
  return(results)
}


# Function 2: Remove "_Manual" from filenames after review
remove_manual_suffix <- function(
    target_dir = "G:/My Drive/Strategies",
    dry_run = TRUE
) {
  
  cat("Starting filename cleanup...\n")
  cat("Target directory:", target_dir, "\n")
  cat("Mode:", if(dry_run) "DRY RUN (no changes)" else "LIVE (will rename)", "\n\n")
  
  # Check if directory exists
  if (!dir.exists(target_dir)) {
    stop("Target directory does not exist: ", target_dir)
  }
  
  # Find all files with "_Manual" in the name
  all_files <- list.files(target_dir, full.names = TRUE)
  manual_files <- all_files[grepl("_Manual", basename(all_files))]
  
  cat("Found", length(manual_files), "files with '_Manual' in the name\n\n")
  
  if (length(manual_files) == 0) {
    cat("No files to rename.\n")
    return(invisible(NULL))
  }
  
  # Process each file
  results <- map_dfr(manual_files, function(file_path) {
    old_name <- basename(file_path)
    new_name <- gsub("_Manual", "", old_name)
    new_path <- file.path(dirname(file_path), new_name)
    
    # Check if target name already exists
    if (file.exists(new_path) && new_path != file_path) {
      cat("CONFLICT:", old_name, "->", new_name, "(target exists)\n")
      return(data.frame(
        old_name = old_name,
        new_name = new_name,
        status = "conflict",
        error = "Target file already exists"
      ))
    }
    
    if (dry_run) {
      cat("WOULD RENAME:", old_name, "->", new_name, "\n")
      return(data.frame(
        old_name = old_name,
        new_name = new_name,
        status = "dry_run",
        error = NA
      ))
    } else {
      tryCatch({
        file.rename(file_path, new_path)
        cat("RENAMED:", old_name, "->", new_name, "\n")
        return(data.frame(
          old_name = old_name,
          new_name = new_name,
          status = "renamed",
          error = NA
        ))
      }, error = function(e) {
        cat("ERROR:", old_name, "-", e$message, "\n")
        return(data.frame(
          old_name = old_name,
          new_name = new_name,
          status = "error",
          error = e$message
        ))
      })
    }
  })
  
  # Summary
  cat("\n=== SUMMARY ===\n")
  cat("Total files with '_Manual':", length(manual_files), "\n")
  if (dry_run) {
    cat("Files that would be renamed:", sum(results$status == "dry_run"), "\n")
  } else {
    cat("Successfully renamed:", sum(results$status == "renamed"), "\n")
    cat("Errors:", sum(results$status == "error"), "\n")
  }
  cat("Conflicts (target exists):", sum(results$status == "conflict"), "\n")
  
  return(results)
}


# ===== USAGE EXAMPLES =====

# Step 1: Copy PDFs from batch folders
# copy_results <- copy_batch_pdfs()

# Step 2a: Preview what would be renamed (safe dry run)
# preview_results <- remove_manual_suffix(dry_run = TRUE)

# Step 2b: After manual review, actually rename files
# rename_results <- remove_manual_suffix(dry_run = FALSE)