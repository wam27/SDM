multiple.union<-function(rasters){
  
  extents <- lapply(raster.list, extent)
  
  
  min_x <- min(sapply(extents, "xmin"))
  max_x <- max(sapply(extents, "xmax"))
  min_y <- min(sapply(extents, "ymin"))
  max_y <- max(sapply(extents, "ymax"))
  
  
  union_extent <- extent(min_x, max_x, min_y, max_y)
  
  return(union_extent)
}