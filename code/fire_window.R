#######################################
## A new higher limit R Script ########
#######################################
# Script to plot manuscript figures
# Requires O2_global_totals.xlsx file created through running fire_O2_spreadsheet.R script

# Load relevent libraries
library(ncdf4)
library(ggplot2)
library("readxl")
library(reshape)
library(rgdal)
library(gridExtra)
library(colorspace)
library(gtable)
library(RColorBrewer)
library(cowplot)
library(reshape)

#### CHANGE HERE ####################################
# directories
datapath   <- "D:/LPJLMfire/Output/oxygen_fire/"                                      # path where data is stored
scriptpath <- "C:/Users/rv237/OneDrive - University of Exeter/PhD/Code/R/LPJ_R_code/" # path where R scripts are stored
plotpath   <- "C:/Users/rv237/OneDrive - University of Exeter/PhD/Plots/"             # path to store figs 
setwd(datapath)                                                                       # set working directory:

# Load function to transfer matrix to dataframes:
source(paste(scriptpath,"matrix2df_function.R",sep=""))
source(paste(scriptpath,"global_total_function.R",sep=""))

# Function to save a legend seperately from a plot
g_legend<-function(a.gplot){
  tmp <- ggplot_gtable(ggplot_build(a.gplot))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  legend <- tmp$grobs[[leg]]
  return(legend)}

# labels for plots
labplot = c("a","b","c")


#############################################################
## Figure 1 #################################################
#############################################################
# plot showing global forest cover for 20.95 and 35% vol. O2

varname    = "cover"        # set variable to be PFT cover
oxygen     = c(20.95,35)    # set oxygen concentrations to plot
plots = c()                 # arrays to store plots in:
diffs = c()
mdf = c()

# loop over each PFT (9 PFTs and 2 extra)
for (pft in 1:11){
  
  # Loop over each oxygen concentration
  for (ox in 1:length(oxygen)){
    
    # select file needed
    oxfile= nc_open(paste(oxygen[ox],"_fire_july22.nc",sep=""))
    
    # check size of output and get last 10 years accordingly
    if (oxfile$dim$time$len == 100){
      v = ncvar_get(oxfile, paste(varname), start=c(1,1,1,1),count=c(-1,-1,-1,10))      # only load 10-years data to save space and time
    }else{v = ncvar_get(oxfile, paste(varname), start=c(1,1,1,1),count=c(-1,-1,-1,10))}
    
    # close file
    nc_close(oxfile)
    
    # calculate 10-year average
    for (i in 1:10){
      if (i == 1){mavg = v[,,,i]/10}
      else{mavg = mavg + v[,,,i]/10}
    }
    
    if(pft == 10){                                                                  # save grass and tree cover
      mavg = mavg[,,8]+mavg[,,9]                                                    # Select grasses (sum of PFT 8 and 9)
    }else if(pft == 11){                                                            # Select trees (sum of PFT 1:7) 
      mavg = mavg[,,1]+mavg[,,2]+mavg[,,3]+mavg[,,4]+mavg[,,5]+mavg[,,6]+mavg[,,7]
      mdf[[ox]] = matrix2df(t(mavg),lat=c(-89.75, 89.75))                           # save tree cover data as dataframe:
    }else{mavg = mavg[,,pft]}
    
  }
} 

bscale=c(-1,0.001,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,Inf)    # Scale for fractional coverage

