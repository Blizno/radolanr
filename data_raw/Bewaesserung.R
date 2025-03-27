## code to prepare `wh` dataset goes here

library(tidyverse)
library(usethis)

library(readxl)

# Evaporation model data

# Todo:
#  numbers are read by read.table as strings/characters disregarding the dec = ... parameter



# Read the Excel file
df <- read_excel("data-raw/Bewaesserung.xlsx", sheet = "Bewaesserung")


Bewaesserung <- as.data.frame(df) %>%
  mutate(Datum = as.POSIXct(Datum, format = "%d.%m.%Y %H:%M:%S", tz = "UTC") )




# 2. add your data to the "/data" file of the package and make it available
usethis::use_data(Bewaesserung, overwrite = TRUE)


# 3. document your data in the "R/data.R" file

