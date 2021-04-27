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

### Source functions from within this project:
file.sources = list.files("src/functions", full.names = T)
sapply(file.sources, source)

###########################################################################################################################
###  File Paths ###
#path.spn = "/net/nfs/squam/raid/data/WBM_TrANS/HiMAT/2021-04/HiMAT_clim_1981_2060/monthly"  # spinup output
#path.sim = "/net/nfs/squam/raid/data/WBM_TrANS/HiMAT/2021-04/HiMAT_sim_1981_2016/monthly"   # simulation output

# for testing
path.spn = "/net/nfs/squam/raid/data/WBM_TrANS/HiMAT/2021-02/HiMAT_clim_1981_2040_v4/monthly"  # spinup output
path.sim = "/net/nfs/squam/raid/data/WBM_TrANS/HiMAT/2021-02/HiMAT_sim_1981_2016/monthly"   # simulation output

path.out  = "results/"  

###########################################################################################################################
### Load data ###

# shapefiles for spatial aggregation
basins    = readOGR("data/basins_hma",    "basins_hma")  
subbasins = readOGR("data/subbasin_poly", "subbasin_poly")

# basin attributes for identifying basin mouth grid cells
basin.ID = raster("data/HiMAT_full_210_IDs_Subset.asc")
up.area  = raster("data/HiMAT_full_210_Subset_upstrArea.asc")

###########################################################################################################################
### Variable lists for spatial aggregation to BASINS ###

# PyGEM variables for basin aggregation
pygem.to.BAS.agg = c("melt")  # in PyGEM output, "melt" is glacier ice melt

# WBM spinup variables for basin aggregation: storage variables
spn.to.BAS.agg = c("resStorage_mm",  "resStorage_mm_pgi",
                   "endoStrg_mm",    "endoStrg_mm_pgi",    
                   "irrRffStorage",  "surfRffStorage", "runoffStrg_mm_pgi",   # runoffStg = irrRffStorage + surfRffStorage
                   "soilMoist",      "soilMoist_mm_pgi",
                   "grdWater",       "grndWater_mm_pgi")

# WBM simulation variables for basin aggregation
wbm.to.BAS.agg = c(# basin characteristics: precipitation
  "precip", # this is a WBM input, but it is output again by WBM post-regridding
  
  # Fluxes: water lost to the atmosphere
  "etIrrCrops",    "etIrrCrops_mm_pgi",       # via Crop ET
  "openWaterEvap", "openWaterEvap_mm_pgi",    # via open water evaporation (rivers & reservoirs)
  "endoEvap",      "endoEvap_mm_pgi",         # via open water evaporation from endorheic lakes (NB: endoEvap is in units of m3/pixel/day)
  
  # Storage: water retained on land, rivers, reservoirs
  "resStorage_mm",  "resStorage_mm_pgi",
  "endoStrg_mm",    "endoStrg_mm_pgi",    
  "irrRffStorage",  "surfRffStorage", "runoffStrg_mm_pgi",   # runoffStg = irrRffStorage + surfRffStorage
  "soilMoist",      "soilMoist_mm_pgi",
  "grdWater",       "grndWater_mm_pgi",
  
  # Irrigation
  "irrigationGross", "GrossIrr_mm_pgi", "GrossIrr_mm_pgn", "GrossIrr_mm_ps", "GrossIrr_mm_pr", "GrossIrr_mm_pu"   # water sources for irrigation
)

# Crop data for basin aggregation
crop.to.BAS.agg = c("crop_production", "Irrigated_crop_production")

###########################################################################################################################
### Variable lists for spatial aggregation to SUB-BASINS ###

# WBM simulation variables for sub-basin aggregation
wbm.to.SUB.agg = c(
  # Irrigation
  "irrigationGross", "GrossIrr_mm_pgi"   # water sources for irrigation
)

# Crop data for sub-basin aggregation
crop.to.SUB.agg = c("crop_production", "Irrigated_crop_production")

###########################################################################################################################
### BASIN aggregations ###

# make directories for all basin aggregate outputs
lapply(c(pygem.to.BAS.agg, wbm.to.BAS.agg, crop.to.BAS.agg), 
         FUN = function(x) create_dir(file.path("results/basin", x)))

# WBM spinup basin aggregation
lapply(spn.to.BAS.agg, FUN = function(x) extract_ts(raster.path   = path.spn,
                                                    monthly.files = 1,
                                                    shp           = basins,
                                                    years         = seq(2031, 2060), # just evaluate last 30 years to see if run stabilized
                                                    var           = x,
                                                    row.nm        = basins$name,
                                                    out.nm        = paste("results/basin", x, "/", x, "_spn_basins_2031_2060_m.csv", sep="")
                                                    )
       )

# WBM simulation basin aggregation
lapply(wbm.to.BAS.agg, FUN = function(x) extract_ts(raster.path   = path.sim,
                                                    monthly.files = 1,
                                                    shp           = basins,
                                                    years         = seq(1981, 2016), 
                                                    var           = x,
                                                    row.nm        = basins$name,
                                                    out.nm        = paste("results/basin", x, "/", x, "_basins_1981_2016_m.csv", sep="")
                                                    )
       )


# Crop production basin aggregation
lapply(crop.to.BAS.agg, FUN = function(x) spatial_agg_crops(file.nm = paste("data/GAEZ_2015_", x, ".nc", sep=""),
                                                            shp     = basins,
                                                            out.nm  = paste("results/basin/", x, "/", x, "_basin_2015_y.csv", sep="")
                                                            )
       )

