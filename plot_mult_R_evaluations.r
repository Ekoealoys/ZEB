#!/usr/bin/env Rscript
#
# Last changed: 10/08/2020
# Status: basically works.
#
# Generate various evaluations by call to external R scripts.
# Basis for all selected variables is h3k (.csv) file from simulation
# run.
#
# Expects 3 + x parameter(s) on call!
#   <file>    The results file (.csv)
#   <BTSTEP>  The time step of .csv (building time step)
#   <simdate> The date of simulation run
#   <x files> The PMV results files
#
suppressPackageStartupMessages(library(tools))
suppressPackageStartupMessages(library(padr))         # span_time()
suppressPackageStartupMessages(library(plyr))
suppressPackageStartupMessages(library(crop))
suppressPackageStartupMessages(library(chron))

args = commandArgs(trailingOnly=TRUE)

#for (ii in 1:length(args)) {
#    writeLines(paste("args[",ii,"] = ",args[ii],"."))
#}

#writeLines(paste("wd = ",getwd()))
#wd =  /Users/achim/ProjectsGit/BIPVT_PCM/cfg

# Test if there are (at least) three arguments: if not, return an error
# and stop.
if (length(args)<3) {
  stop("** <<plot_mult_R_evaluations>>: At least .csv file name, \
        number of building ts & simulation date-time must be supplied!",
        call.=FALSE)
}

## Define "calendar"
#https://stackoverflow.com/questions/29199181/boxplot-by-date-in-r
Sys.setenv(TZ="Europe/Berlin")

writeLines(" ")
cat("\tR postprocessing, reading input")

##filenam <- strsplit(args[1], "\\.")[[1]]
file_base <- file_path_sans_ext(args[1])

## CMRnZEB_nc_c000_cw_noPCM_test/CMRnZEB_nc_c000_cw_noPCM_test.csv
parm<-strsplit(args[1],"/")[[1]]

##    1     2    3  4   5     6
## CMRnZEB_nc_c000_cw_noPCM_test.csv
parm<-strsplit(parm[2],"_")[[1]]

## Create data frame for current variant (this adds one line to the
## variant summary data file before closing the file for the next call
## i.e. the next variant results set).
cn<-c("RunDate","SimStart","SimEnd","TSPH","Obs.cm",
      "Control", "CeilCon", "WallCon", "PCM",
      "too_cold","too_warm",
      "Bath1_min",     "Bath1_max",     "BathRoom_2_min", "BathRoom_2_max",
      "BedRoom_1_min", "BedRoom_1_max", "BedRoom_2_min",  "BedRoom_2_max",
      "BedRoom_3_min", "BedRoom_3_max", "Cellar_min",     "Cellar_max",
      "Kitchen_min",   "Kitchen_max",   "Salon_min",      "Salon_max",
      "WC_min",        "WC_max",
      "TotPVyield.kWh", "CoolingDemand.kWh", "TotSC.kWh", "TotSC_all.kWh",
      "Tot.grid.draw.kWh", "Tot.grid.draw_all.kWh",
      "Tot.grid.feed.kWh", "Tot.grid.feed_all.kWh",
      "maxPVpower.kW", "maxCooling.kW", "maxCoolingElec.kW",
      "TotIL.kWh", "SCR", "ATR", "SCR_all", "ATR_all"
	   )

NDAT             <- length(cn)
DataDF           <- data.frame(matrix(ncol = NDAT, nrow = 1))
colnames(DataDF) <- cn

## Begin filling overall results values output.
DataDF$Obs.cm   <-as.character(parm[2])
DataDF$Control  <-as.character(parm[3])
DataDF$CeilCon  <-as.character(parm[4]) # <<back-translate ...?>>
DataDF$WallCon  <-as.character(parm[5]) # <<back-translate ...?>>
DataDF$PCM      <-as.character(parm[6])


## Read .csv file (h3k-output) incl. column headers.
if (length(args)>=3) {
    cat(" ...")
    TSTEP  <-as.numeric(args[2])
    simDate<-as.character(args[3])
    movable<-read.csv(file=args[1],header=T,sep=",") #[-1:-TSTEP,]

    # "Replace" simulation date with R date and datetime, i.e. convert
    # from 24:00 ... 1:00 (h3k) to 00:00 ... 01:00 (more common).
    # Create 60/TSTEP-min sequence data frame and drop last line (next day).
    if (movable$building.day.number.present..days.[1] == 365) {
      mindate<-"20150101"
    } else {
      mindate<-format(as.Date(movable$building.day.number.present..days.[1],
                                origin = "2015-01-01"),"%Y%m%d")
    }
    NN<-length(movable$building.day.number.present..days.)
    maxdate<-format(as.Date(movable$building.day.number.present..days.[NN],
                                origin = "2015-01-01"),"%Y%m%d")
    ts<-as.data.frame(span_time(as.character(mindate),
                                as.character(maxdate),
                                by=paste(as.character(60/TSTEP),"min")))
    ts<-head(ts,-1)
    names(ts)<-c("dt")
    movable[,"thedate"]<-as.Date(ts$dt)
    movable$ndt   <-ts$dt
}

