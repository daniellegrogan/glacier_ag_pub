# max_month()

# project: NASA HiMAT
# Danielle S Grogan

# calculate month of max value of a given variable
# use output of agg_contribution() applied to monthly time series as input here

max_month = function(var.m,          # monthly values
                     var,            # character string, e.g., "pgi"
                     unit            # character string, e.g., "km3" or "percent"
){
  var.months = subset(var.m,      select = grepl(paste(unit, var, sep="_"), colnames(var.m)))
  var.stdev  = subset(var.months, select = grepl("stdev", colnames(var.months)))
  var.unit   = subset(var.months, select = grepl("stdev", colnames(var.months)) == F)
  
  max.unit = apply(var.unit, c(1), max, na.rm=T)
  max.month = (var.unit == max.unit)
  max.month.id = apply(max.month, MARGIN = c(1), FUN = function(x) which(x == max(x, na.rm=T)))
  month.names = c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
  max.month.out = cbind(names(max.unit), month.names[max.month.id], as.numeric(max.unit))
  colnames(max.month.out) = c("Basin", "Month_of_Max", "Max_Value")
  out = max.month.out
}
  
