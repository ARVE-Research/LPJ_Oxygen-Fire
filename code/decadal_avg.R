##############################################################
# Script to create a dataframe of 10-year averages ###########
##############################################################

# This script takes an .nc output file and creates a dataframe of 10-year averages
# for each gridcell from the last 10-years of the output file for a given variable.

decadalavg_mdf <- function(file, var, npft=0, path){

  source(paste(path,"matrix2df_function.R",sep=""))       # load matrix conversion to dataframe script
  nc = nc_open(file)                                      # open file
  
  if(nc$dim$time$len==10){tcheck=TRUE}else{tcheck=FALSE}                                                            # check if file is already 10-years or if cut is needed
  
  if (var == "mnfire" || var == "mieff"|| var == "mmofe" || var == "mfuelmoist"){mcheck = TRUE}else{mcheck=FALSE}   # check if variable includes monthly data
  
  if(var == "cover" || var == "pftalbiomass" || var == "forestcov"){pcheck=TRUE}else{pcheck=FALSE}                  # check if variable includes PFT dimensions
  
  if(var == "forestcov"){   # if var is forestcov the actual variable is cover 
    forestcov = TRUE        # forests calculated as tree cover 60% or more
    var = "cover"
  }else{forestcov=FALSE}
  
  ##################
  ## get variable ##
  ##################
  if(tcheck){ vdat = ncvar_get(nc, var)
  }else{
  if(mcheck || pcheck){
    vdat = ncvar_get(nc, var, start=c(1,1,1,491), count = c(-1,-1,-1,10))
  }else{
  vdat = ncvar_get(nc, var, start=c(1,1,491), count = c(-1,-1,10))}
  }
  
  #################
  # find averages #
  #################
  if(mcheck){
    
    # take sum of monthly values to get annual
    temp = array(0,dim=c(720,360,10))
    for (year in 1:10){
      for (month in 1:12){
        temp[,,year] = temp[,,year]+vdat[,,month,year]
      }
    }
    adat = temp
    
    # find 10-year annual average
    for (i in 1:10){
      if (i == 1){mavg = adat[,,i]/10}
      else{mavg = mavg + adat[,,i]/10}
    }
    
  }else if(pcheck){
    
    # if PFT then either specific PFT, forest (trees combined) or all 
    temp = array(0,dim=c(720,360,10))
    for (year in 1:10){
      if(forestcov){
        for (pft in 1:7){
          temp[,,year] = temp[,,year]+vdat[,,pft,year]}
      }else if (forestcov == FALSE && npft == 0){
        for (pft in 1:9){
          temp[,,year] = temp[,,year]+vdat[,,pft,year]}
      }else{
          temp[,,year] = temp[,,year]+vdat[,,npft,year]
      }
    }
    
    # find 10-year annual average
    for (i in 1:10){
      if (i == 1){mavg = temp[,,i]/10}
      else{mavg = mavg + temp[,,i]/10}
    }
    
  }else{
    # find 10-year annual average
    for (i in 1:10){
      if (i == 1){mavg = vdat[,,i]/10}
      else{mavg = mavg + vdat[,,i]/10}
    }
  }
  
  ##################################
  ## create dataframe from matrix ##
  ##################################
  mdf = matrix2df(t(mavg),lat=c(-89.75, 89.75))
  nc_close(nc)
  return(mdf)
}
