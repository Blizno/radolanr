#' radolan2polygon.R
#'
#' @description
#' This function
#' Outlook: I will in future maybe use terra alongside with geos package. Use terra if working with raster & vector data (most modern for raster). Use sf if doing vector operations (widely used, but heavier dependencies). Use geos for fast geometry computations (complements terra well).
#'

#' @param locations_polygon_path a polygon layer (may be the file or its path)
#' @param radolan_raster the radolan raster created with radolanr::dataDWDPerDay(addMetaData = TRUE)
#' @param use_metadata use metadata stored in a terra::metag()
#' @param silent show warnings, plots,..
#' @param saveCentroidsVector export the created centroids to a shapefile (boolean)
#' @param centroidsVectorPath path where the centroids will be exported to (.shp)
#' @return a polygon layer with locations_polygon_path filled with rain_mm values from radolan data
#' @import terra
#' @export
radolan2polygon <- function(locations_polygon_path, radolan_raster, use_metadata = TRUE, silent = TRUE, saveCentroidsVector = FALSE, centroidsVectorPath = ""){
  # read shapefiles of target areas

  try({
    # Check if input is already a SpatVector
    if (inherits(locations_polygon_path, "SpatVector")) {
      shp <- locations_polygon_path  # Directly assign if it is a SpatVector

      # Check if input is a valid file path
    } else if (is.character(locations_polygon_path) &&
               file.exists(locations_polygon_path)) {
      shp <- terra::vect(locations_polygon_path)  # Read shapefile if it exists

      # If neither, return an error
    } else {
      stop("Error: Input must be either a valid SpatVector or a path to a shapefile.")
    }
  }, silent = FALSE)  # Ensure errors are displayed

  shp <- terra::vect(locations_polygon_path)
  my.centroids <- terra::centroids(shp)

  # # Optional/Todo:
  # # Convert SpatVector to geos_geometry and compute centroids that are guaranteed to be inside polygons (critical for irregular    polygons). This is not guaranteed for terra:centroides. However geos not natevly works with terra object so conversions are necessary.
  # my.centroids.inside <- geos::geos_point_on_surface(shp)

  if (saveCentroidsVector == TRUE){
    terra::writeVector(my.centroids, "transsect_weinbau_seusslitz_pillnitz_polygons_centroids_4326.shp", overwrite = TRUE)
  }

  # Extract raster values to list object
  r.vals <- terra::extract(radolan_raster, my.centroids, na.rm = FALSE)  # !! changed raster extract to terra:extract to be consistent here -->     maybe change this in UseCase1 too ; I think na should not be removed as this will change the ranking and number of extracted     values, but na.rm seems not to have an influence in the function, i.e. if polygons are outside the radolan map there will be NA in the resulting table, no matter if na.rm was TRUE or FALSE

  if (silent == FALSE){
    print(r.vals)
  }

    # Extract function returns a data frame with an ID column, so merge properly
  my.centroids$rain_mm <- r.vals[, 2]  # Second column contains raster values

  # Add metadata
  if (use_metadata == TRUE){
    my.metadata       <- terra::metags(radolan_raster) # a names character vector
    timestamp_radolan <- my.metadata["timestamp_radolan"] # will give timestamp of radolan data in ISO8601 Format: "2025-03-26   08:50:00+0100" as character string (added by radolanr::dataDWDPerDay(mode = "latest", addMetaData = TRUE))
  }


  # create output
  shp$rain_mm <- r.vals[,2]
  shp$timestamp_radolan <- timestamp_radolan

  return(shp)

}
