################################################
## Function to make matrix into dataframe ######
################################################

# takes matrix and converts it into a dataframe
# functions inputs include defined lat lon, resolution of model, whether or not 
# matrix is to include PFTs (fpc = foliar projected cover) 

matrix2df = function(matrix,lat=c(-55.75, 83.75),lon=c(-179.75, 179.75),res=0.5, fpc=FALSE){
  
  # Load library needed:  
  library(reshape2)
  
  # Find and save dimensions of matrix:
  if(fpc == TRUE){
    cols <- 720
    rows <- 350
    cells <- rows*cols
  }else{
    cols <- length(matrix[1,])
    rows <- length(matrix[,1])
    cells <- rows*cols 
  }
  
  ################################################# 
  ## Create matrices for latitude and longitude ###
  #################################################
  
  # First for longitude:
  lon_grid <- array(NA, dim=c(rows,cols))
  
  # fill longitude a column at a time so that it repeats vertically, changes horizontally
  for( i in 1:rows){
    lon_grid[i,] <- seq(lon[1], lon[2], by = res)
  }
  
  # for latitude:
  lat_grid <- array(NA, dim=c(rows,cols))
  
  #Fill row at time so that it repeats horizontally, changes vertically
  for( i in 1:cols){
    lat_grid[,i] <- seq(lat[1], lat[2], by = res)
  }
  

  ##############################################
  ## melt and combine matrices into dataframe ##
  ##############################################
  if(fpc == TRUE){
  
  Titles=c("lat","lon","Fraction of natural vegetation","Tropical broadleaved evergreen tree","Tropical broadleaved raingreen tree",
           "Temperate needleleaved evergreen tree","Temperate broadleaved evergreen tree","Temperate broadleaved summergreen tree",
           "Boreal needleleaved evergreen tree","Boreal broadleaved summergreen tree","Boreal needleleaved summergreen tree",
           "Tropical herbaceous (C4)","Temperate herbaceous (C3)","Polar herbaceous (C3)")
  
  lat = melt(as.data.frame(lat_grid))
  lon = melt(as.data.frame(lon_grid))
  
  data=data.frame(lat$value,lon$value)
  
   for (i in 1:12){
    dat = t(matrix[,,i])
    pft = melt(as.data.frame(dat))
    data = data.frame(data, pft$value)
    }
  
  df = na.omit(data)
  colnames(df)=Titles
  
  }
    else{
    z <- melt(as.data.frame(matrix))
    lat = melt(as.data.frame(lat_grid))
    lon = melt(as.data.frame(lon_grid))
    data1=data.frame(lat$value,lon$value,z$value)
    df=na.omit(data1)
    }

return(df)
}