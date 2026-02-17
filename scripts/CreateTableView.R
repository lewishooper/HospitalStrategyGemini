
#rm(list=ls())
# Load required libraries
library(tidyverse)
library(gt) # For professional tables
library(readxl)
final_dataset<-readRDS("E:/HospitalStrategyGemini/Output/Strategy_Master_Dataset_20260213_1119.rds")

MOHLookup<-read_xlsx("E:/HospitalStrategyGemini/Source/FACMOHHIT.xlsx") %>%
  rename(FAC="Facility ID",Hospital_Name="Facility",Type="Facility Type") %>%
  mutate(FAC=as.character(FAC))

ForType<-MOHLookup %>%
  select(FAC,Type)
final_dataset<-left_join(final_dataset,ForType,by="FAC")

# --- STEP 1: GROUPING HOSPITAL TYPES ---
# We will collapse specialty categories into broader buckets for cleaner analysis
final_dataset_cleaned <- final_dataset %>%
  filter(Type != "Other") %>% # Remove noise
  mutate(Hospital_Group = case_when(
    Type %in% c("Teaching", "Children's") ~ "Teaching & Research",
    Type %in% c("Mental Health", "Chronic", "Rehab") ~ "Specialty/Rehab",
    Type == "Small" ~ "Small Rural",
    Type == "Community" ~ "Community",
    TRUE ~ Type # Keeps existing if not specified above
  ))

# --- STEP 2: OVERVIEW TABLE ---
# We need to calculate counts at the Hospital level first, then aggregate
hospital_summary <- final_dataset_cleaned %>%
  group_by(Hospital_Group, FAC) %>%
  summarize(
    n_directions = n(),
    .groups = "drop"
  ) %>%
  group_by(Hospital_Group) %>%
  summarize(
    `Hospital Count` = n_distinct(FAC),
    `Total Directions` = sum(n_directions),
    `Avg Directions/Plan` = round(mean(n_directions), 1),
    `Min` = min(n_directions),
    `Max` = max(n_directions)
  ) %>%
  arrange(desc(`Hospital Count`))

# Render a clean table for validation
overview_table <- hospital_summary %>%
  gt() %>%
  tab_header(
    title = "Ontario Hospital Strategic Plan Overview",
    subtitle = "Analysis by Grouped Hospital Type"
  ) %>%
  cols_align(align = "left", columns = Hospital_Group) %>%
  tab_options(table.width = pct(100))

# Display the table
print(overview_table)
