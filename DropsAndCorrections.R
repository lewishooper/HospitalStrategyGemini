library(tidyverse)
library(readxl)


## Add in template
#UHN<-read_csv(file.path(source,"UHNRepairs.csv")) %>%
 # rename(Hospital_Name="Hospital Name",FAC="Hospital FAC",Plan_dates="Plan Dates",Direction="Strategic Direction") %>%
  #rename(Descriptive_text="Descriptive Text",Actions="Key Actions") %>%
  #filter(Hospital_Name!=":---")

#DF<-DF %>%
 # filter(FAC!=947)
#DF<-rbind(DF,UHN)  

final_dataset_visualization_readyTemplate<-final_dataset_visualization_ready[0,]
write_csv2(final_dataset_visualization_readyTemplate,"E:/HospitalStrategyGemini/Source/Updates.csv")
           