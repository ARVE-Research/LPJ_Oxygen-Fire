#####################################################
### script to create O2_global_totals.xlsx ##########
#####################################################

# creates a spreadsheet that holds global total values from a 10-year annual average for forest cover, number of fires and burned area
# also gives normalised (around PAL 20.95% O2) values as well as forest cover suppression which is defined to be the % of forests removed
# by fire compared to a world without fire (16% O2)

#load libraries
library(ncdf4)
library(openxlsx)


#### CHANGE HERE ####################################
# directories
datapath   <- "D:/LPJLMfire/Output/oxygen_fire/"                                      # path where data is stored
scriptpath <- "C:/Users/rv237/OneDrive - University of Exeter/PhD/Code/R/LPJ_R_code/" # path where R scripts are stored

# load needed functions 
source(paste(scriptpath,"decadal_avg.R",sep=""))            # function to create 10-year average dataframe fro data
source(paste(scriptpath,"global_total_function.R",sep=""))  # function to calculate global total/average values

# parameters needed to create spreadsheet
oxygen = c(16,20.95,22,23,24,25,26,27,28,29,30,31,32,33,34,35)
varnames = c("forestcov","mnfire","burnedf")


###################################################
### Find global total values for decadal average ##
###################################################

# create temporary matrix to store values for each variable
tempvar = matrix(ncol = length(varnames), nrow = length(oxygen))
  
  # loop over vars
  for (v in 1:length(varnames)) {
    var = varnames[v]
    
    # set temporary array to hold global totals for each O2 concentration
    tempox = array(0,length(oxygen))
    
    # loop over oxygen concentration
    for (o in 1:length(oxygen)) {
      ox = oxygen[o]
      
      setwd(paste(datapath))                 # set correct working directory
      oxfile=(paste(ox,"_fire_july22.nc",sep=""))  # get correct file
      mdf = decadalavg_mdf(oxfile,var,path = scriptpath)       # create dataframe of decadal averages
      
      # calculate total global values for variable and store for O2 concentration
      if(var == "forestcov"){
        mdf$z.value[which(mdf$z.value<0.6)] = 0        # forests defined to be tree cover of 60% or more
        mdf$z.value[which(mdf$z.value>=0.6)] = 1       # set gridcells to be either forest or not
        tempox[o] = global_total(mdf, FOREST = TRUE)   # global total forest cover (km2)
        
      }else if(var == "mnfire"){
        tempox[o] = global_total(mdf, COUNT = TRUE)    # global number of fires
        
      }else{tempox[o] = global_total(mdf, PFT = TRUE)} # 
    }
    
    tempvar[,v]=tempox   # store all oxygen data for this variable in matrix
  }
  
###################################################
### Normalize burned area and number of fires #####
###################################################

normval = matrix(ncol = 2, nrow = length(oxygen))    # create matrix to store data

for (i in 2:3){                                      # loop over no. of fires and burned area
  PALval = tempvar[2,i]
  for (o in 2:length(oxygen)){
    normval[o,(i-1)] = tempvar[o,i]/PALval
  }
}

###################################################
### calculate fire suppression on forest cover ####
###################################################

supval = c()                                        
nofireval = tempvar[1,1]                                                    # forest cover in world without fire
for (o in 1:length(oxygen)){ supval[o] = (1-(tempvar[o,1]/nofireval))*100}  # find % of forest cover suppressed by fire for O2 concentration


###############################
### build dataframe and save ##
###############################

df  = data.frame(oxygen, tempvar[,1],supval,tempvar[,2],tempvar[,3],normval[,1],normval[,2])
colnames(df) = c("O2 concentration (%)", "Forest cover (km2)","forest suppression (%)","Annual number of fires","Annual burnt area (km2)",
                 "Annula number of fires norm","Annual burnt area norm")
  
# set working directory
setwd(datapath)
  
# for writing a data.frame or list of data.frames to an xlsx file
write.xlsx(df, "O2_global_totals.xlsx")

