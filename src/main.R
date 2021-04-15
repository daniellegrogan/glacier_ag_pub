# MAIN

###########################################################################################################################
# Main file for post-processing of Water Balance Model (WBM) output for the paper:
# High Mountain Asia’s glacier ice melt water is important for local food security, but not for global food production
# (not yet published)
# Project: NASA High Mountain Asia Team (HiMAT and HiMAT-2)

# Code by Danielle S Grogan, University of New Hampshire

###########################################################################################################################
# R libraries
library(RCurl)  # enables sourcing R code from github
library(raster)
rasterOptions(tmpdir = "/net/usr/spool/")   # set alternative /tmp directory
library(rgdal)
library(rgeos)

### Source functions from other github repos:
# wbm_load()
wbm_load.script = getURL("https://raw.githubusercontent.com/daniellegrogan/WBMr/master/wbm_load.R", ssl.verifypeer=F)
eval(parse(text=wbm_load.script))

# mouth_ts_basins()
mouth_ts_basins.script = getURL("https://raw.githubusercontent.com/daniellegrogan/WBMr/master/mouth_ts_basins.R", ssl.verifypeer=F)
eval(parse(text=mouth_ts_basins.script))

# create_dir()
create_dir.script = getURL("https://raw.githubusercontent.com/daniellegrogan/WBMr/master/create_dir.R", ssl.verifypeer=F)
eval(parse(text=create_dir.script))

# spatial_aggregation()
spatial_aggregation.script = getURL("https://raw.githubusercontent.com/daniellegrogan/WBMr/master/spatial_aggregation.R", ssl.verifypeer=F)
eval(parse(text=spatial_aggregation.script))

###########################################################################################################################
###  File Paths ###
path.base = "/net/nfs/squam/raid/data/WBM_TrANS/HiMAT/2021-02/HiMAT_clim_1981_2040_v3/monthly"   # testing. for real, use v4
path.out  = "results/"  

###########################################################################################################################
### Load data ###

# shapefiles for spatial aggregation
basins    = readOGR("data/basins_hma",    "basins_hma")  
subbasins = readOGR("data/subbasin_poly", "subbasin_poly")

# basin attributes for identifying basin mouth grid cells
basin.ID = raster("data/HiMAT_full_210_IDs_Subset.asc")
up.area  = raster("data/HiMAT_full_210_Subset_upstrArea.asc")

# unit conversions
# m3_to_mm = (1e-3)/cell.area
# seconds_per_day = 86400
# mm_per_m = 1e3
# m2_per_km2 = 1e6
# m3s_to_mm.day = seconds_per_day * mm_per_m * 1/(cell.area*m2_per_km2)
###########################################################################################################################
