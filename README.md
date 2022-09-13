# LPJ_Oxygen-Fire model output and postprocessing code for oxygen-fire simulation experiments for testing the upper limit of the fire window

This repository contains output from simulations performed with the LPJ-LMfire dynamic global vegetation model to investigate the response of vegetation under varying atmospheric oxygen concentrations due to fire. This output and included code were used to create the figures shown in Vitali et al. (in review).

Vitali, R., Belcher, C. M., Kaplan, J. O., & Watson, A. J. (in review). Redefining the fire window: Higher atmospheric oxygen concentrations are compatible with the presence of forests. *Nature Communications*.

The raw model output (`.nc` files) in this repository are stored using the Git Large File Storage (Git LFS) extension. Cloning the repository therefore requires the user to have `git lfs` installed. More information regarding Git LFS can be found [here](https://git-lfs.github.com).

The model processing codes are written as `R` scripts and therefore require `R` to be [installed](https://www.r-project.org). Note that the scripts included here have been tested and ran on `R version 4.1.2`. Postprocessing of the data is then split into two steps:
1. **create O2_global_totals.xlsx spreadsheet**
2. **create figures shown in manuscript**


## Creating O2_global_totals.xlsx spreadsheet

Created by running the script `fire_O2_spreadsheet.R` which reads raw output and creates a spreadsheet of global totals/averages for each oxygen concentration. 

All that should be required to run is setting the data and script directories marked at the beginning of the script (note that these directories can be the same and that the spreadsheet is saved in the set data directory). Requires `ncdf4`, `openxlsx` and `reshape2` packages to be installed and calls on `decadal_avg.R`, `matrix2df_function.R` and `global_total_function.R` scripts (see file descriptions below).

Running time of script should be <2 minutes and a complete version of `O2_global_totals.xlsx` is provided for comparison.  

## Reproducing figures from the manuscript

Figures can be reproduced by running the `fire_window.R` script and can be ran after creating the spreadsheet above, or independently (spreadsheet included). Plots created are:

1. global forest cover for 20.95% and 35% vol. O2
2. line plots showing global total/average number of fires, burned area and forest suppression by fire over varying O2 concentrations
3. global rate of fire spread for 20.95% and 35% vol. O2
4. global fuel moisture under 35% vol. O2 and global average rate of fire spread for different bands of fuel moisture

In order to run the script, the following `R` packages are required: `ncdf4`,`ggplot2`,`reshape`,`readxl`,`rgdal`,'gridExtra',`colorspace`,`gtable`,`RColorBrewer`& `cowplot`. Running of script should take ~2 minutes and calls on `matrix2df_function.R` and `global_total_function.R` scripts (see file descriptions below).  

Figures which include global maps (1,3 & 4) also require land shapefiles that have been provided in the [ndata/ne_110m_land](data/ne_110m_land) directory but are available from [Natural Earth vector and raster data](https://www.naturalearthdata.com/downloads/110m-physical-vectors/110m-land/).

## File descriptions
Filename       | Description
-------------  | -------------
.nc files      | raw output from LPJ-LMfire simulations
ne_110m_land   | folder holding shapefiles for world map outline used in global plots
O2_global_total.xlsx | spreadsheet containing global totals/averages from last decade of simulations for varying atmopsheric oxygen concentrations
fire_O2_spreadsheet | R script to create O2_global_total.xlsx spreadsheet
decadal_avg.R | R script to create a dataframe of 10-year averages 
matrix2df_function.R | R script containing a function to turn matrix into dataframe
global_total_function.R | R script containing function to find value for global totals
fire_window.R | R script to create figures displayed in Vitali et al manuscript. 

This work is licensed under a [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)