# Create plots
for (ox in 1:2){
  
  # make breaks
  mdf[[ox]]$breaks = cut(mdf[[ox]]$z.value,breaks= bscale)
  unit = "fraction of gridcell"
  
  # make plot
  plots[[ox]] = ggplot(mdf[[ox]], aes_(mdf[[ox]]$lon.value,mdf[[ox]]$lat.value,fill=mdf[[ox]]$z.value))+geom_raster(interpolate = TRUE)+
    scale_fill_gradientn("Tree Cover (%)",colours = c("white",brewer.pal(9,"Greens")),
                         breaks = c(0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1), limits=c(0,1), labels =c("0","10","20","30","40","50","60","70","80","90","100"))+
    xlab("")+ylab("")+
    theme(  
      legend.title = element_text(size = 7),
      legend.position = "bottom",
      legend.key.width = unit(1, "cm"),
      legend.spacing.x = unit(1, 'cm'),
      legend.key.height = unit(.5,"cm"),
      legend.text  = element_text(size = 6),
      panel.border = element_rect(fill = NA),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      panel.background = element_rect(fill = "slategray1"),
      axis.line = element_blank(),
      axis.text = element_blank(),
      axis.ticks = element_blank(),
      plot.title = element_text(size=8, face = "bold"),
      plot.margin = unit(c(0.1,0.1,0.1,0.1), "cm")
    )+
    
    ggtitle(paste(labplot[ox]))+
    coord_equal(ylim = c(-57,84))
}

# grab legend from plot
leg = gtable_filter(ggplot_gtable(ggplot_build(plots[[1]])), "guide-box")
leg <- get_legend(plots[[2]])

# stack plots
grid.arrange(
  arrangeGrob(plots[[1]] + theme(legend.position = "none", plot.margin=unit(c(0.2,0,0.2,-0.5), "cm")),
              plots[[2]] + theme(legend.position = "none", plot.margin=unit(c(0.2,0,0.2,-0.5), "cm")), nrow =2),
  leg, nrow=2,heights = c(10,1), top=""
)


#########################################
## Figure 2 #############################
#########################################
# plots showing normalized number of fires and burnt area as well as forest
# suppression over different O2 concentrations

my_data <- read_excel("O2_global_totals.xlsx")     # load data from spreadsheet
nrow=length(my_data$`O2 concentration (%)`) - 2    # length of data 
ox = my_data$`O2 concentration (%)`                # load O2 levels
fsup = my_data$`forest suppression (%)`            # load forest suppression
fcov = my_data$`Forest cover (km2)`                # load forest cover
nfire = my_data$`Annula number of fires norm`      # load no.of fires normalized
barea = my_data$`Annual burnt area norm`           # load burned area normalized 
df = data.frame(ox, fsup,fcov,nfire,barea)         # create data frame

# create forest suppression plot
supplot =  ggplot()+geom_line(aes(df$ox, df$fsup)) + 
  geom_point(aes(df$ox, df$fsup), shape = 4) +
  xlab("Oxygen (% of atmosphere)")+ylab("forest cover supression (%)")+
  scale_y_continuous(breaks = seq(0, 60, by = 20),limits = c(0,60))+
  scale_x_continuous(breaks = seq(20, 35, by = 5),limits = c(20.5,35))+
  ggtitle(paste(labplot[2]))+
  theme(  
    panel.border = element_rect(fill = NA),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.background = element_blank(),
    axis.text = element_text(size = 6),
    axis.title.y = element_text(margin = margin(t = 0, r = 5, b = 0, l = 0)),
    axis.title.x = element_text(margin = margin(t = 5, r = 0, b = 0, l = 0)),
    axis.title = element_text(size = 7,vjust=-5),
    # text = element_text(family="Times"),
    plot.title = element_text(size=8, face="bold"),
    plot.margin = unit(c(0.1,0.1,0.1,0.1), "cm")
  )

df2=  data.frame(ox, nfire,barea)   # put data together for second plot
mdf = melt(df2, id="ox")

