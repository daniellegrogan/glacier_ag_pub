# extract_ts()
# wrapper on spatial_aggregation()

# project: NASA HiMAT
# Danielle S Grogan

library(raster)
rasterOptions(tmpdir = "/net/usr/spool/")   # set alternative /tmp directory
library(rgdal)
library(rgeos)

extract_ts = function(raster.path, # path to wbm output
                      monthly.files = 0, # binary: 1 or 0 indicating the structure of WBM output files for monthly time series
                                         # 0 := files are 1 file per year, 12 layers (temporal aggregate of WBM daily output)
                                         # 1 := files are 1 file per month, with file structure montyly/YYYY/YYYY-MM.nc
                      shp,         # shapefile for spatial aggregation
                      years,       # sequence of years
                      var = NA,    # only needed if wbm file has more than one variables in it; variable name to load
                      s=1,         # sum = 1 (set to 0 for average spatial aggregation)
                      cell.area = 1, 
                      weight = T, 
                      poly.out = F,
                      row.nm = NA,    # characters; typically the basin names
                      out.nm = NA,    # out.nm = character string; if provided, results are written to file
                      check.file = 1, # 1 or 0; if 1, exits if file exists.  Requires and out.nm (not NA)
                      return.df  = 0) # 1 or 0; if 1, returns the data frame made by the function. If 0, does not return the data frame
{  
  

  if(file.exists(out.nm) & check.file == 1){  # if the file exists, and check.file = 1, then just read in the file.
    out = read.csv(out.nm)
    print(paste(out.nm, "already exists"))
    
  }else{                                      # otherwise, do the aggregation
    region = gUnaryUnion(shp, id = rep(1, length(shp)))
    
    if(grepl("yearly", c(raster.path))){
      
      if(sum(is.na(years)) == 1){ # if years are not specified, use all years 
        file.list = list.files(path = path, full.names = T)
        
      }else{ # otherwise subset the list of files to those with the specified years
        file.list.full = list.files(path = raster.path, full.names = T)
        file.yrs = substr(file.list.full, start = nchar(file.list.full)-6, stop= nchar(file.list.full)-3)
        file.list = file.list.full[as.numeric(file.yrs) %in% years]
      }
      
      # load all yearly files into a raster brick
      brk = do.call(stack,
                    lapply(file.list, 
                           raster::brick))
      
      brk = 365*brk   # convert average mm/day over the year to mm/year
      
      # column names
      dt.cols =  seq(from = as.Date(paste(min(years), "-01-01", sep="")), 
                     to   = as.Date(paste(max(years), "-12-01", sep="")), 
                     by   = "year")
      
    }else if(grepl("monthly", c(raster.path))){
      
      if(monthly.files == 0){
        
        if(sum(is.na(years)) == 1){
          file.list = list.files(path = raster.path, full.names = T)
        }else{
          file.list.full = list.files(path = raster.path, full.names = T)
          file.yrs = substr(file.list.full, start = nchar(file.list.full)-6, stop= nchar(file.list.full)-3)
          file.list = file.list.full[as.numeric(file.yrs) %in% years]
        }
        
      }else if(monthly.files == 1){
       
         if(sum(is.na(years)) == 1){ # if years are not specified, use all years 
          dir.list = dir(raster.path, full.names = T)      # in this file structure, there are directories for each year. List the directories
          file.list = unlist(lapply(dir.list, FUN=list.files, full.names = T)) # list files
        }else{
          dir.list.full = dir(raster.path, full.names = T) # list all directories
          dir.list.yrs = subset(dir.list.full,      # subset to those with names that match the "years" specified
                                as.numeric(
                                  substr(dir.list.full, 
                                         start = nchar(dir.list.full)-3, 
                                         stop = nchar(dir.list.full))) 
                                %in% years)
          file.list = unlist(lapply(dir.list.yrs, FUN=list.files, full.names = T)) # list files
        }
      }
      
      
      # load all files into a raster brick
      brk = do.call(stack,
                    lapply(file.list, 
                           raster::brick, 
                           varname = var))
      
      # x days-per-month to convert from ave/month to total per month
      month.data = read.csv("data/days_in_months.csv")
      brk = month.data$days*brk
      
      # column names
      dt.cols =  seq(from = as.Date(paste(min(years), "-01-01", sep="")), 
                     to   = as.Date(paste(max(years), "-12-01", sep="")), 
                     by   = "month")
      names(brk) = dt.cols
      # names(brk) = dt.cols[1:length(names(brk))] # temporary fix while Alex figures out leap year bug
    
    }else if(grepl("daily", c(raster.path))){
      
      if(sum(is.na(years)) == 1){
        file.list = list.files(path = raster.path, full.names = T)
      }else{
        file.list.full = list.files(path = raster.path, full.names = T)
        file.yrs = substr(file.list.full, start = nchar(file.list.full)-6, stop= nchar(file.list.full)-3)
        file.list = file.list.full[as.numeric(file.yrs) %in% years]
      }
      
      brk = do.call(stack,
                    lapply(file.list, 
                           raster::brick, 
                           varname = var))
      
      # column names
      dt.cols =  seq(from = as.Date(paste(min(years), "-01-01", sep="")), 
                     to   = as.Date(paste(max(years), "-12-31", sep="")), 
                     by   = "day")
      
    }
    
    s1 = spatial_aggregation(brk, shp,    s, cell.area, weight, poly.out)
    s2 = spatial_aggregation(brk, region, s, cell.area, weight, poly.out)
    
    row.names = c(row.nm, "all_basins")
    
    out = rbind(s1,s2)
    out = cbind(row.names, out)
    colnames(out) = c("Basin", as.character(dt.cols))
    #colnames(out) = c("Basin", as.character(dt.cols)[1:length(names(brk))]) # temporary
    
    if(is.na(out.nm) == F){
      # make a date sequence for the column names. assume full years (Jan through Dec)
      write.csv(out, out.nm, row.names = F)
      print(paste(out.nm, "written to file"))
    }
  }

  if(return.df == 1){
    return(out)
  }
  removeTmpFiles(h=6) # remove temporary files older than 6 hours
}

