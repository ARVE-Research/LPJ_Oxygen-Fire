##########################################################
### function to find value for global totals #############
##########################################################

# function that takes a data frame of values for each gridcell and returns global total or average value
# dependent on variable type (defined in input to function)

global_total = function(df,FRAC=FALSE,BIO=FALSE,PFT=FALSE,COUNT=FALSE,FOREST=FALSE,AVG=FALSE,LAT="none"){

######################################
## FUNCTION TO FIND AREA OF A CELL: ##
######################################
gridarea = function(lat){
  area = ((111000^2)*0.5*0.5)*cos(lat*(pi/180))
  return(area)
}

area_df=array(0,dim=c(length(df[,1])))  # empty array to store gridcell areas
for (i in 1:length(df[,1])){            # calculate the area of each gridcell
  area_df[i] = gridarea(df[i,1])
}

### FIND TOTAL FRACTIONAL COVERAGE #######################
if (FRAC == TRUE || AVG == TRUE){
  
  # if latitude is defined in input, calculates total fractional coverage for given latitude band
  if(LAT == "high"){                                     
    df = df[-which(df$lat.value>(-60) & df$lat.value<60),]
  }else if (LAT == "mid"){
    df = df[c(which(df$lat.value>30 & df$lat.value<60),which(df$lat.value>(-60) & df$lat.value<(-30))),]
  }else if (LAT == "low"){
    df = df[which(df$lat.value>(-30) & df$lat.value<30),]
  }
  
  total_area = sum(area_df)               # find total global area of defined gridcells
  fracarea = area_df/total_area           # calculate the fraction that each gridcell is of total area
  data = fracarea*df[,3]                  # find fraction of coverage 
  return(sum(data))                       # Find sum of this for total coverage
}

## FIND TOTAL BIOMASS ##################################
if (BIO == TRUE){
  tbio = df$z.value*area_df*1e-15        # Multiply biomass by area to find total biomass in cell (Pg)
  return(sum(tbio))                      # Find sum of this for total coverage
}

## FIND TOTAL PFT FRACTIONAL COVERAGE ##################
if(PFT==TRUE){
  tpft = df$z.value*area_df/1000000     # times area by pft frac so we find total frac in each cell (km2)
  return(sum(tpft))                     # find sum of total cover
}

## FIND TOTAL FOREST COVER #############################
if(FOREST==TRUE){
  
  # if latitude is defined in input, calculates total fractional coverage for given latitude band
  if(LAT == "high"){
    df = df[-which(df$lat.value>(-60) & df$lat.value<60),]
  }else if (LAT == "mid"){
    df = df[c(which(df$lat.value>30 & df$lat.value<60),which(df$lat.value>(-60) & df$lat.value<(-30))),]
  }else if (LAT == "low"){
    df = df[which(df$lat.value>(-30) & df$lat.value<30),]
  }
  
  tpft = df$z.value*area_df/1000000     # times area by pft frac so we find total frac in each cell (km2)
  return(sum(tpft))                     # find and return the sum of forest cover
}

## FIND TOTAL GLOBAL NUMBER OF VARIABLE ################  
 if(COUNT == TRUE){
   num=df$z.value                       # get variable data which includes number of variable for each gridcell
   return(sum(num))                     # find total value and return
 }
}