if (length(args) > 3) {
  # Read in .dat files for PMV and create summary probability plots.
  source("../plot_PMV.r")
  writeLines(" done.")
}

## Continue filling overall results values output.
DataDF$RunDate <-simDate
DataDF$TSPH    <-TSTEP
DataDF$SimStart<-as.character(min(as.Date(movable$thedate)))
DataDF$SimEnd  <-as.character(max(as.Date(movable$thedate)))

#writeLines(" done.")

## Monthly box plots
#https://togaware.com/datamining/survivor/Grouping_Time.html
mons<-c("January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November",
        "December")
smons<-c("Jan", "Feb", "Mar", "Apr", "May", "Jun",
         "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")

observer.months <- ordered(months(movable$thedate),
                           levels=mons,
                           labels=smons)

## Choose individual output options
if (!is.na(grep("bui.spm.PCM",names(movable))[1])) {
    bPCM<-T
} else {
    bPCM<-F
}

bzoneTmaps<-T
bSCD<-T
bPVeff<-F
bPV<-T
bSolRad<-F
bzoneTstats<-F
bMultStat<-F

## Choose if fixed scales should be used
bFixedScales<-F

###########################################################
## Zone air temperature color maps.
if (bzoneTmaps==T) {
   cat("\tCreating colour field plots for indoor air temperatures ...")
   outputfile <- paste(file_base,"_zoneTmaps.png", sep="")
   source("../plot_mult_zoneT_maps.r")
   writeLines(" done.")
}

###########################################################
## Space cooling demand.
if (bSCD==T) {
   cat("\tCreating space cooling demand boxplots ...")
   outputfile <- paste(file_base,"_SCD.png", sep="")
   source("../plot_SCD.r")
   writeLines(" done.")
}

############################################################
## PV efficiency.
if (bPVeff==T) {
  cat("\tCreating plots for PV efficiency ...")
  outputfile <- paste(file_base,"_PVeff", sep="")
  source("../plot_PV_efficiency.r")
  writeLines(" done.")
}

############################################################
## Further PV plots.
if (bPV==T) {
  cat("\tCreating plots for PV ...")
  outputfile <- paste(file_base,"_PV.png", sep="")
  source("../plot_PV.r")
  writeLines(" done.")
}

###########################################################
## Solar radiation incidence color maps
if (bSolRad==T) {
   cat("\tCreating colour field plots for direct and diffuse incident \
           solar radiation ...")
   outputfile <- paste(file_base,"_solRadmaps.png", sep="")
   outputfile2 <- paste(file_base,"_solTotRadmaps.png", sep="")
   source("../plot_mult_rad_maps.r")
   writeLines(" done.")
}

############################################################
## Zone temperature cumulative frequency distribution and box plot
if (bzoneTstats==T) {
   cat("\tCreating cumulative frequency distribution and box plots \
           for indoor air temperatures ...")
   outputfile <- paste(file_base,"_zoneTstats.png", sep="")
   source("../plot_mult_zoneT_stats.r")
   writeLines(" done.")
}

#############################################################
## Various box plots
if (bMultStat==T) {
   cat("\tCreating box plots for various variables ...")
   outputfile <- paste(file_base,"_MultStats", sep="")
   source("../plot_mult_stats.r")
   writeLines(" done.")
}

###############################################
## PCMFAC (state flag) color maps
if (bPCM==T) {
    cat("\tCreating colour field maps of PCM state for selected nodes ...")
    outputfile <- paste(file_base,"_pcmFACmaps.png", sep="")
    source("../plot_mult_pcmfac_maps.r")
    writeLines(" done.")

## SHCarea (PCM latent heat stored per area) color maps
    cat("\tCreating colour field maps of latent heat per area stored \
            in PCM for selected nodes ...")
    outputfile <- paste(file_base,"_pcmSHCareamaps.png", sep="")
    source("../plot_mult_SHCarea_maps.r")
    writeLines(" done.")
}


#############################################################
## Write data for current variant to data container.
cat("\tWriting summary data to central file ...")
suppressWarnings(write.table(DataDF, "../DataContainer.csv", sep = ",",
                 row.names = FALSE,
                 col.names = !file.exists("../DataContainer.csv"),
                 quote = FALSE,
                 append = T))
writeLines(" done.")

writeLines(" ")

# Clean up (?)
rm(list = ls(all.names = TRUE))
