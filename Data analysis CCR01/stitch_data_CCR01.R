# This script stitches together the data files into one dataframe.
# It then does some basic data cleaning in terms of editing column names

library(tidyverse)

# this bit reads in the files and stiches them together
fnams <- list.files("CSV Data", "td", full.names = TRUE) # needed for reading data
subjs <- list.files("CSV Data", "td") # needed for identifying subject numbers
data <- NULL
for (subj in 1:length(fnams)) {
  pData <- read_csv(fnams[subj], col_types = cols(), col_names = FALSE) # read the data from csv
  data <- rbind(data, pData) # combine data array with existing data
}


# first step of data cleaning is to rename variables
data <-
  data %>%
  select(-X2, -X3) %>% # date/time stamp didn't work correctly; phase is irrelevant
  # rename the remaining columns
  rename(block = X4, trial = X5, TT = X6, patType = X7,
         tQuad = X8, tLoc = X9, tOrient = X10,
         resp = X11, acc = X12, RT = X13,
         trialPoints = X14, totalPoints = X15)

save(data, file = "CCR01_data.RData") # save this cleaned data file as

