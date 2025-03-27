## code to prepare `centroids_weatherstation` dataset goes here

library(tidyverse)
library(usethis)
library(sf)


centroid_weatherstation <- sf::st_read("data_raw/centroid_amms_weatherstation_coswig_4326.shp")

# 2. add your data to the "/data" file of the package and make it available
usethis::use_data(centroid_weatherstation, overwrite = TRUE)
# this does not work! SpatVector objects are not standard R objects → They include pointers to external data, which cannot be saved/restored with save() or load().
#When you reload the .rda file, the external pointer becomes invalid, causing the "external pointer is not valid" error.

# 3. document your data in the "R/data.R" file
