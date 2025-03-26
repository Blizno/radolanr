#' dataDWDPerDay
#'
#' @description
#' This function lists all available sensors for a specific device on open sensor web
#' A file like "lastest" is only available at https but data is only available for 2 days at "https", so I will stay with ftp but try to find the last dataset in mode = "latest"
#' I the code is run on a system with another timezone the the one of the user, this might cause problems
#' This function and rdwd is not using #https://opendata.dwd.de/weather/radar/radolan/sf/ but gridbase = "ftp://opendata.dwd.de/climate_environment/CDC/grids_germany"
#' For Radolan finaly this function then is using: radbase = "ftp://opendata.dwd.de/climate_environment/CDC/grids_germany/daily/radolan/recent/bin/"
#' @param date as Date formate YY-MM-DD
#' @param hour hour of the day
#' @param mode latest or specific if only the last dataset provided shall be used, variables date and hour will be ignored an the last dataset provided will be returned, the https server might also provide this but can not be accessed in the same way with rdwd
#' @return a radolan grid
#' @examples radolanr::dataDWDPerDay(date = Sys.Date()-1, hour = "23")
#' @import rdwd dwdradar
#' @export
dataDWDPerDay <- function(mode = "specific", date = Sys.Date()-1, hour = "23", addMetaData = FALSE){
  # library(rdwd)
  #rdwd::updateRdwd() # --> installes the last version, developement version on the github is used..
  #library(rdwd)
  #install.packages('dwdradar')
  #library(dwdradar)

  # set the database file
  radbase <- paste0(gridbase,"/daily/radolan/recent/bin/") # gidbase = "ftp://opendata.dwd.de/climate_environment/CDC/grids_germany"

  # chose which dataset to download: latest or fixed time and date
  if (mode == "latest"){
    # will provide the last dataset, normally 2 hours ago
    mytime <- Sys.time()

    # floor time to 10 minutes intervals as data is provided in 10 minutes interval
    #mytime <- floor_time_to_10min(mytime)
    #data.time <- mytime - (2*3600)  # assuming data is provided at minimum every two hours, here I may find a more precise possibility, todo: include error handling and trying
    #radfile <- format(data.time, paste0("raa01-sf_10000-%y%m%d%H%M","-dwd---bin.gz"))



    # der Datensatz zur Stunde:50 Minuten hat immer den Stand xx.20 oder xx:21 wird der Datensatz aktualisiert --> ich muss also wenn es vor :20 ist 2h abziehen und ansonsten 1h
    # aber bei https:// hat der Datensatz 20:50 hat den Stand 21:16
    # im FTP hat der Datensatz 20:50 Aenderungsdatum 23:20 obwohl es gerade erst 22:53 ist.. vielleicht haben die FTP-Daten ein anderes Datumsformat, was ich nicht glaube, sondern nur der Server hat ein komisches Zeit-Format: Winterzeit?!

    mytime <- Sys.time()
    time_lt <- as.POSIXlt(mytime)

    # test if minutes are > or < 20 Mintes (add some buffer and use 25)
    if (time_lt$min >=0 & time_lt$min < 25){
      time_lt$hour <- time_lt$hour - 3
    } else {
      time_lt$hour <- time_lt$hour - 2
    }

    time_lt$min <- 50
    time_lt$sec <- 0
    # Convert back to POSIXct
    time.dataset <- as.POSIXct(time_lt)

    radfile <- format(time.dataset, paste0("raa01-sf_10000-%y%m%d%H%M-dwd---bin.gz")) # Todo: this might be more precise if I would use the code above and adding 10 minutes or rounding


  } else if (mode == "specific"){
    radfile <- format(date, paste0("raa01-sf_10000-%y%m%d",hour,"50-dwd---bin.gz")) # Todo: this might be more precise if I would use the code above and adding 10 minutes or rounding

  }

  rad <- dataDWD(radfile, base=radbase, joinbf=TRUE, dividebyten=FALSE)
  radp <- projectRasterDWD(rad$dat)
  #radp <- radp * 10 # correct for the 1/10mm values to get mm (added Rikard, 8.1.2024)  ---> maybe I do not need this anymore if "dividebyten=TRUE

  # plot it for testing
  # plotRadar(radp, main=paste("mm in 24 hours preceding", rad$meta$date), project=FALSE)


  if (addMetaData == TRUE){ # it is not clear if this will also work for a rasterstack
    # Add metadata using metags() # https://rspatial.github.io/terra/reference/metags.html

    # standardize date format information by adding the ISO 8601 Format with offset to UTC asigned, can be done by %z Signed offset in hours and minutes from UTC, so -0800 is 8 hours behind UTC. Values up to +1400 are accepted. (Standard only for output. For input R currently supports it on all platforms.)

    #datetime_posixct <- as.POSIXct(timestamp_radolan, format = "%Y-%m-%d %H:%M:%S") # not completely clear if this is UTC, summer or winter time

    timestamp_radolan_posixct_ISO <- format(rad$meta$date, "%Y-%m-%d %H:%M:%S%z")
    timestamp_access_posixct_ISO <- format(Sys.time(), "%Y-%m-%d %H:%M:%S%z")

    my.tag <- cbind(c("timestamp_radolan", "timestamp_access"), c(as.character(timestamp_radolan_posixct_ISO), as.character(timestamp_access_posixct_ISO)))
    metags(radp, layer = NULL, domain = "") <- my.tag
    metags(radp)
  }
  return(radp)
}


