# spatial_agg_crops()
# Spatial aggregation of crop data

### R Libraries
library(raster)
rasterOptions(tmpdir = "/net/usr/spool/")   # set alternative /tmp directory
library(rgdal)
library(rgeos)

spatial_agg_crops = function(file.nm,    # full file name for crop data
                             shp,        # shapefile for spatial aggregation
                             out.nm){    # full file name for output
  
  crop.data     = raster(file.nm)
  crop.prod.agg = extract(crop.data, shp, fun=sum, na.rm=T, sp=F)
  
  write.csv(crop.prod.agg, out.nm)
  print(paste(out.nm, "written to file"))
}
