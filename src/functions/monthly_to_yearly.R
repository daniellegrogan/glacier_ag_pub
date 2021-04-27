# monthly_to_yearly()

# Input a time series data frame of monthly values, and output yearly sums
# assumes column header in format: XYYYY.MM.DD (typical output of spatial aggregation)

################################################################################################################
monthly_to_yearly = function(data.m, out.nm=NA){
  yr = as.numeric(substr(colnames(data.m), start=2, stop=5))
  
  if(is.na(yr[1])){
    yr = yr[2:length(yr)]
    data = data.m[,2:ncol(data.m)]
    agg.names = data.m[,1]
  }else{
    agg.names = NA
  }
  
  data.yr = data.frame(matrix(nr=nrow(data.m), nc=length(unique(yr))))
  colnames(data.yr) = unique(yr)
  
  for(i in 1:length(unique(yr))){
    data.sub = subset(data, select = c(yr == unique(yr)[i]))
    data.yr[,i] = rowSums(data.sub)
  }
  
  if(is.na(agg.names[1]) == T){
    out = data.yr
  }else{
    out = cbind(agg.names, data.yr)
  }
  colnames(out)[1] = "Basin"
  
  if(is.na(out.nm) == F){
    write.csv(out, out.nm)
    print(out.nm)
  }
  out
}
################################################################################################################

