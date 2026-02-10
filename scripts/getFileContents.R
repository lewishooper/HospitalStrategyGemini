# Load required library
library(dplyr)
library(lubridate)
library(stringr)

# Set the main folder path
main_folder <- "E:/Hospital_Strategic_Plans/strategic_plans"

# Get all subfolders (excluding the main folder itself)
subfolders <- list.dirs(main_folder, recursive = FALSE, full.names = TRUE)

# Initialize an empty list to store results
file_list <- list()

# Loop through each subfolder
for (subfolder in subfolders) {
  
  # Get subfolder name (without full path)
  subfolder_name <- basename(subfolder)
  
  # Get subfolder creation time
  subfolder_info <- file.info(subfolder)
  subfolder_created <- subfolder_info$ctime
  
  # Get all files in this subfolder (not recursive)
  files <- list.files(subfolder, full.names = TRUE, recursive = FALSE)
  
  # If there are files in this subfolder
  if (length(files) > 0) {
    
    # Get file information
    file_info <- file.info(files)
    
    # Create a dataframe for this subfolder's files
    subfolder_df <- data.frame(
      subfolder_name = subfolder_name,
      subfolder_created = subfolder_created,
      file_name = basename(files),
      file_type = tools::file_ext(basename(files)),
      file_created = file_info$ctime,
      file_modified = file_info$mtime,
      stringsAsFactors = FALSE
    )
    
    file_list[[length(file_list) + 1]] <- subfolder_df
  }
}

# Combine all dataframes into one
files_df <- bind_rows(file_list)
saveRDS(files_df,"E:/HospitalStrategyGemini/Source/AllStrategyFiles.rds"      )
# View the result
print(paste("Total files found:", nrow(files_df)))
#head(files_df)
TotalPDFS<-files_df %>%
  filter(file_type=="pdf") %>%
  group_by(subfolder_name) %>%
  mutate(MultiplePDFs=n())  %>%
  select(subfolder_name,file_name) %>%
  mutate(FAC=str_sub(subfolder_name,1,3))
saveRDS(TotalPDFS,"E:/HospitalStrategyGemini/Source/AllFeb26PDFs.rds")
colnames(TotalPDFS)