#' dataDWDPerDayInterval
#'
#' @description
#' Download data of Radolan Data for a specific time interval
#' all arguments from dataDWDPerDay() may be used to e.g. specify the reference hour for the measurement, default is 23:00, but data is from the last 24h, so 23:00 largly represents the precipitation of the given day.
#' @param date as Date formate YY-MM-DD
#' @param hour hour of the day
#' @param data.start as.Date format
#' @param date.end as.Date format e.g. as.Date("2025-01-01")
#' @return a radolan grid
#' @examples radolanr::dataDWDPerDay(date = Sys.Date()-1, hour = "23")
#' @import rdwd dwdradar
#' @export
dataDWDPerDayInterval <- function(date.start = as.Date("2025-01-01"), date.end = as.Date("2025-01-02"), hour = "23",...){
  days <- as.Date(date.start:date.end)
  my_list <- vector("list", length = length(days))

  # sequentially download radolan data for the last days
  for (i in seq_along(my_list)){
    my_list[[i]] <- dataDWDPerDay(date = as.Date(days[i]), ...)
  }

  # create raster stack
  mystack <- terra::rast(my_list) # to create a raste stack use c(layer1, layer2,.. ) but if data is provided as a list use terra:rast(list)

  # name the layers for easier referencing and for better naming after extraction
  names(mystack) <- days
  myraster_stack = mystack

  #myraster_stack <- dataDWDPerDay(...) #.. allow the flexible forwarding of parameters, if dataDWDPerDay gets new parameters they will be available for the wrapper function.
  return(myraster_stack)
}






#' extractTimeSeriesFromStack
#'
#' @description
#' extract a timeseries object from a radolan-stack
#'
#' @param raster_stack given radolan raster stack, exportet from dataDWDPerDayInterval()
#' @param centroids in the format of SpatialPoints for which data shall be exported
#' @return a list of the resulting timeseries as data.frame along with given centroids and raster stack
#' @examples my.centroids = terra::vect("data_raw/centroid_amms_weatherstation_coswig_4326.shp")
#' @examples my.timeseries <- extractTimeSeriesFromStack(raster_stack = radolan_stack, centroids = my.centroids)
#' @import raster tidyverse
#' @export
extractTimeSeriesFromStack <- function(raster_stack, centroids){
  # TODO: im idalfall kann ich hier einen Stack oder nur ein Datum reingeben und es kommt jedes mal das gleiche Format raus..


  # extract the rain amounts at specific points
  r.vals <- raster::extract(raster_stack, centroids, na.rm = TRUE)  #, df = TRUE


  rain_radolan <- as.data.frame(t(r.vals), ) # transpose the results
  rain_radolan$date <- rownames(rain_radolan)
  rain_radolan <- rain_radolan[-1,]
  rownames(rain_radolan) <- NULL
  colnames(rain_radolan) <- c("rain_mm","date" )



  rain_radolan <- rain_radolan %>%
    mutate(date = as.Date(date)) %>%
    dplyr::select(date,rain_mm)



  # wenn die Centroids mehrere Punkte enthalten, soll ein flat file ausgegeben werden mit date, plot, value
  # ggf. ist es sinnvoll auch noch das punkt-shape mit auszugeben?? Oder ich joine es ueber den namen

  # create a list or json to return
  results =
    list(
    centroids = centroids,
    raster_stack = raster_stack,
    time_series = rain_radolan

  )
  return(results)
}


#' floor_time_to_10min
#'
#' @description
#' round_time_to_10min
#'
#' @param raster_stack given radolan raster stack, exportet from dataDWDPerDayInterval()
#' @param centroids in the format of SpatialPoints for which data shall be exported
#' @return a list of the resulting timeseries as data.frame along with given centroids and raster stack
#' @examples my.centroids = terra::vect("data_raw/centroid_amms_weatherstation_coswig_4326.shp")
#' @examples my.timeseries <- extractTimeSeriesFromStack(raster_stack = radolan_stack, centroids = my.centroids)
#' @export
#'
#'
floor_time_to_10min <- function(mytime) {
  # Convert to POSIXlt to access minutes and seconds
  time_lt <- as.POSIXlt(mytime)

  # Floor minutes to the nearest multiple of 10
  floored_minute <- floor(time_lt$min / 10) * 10

  # Apply the floored minutes and reset seconds
  time_lt$min <- floored_minute
  time_lt$sec <- 0

  # Convert back to POSIXct
  as.POSIXct(time_lt)
}