# create plot for no of fires and burned area
duoplot = ggplot()+geom_line(aes(mdf$ox, mdf$value, linetype = mdf$variable)) + 
  geom_point(aes(mdf$ox, mdf$value, shape = mdf$variable)) + 
  xlab("Oxygen (% of atmosphere)")+
  ylab("normalised around PAL")+
  ggtitle(paste(labplot[1]))+
  scale_linetype_manual("",values = c("solid","dashed"), labels = c("number of fires", "burned area"))+
  scale_shape_manual("",values = c(4,26), labels = c("number of fires", "burned area"))+
  scale_x_continuous(breaks = seq(20, 35, by = 5),limits = c(20,35))+
  theme(  
    legend.position = c(0.2,0.8),
    legend.background = element_blank(),
    legend.margin = margin(0.1, 5, 0.2, 0.2),
    legend.key.height=unit(0.3, "cm"), 
    legend.key.width = unit(0.5, "cm"),
    legend.box.background = element_rect(colour = "black"),
    legend.title = element_blank(),
    legend.text = element_text(size = 6),
    legend.key = element_rect(colour = NA, fill = NA),
    panel.border = element_rect(fill = NA),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.background = element_blank(),
    axis.text = element_text(size = 6),
    axis.title.y = element_text(margin = margin(t = 0, r = 5, b = 0, l = 0)),
    axis.title.x = element_text(margin = margin(t = 5, r = 0, b = 0, l = 0)),
    axis.title = element_text(size = 7,vjust=-5),
    plot.title = element_text(size=8, face="bold"),
    plot.margin = unit(c(0.1,0.1,0.1,0.1), "cm")
  )

# stack plots
grid.arrange(
  arrangeGrob(duoplot + theme(plot.margin=unit(c(0,0.15,0.2,0.1), "cm")),
              supplot + theme(plot.margin=unit(c(0.1,0.15,0.1,0.1), "cm")),
              nrow =2), top="")

#########################################
## Figure 3 #############################
#########################################
# plots showing global rate of fire spread for PAL and 35% vol. O2

varname1    = "mfuelmoist"   # set up variables and arrays to use
varname2    = "mROS"         # Here load data for next plot too 
oxygen = c(20.95,22,23,24,25,26,27,28,29,30,31,32,33,34,35)
avg = c()
avg2=c()
mdf=c()
mdf2=c()
vardat = c()
vardat2 = c()

# Load variable data for each oxygen level 
for (ox in 1:length(oxygen)){
  oxfile= nc_open(paste(oxygen[ox],"_fire_july22.nc",sep=""))
  vardat[[ox]] = ncvar_get(oxfile, paste(varname1), start=c(1,1,1,1),count=c(-1,-1,-1,10)) # only load 10-years data to save space and time
  vardat2[[ox]] = ncvar_get(oxfile, paste(varname2), start=c(1,1,1,1),count=c(-1,-1,-1,10))
  nc_close(oxfile)
}

#find 10-year annual average from monthly data for this oxygen concentration and variable
for (ox in 1:length(oxygen)){
  
  # select file needed
  v = vardat[[ox]]
  v2 = vardat2[[ox]]
  
  for (year in 1:10){
    for (month in 1:12){
      if (year == 1 && month == 1){
        mavg = v[,,month,year]/120                            # Find monthly average for 10-year period
        mavg2 = v2[,,month,year]/120
      }else{mavg = mavg + v[,,month,year]/120
      mavg2 = mavg2 + v2[,,month,year]/120}   
    }
  }

  mdf[[ox]] = matrix2df(t(mavg),lat=c(-89.75, 89.75))         # convert to data frame
  mdf2[[ox]] = matrix2df(t(mavg2),lat=c(-89.75, 89.75))
  
  # create breaks in fuel moisture for 21%
  breaks = cut(mdf[[1]]$z.value,breaks= c(-1,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,Inf), 
               labels=c("0-10","10-20", "20-30", "30-40", "40-50", "50-60", "60-70", "70-80","80-90","90+"))
  mdf[[ox]]$breaks = breaks
  mdf2[[ox]]$breaks = breaks
  
  # find global average values for each moisture band for given O2 level
  avg$a[ox] = global_total(mdf2[[ox]][which(mdf2[[ox]][,4] == "0-10"),],AVG=TRUE)
  avg$b[ox] = global_total(mdf2[[ox]][which(mdf2[[ox]][,4] == "10-20"),],AVG=TRUE)
  avg$c[ox] = global_total(mdf2[[ox]][which(mdf2[[ox]][,4] == "20-30"),],AVG=TRUE)
  avg$d[ox] = global_total(mdf2[[ox]][which(mdf2[[ox]][,4] == "30-40"),],AVG=TRUE)
  avg$e[ox] = global_total(mdf2[[ox]][which(mdf2[[ox]][,4] == "40-50"),],AVG=TRUE)
  avg$f[ox] = global_total(mdf2[[ox]][which(mdf2[[ox]][,4] == "50-60"),],AVG=TRUE)
  avg$g[ox] = global_total(mdf2[[ox]][which(mdf2[[ox]][,4] == "60-70"),],AVG=TRUE)
  avg$h[ox] = global_total(mdf2[[ox]][which(mdf2[[ox]][,4] == "70-80"),],AVG=TRUE)
  avg$i[ox] = global_total(mdf2[[ox]][which(mdf2[[ox]][,4] == "80-90"),],AVG=TRUE)
  avg$j[ox] = global_total(mdf2[[ox]][which(mdf2[[ox]][,4] == "90+"),],AVG=TRUE)
  avg$all[ox] = global_total(mdf2[[ox]],AVG=TRUE)
}

