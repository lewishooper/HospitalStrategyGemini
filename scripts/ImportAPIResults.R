library(tidyr)
library(tidyverse)
library(readr)
library(readxl)


# bring in, review and update the data from the Gemini API call in 
# process_strategies.R


DF<-read_csv("E:/HospitalStrategyGemini/Source/Master_Strategy_Extract_20260210_1107.csv")
DF<-DF %>%
  rename(Hospital_Name="Hospital Name",FAC="Hospital FAC",Plan_dates="Plan Dates",Direction="Strategic Direction") %>%
  rename(Descriptive_text="Descriptive Text",Actions="Key Actions")
DF<-DF %>%
  filter(Hospital_Name!=":---")


NumberofDirections<-DF %>%
  select(Hospital_Name,FAC) %>%
  group_by(Hospital_Name)%>%
  mutate(NumNames=n()) %>%
  unique()
         

### some fixes are needed
#southlake fac didn't come across
DF<-DF %>%
  mutate(FAC = ifelse(is.na(FAC), 736, FAC))

# delete hawksbury for now fac=800 Page is unable to be rendered I have asked for physical copy
DF <- DF %>%
  filter(FAC != 800)
