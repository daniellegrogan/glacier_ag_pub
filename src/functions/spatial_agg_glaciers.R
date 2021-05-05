# spatial_agg_glaciers()  
# Spatial aggregation of PyGEM model output: calculate glacier melt in km3/month, with spatial aggregation

### R Libraries
library(RCurl)  # enables sourcing R code from github
library(raster)
rasterOptions(tmpdir = "/net/usr/spool/")   # set alternative /tmp directory
library(rgdal)
library(rgeos)

# create_dir()
create_dir.script = getURL("https://raw.githubusercontent.com/daniellegrogan/WBMr/master/create_dir.R", ssl.verifypeer=F)
eval(parse(text=create_dir.script))

##################################################################################################################################
spatial_agg_glaciers = function(file.nm,   # full file name with path to PyGEM model output
                                var,       # PyGEM variable to utput
                                shp,       # shapefile for spatial aggregation
                                shp.names, # names from shapefile to use as row names in output
                                path.out   # path to write output
){

  out.nm      = paste(path.out, "/glacier_", var, "_m.csv", sep = "")
  
  if(!file.exists(out.nm)){
    b = raster::brick(file.nm, varname = var)*1e-9  # 1e-9 to convert from m3 to km3
    a = raster::extract(b, shp, fun = sum,  na.rm = T, sp = F)
    rownames(a) = shp.names
    write.csv(a, out.nm)
  }
  print(out.nm)
  removeTmpFiles(h=12) # remove temporary files older than 12 hours. Required to avoid filling up memory in tmpdir
}
##################################################################################################################################