# arrays to help plots
oxnum = c(1, length(oxygen))
rosplot = c()

# loop over the twp different oxygen concentrations
for (i in 1:2){
mdf2[[oxnum[i]]]$breaks = cut(mdf2[[oxnum[i]]]$z.value,breaks= c(-1,0.01,5,10,20,50,100,Inf), 
                 labels=c("0","0-5", "5-10", "10-20","20-50", "50-100", "100+"))

# create rate of spread plot
rosplot[[i]] =ggplot(mdf2[[oxnum[i]]], aes_(mdf2[[oxnum[i]]]$lon.value,mdf2[[oxnum[i]]]$lat.value,fill=mdf2[[oxnum[i]]]$breaks))+geom_raster(interpolate = TRUE)+
  scale_fill_manual(values=c("white","#FBEDE6", "#F4CFB3","#E89167", "#E16D34","#D94801","#8C2D04"), name=expression(paste("m min"^-1, sep="")))+
  xlab("")+ylab("")+
  theme(  
    legend.title = element_text(size = 7),
    legend.position = "bottom",
    legend.key.width = unit(1, "cm"),
    legend.spacing.x = unit(0.3, 'cm'),
    legend.key.height = unit(0.3,"cm"),
    legend.key = element_rect(colour="black"),
    legend.text  = element_text(size = 6),
    panel.border = element_rect(fill = NA),
    panel.background = element_rect(fill = "slategray1"),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.line = element_blank(),
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    plot.title = element_text(size=8, face="bold")
  )+
  guides(fill = guide_legend(nrow=1,label.position = "bottom"))+
  ggtitle(paste(labplot[i]))+
  coord_equal(ylim = c(-57,84))
}

# grab legend from plot 
leg <- get_legend(rosplot[[2]])

# stack plots and share the legend
grid.arrange(
  arrangeGrob(rosplot[[1]] + theme(legend.position = "none", plot.margin=unit(c(0.2,0,0.2,-0.5), "cm")),
              rosplot[[2]] + theme(legend.position = "none", plot.margin=unit(c(0.2,0,0.2,-0.5), "cm")), nrow =2),
  leg, nrow=2,heights = c(10,1), top=""
)


#########################################
## Figure 4 #############################
#########################################
# plots showing global fuel moisture content at 35% vol O2
# and how different bands of fuel moisture effect rate of fire spread over O2

# combine data loaded above for fuel moisture with oxygen
datdf = data.frame(oxygen,avg)

# combine different moisture bands
datdf$one = (datdf$a + datdf$b)/2
datdf$two = (datdf$c + datdf$d)/2
datdf$three = (datdf$e + datdf$f)/2
datdf$four = (datdf$g + datdf$h)/2
datdf$five = (datdf$i + datdf$j)/2

# create global plot for decadal average fuel moisture
dat = mdf[[length(oxygen)]]
dat$breaks = cut(mdf[[1]]$z.value,breaks= c(-1,0.2,0.4,0.6,0.8,Inf), 
                 labels=c("0-20","20-40", "40-60", "60-80","80+"))

# create global plot
fmoistplot = ggplot(dat,aes_(dat$lon.value, dat$lat.value, fill = dat$breaks))+ geom_raster(interpolate = TRUE)+
  scale_fill_manual(values=c("#DEEBF7","#C6DBEF","#6BAED6","#2171B5","#08306B"), name = "fuel moisture (%)")+
  xlab("")+ylab("")+
  coord_equal()+
  ggtitle(paste(labplot[1]))+
  theme(  
    legend.title = element_text(size = 7),
    legend.position = "right",
    legend.box.background = element_rect(colour = "black"),
    legend.key.width = unit(0.5, "cm"),
    legend.key.height = unit(0.3,"cm"),
    legend.text  = element_text(size = 6),
    panel.border = element_rect(fill = NA),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = "gray80"),
    axis.line = element_blank(),
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    plot.title = element_text(size=8, face="bold"),
    plot.margin = unit(c(0.1,0.1,0.1,0.1), "cm")
  )


# create line plot
moistplot =ggplot()+geom_line(aes_(datdf$oxygen, datdf$all, col = "global"),lwd = 0.2)+
  geom_point(aes_(datdf$oxygen, datdf$all, col = "global", shape = "global"), size = 0.75)+
  geom_line(aes_(datdf$oxygen, datdf$one, col="0-20"),lwd = 0.2)+
  geom_point(aes_(datdf$oxygen, datdf$one, col = "0-20", shape = "0-20"), size = 0.75)+
  geom_line(aes_(datdf$oxygen, datdf$two, col="20-40"),lwd = 0.2)+
  geom_point(aes_(datdf$oxygen, datdf$two, col = "20-40", shape = "20-40"), size = 0.75)+
  geom_line(aes_(datdf$oxygen, datdf$three, col="40-60"),lwd = 0.2)+
  geom_point(aes_(datdf$oxygen, datdf$three, col = "40-60", shape = "40-60"), size = 0.75)+
  geom_line(aes_(datdf$oxygen, datdf$four, col="60-80"),lwd = 0.2)+
  geom_point(aes_(datdf$oxygen, datdf$four, col = "60-80", shape = "60-80"), size = 0.75)+
  geom_line(aes_(datdf$oxygen, datdf$five, col="80+"),lwd = 0.2)+
  geom_point(aes_(datdf$oxygen, datdf$five, col = "80+", shape = "80+"), size = 0.75)+
  scale_colour_manual("fuel moisture (%)",values  = c("global"="black","0-20"="#DEEBF7","20-40"="#C6DBEF","40-60"="#6BAED6","60-80"="#2171B5","80+"="#08306B"))+
  scale_shape_manual("fuel moisture (%)", values = c("global"=4,"0-20"=4,"20-40"=4,"40-60"=4,"60-80"=4,"80+"=4))+
  xlab("Oxygen (% of atmosphere)")+
  ylab("Rate of spread (m/min)")+
  scale_x_continuous(breaks=seq(20,45,by=2))+
  ggtitle(paste(labplot[2]))+
  theme(  legend.title = element_text(size = 7),
          legend.position = "right",
          legend.box.background = element_rect(colour = "black"),
          legend.key.width = unit(0.5, "cm"),
          legend.key.height = unit(0.3,"cm"),
          legend.key = element_rect(fill=NA),
          legend.text  = element_text(size = 6),
          panel.border = element_rect(fill = NA),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          panel.background = element_blank(),
          plot.title = element_text(size=8, face="bold"),
          axis.text = element_text(size = 6),
          axis.title.y = element_text(margin = margin(t = 0, r = 5, b = 0, l = 0)),
          axis.title.x = element_text(margin = margin(t = 5, r = 0, b = 0, l = 0)),
          axis.title = element_text(size = 7,vjust=-5),
          plot.margin = unit(c(0.1,0.1,0.1,0.1), "cm"))

# put plots together
plot_grid(fmoistplot,moistplot,
          align = "v", nrow = 2)
