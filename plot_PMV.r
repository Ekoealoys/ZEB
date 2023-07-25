#!/usr/bin/env Rscript
#
# Last changed: 04/08/2020
# Status: usable
#
# Generate histogram for HP on time intervals and turn-on count.
# Data taken from .dat file (format csv) from simulation extracted via res
# (in order to always have plant time step resolution data).
#
# Expects (at least) 1 parameter(s) on call!
#   <file(s)>  The results file (.dat)
#
#suppressPackageStartupMessages(library(tools))
suppressPackageStartupMessages(library(data.table))    # Provides fread() and setDT()
suppressPackageStartupMessages(library(accelerometry)) # Provides rle2()
#suppressPackageStartupMessages(library(crop))

#args = commandArgs(trailingOnly=TRUE)

# Test if there is (at least) one argument: if not, return an error.
#if (length(args)==0) {
#  stop("** Input file name must be supplied (input file).n", call.=FALSE)
#}

writeLines(" ")
cat("\tEvaluating PMV, reading .dat input files ...")

file_base <- file_path_sans_ext(args[4])
outputfile <- paste(file_base,".png", sep="")

isPPD2<-F

# Create "index" function for mapping of zone names.
idx <- function(x) {utf8ToInt(x) - utf8ToInt("a") + 1L}

# List of zones. <<automate and/or pass from Python?>>
zl<-c("Cellar","WC","Garage","BedRoom1","Bath1","Salon","Kitchen",
      "BedRoom_3","BedRoom_2","BathRoom_2","Roof",
      "Pvt_1","Pvt_4","R_Pvt_3","R_Pvt_4","R_Pvt_5","R_Pvt_6","R_Pvt_7","R_Pvt_8")

#   1     2   3   4   5     6  7  8   9   10  11
#CMRnZEB_nc_c000_cw_noPCM_test_f_PMV_0.5_1.0_0.1
Nfiles <-length(args)-3

allPMV <-as.data.frame(NULL)
clo    <-list()
met    <-list()
veloc  <-list()

## Read files and set column headers
for (kk in 1:Nfiles) {
    ## Split file name into components.
    parm<-strsplit(args[3+kk],"/")[[1]]
    parm<-strsplit(parm[2],"_")[[1]]

    if (kk == 1) {
        ## Set variant values for case only once.
        case  <-parm[1]
        obs   <-parm[2]
        ctl   <-parm[3]
        ccon  <-parm[4]
        wcon  <-parm[5]
        pcm   <-parm[6]
        per   <-parm[7]
        zone  <-parm[8]
    }

    ## clo, met and veloc values for evaluation sets.
    clo[kk]  <-parm[10]
    met[kk]  <-parm[11]
    veloc[kk]<-substr(parm[12], 1, nchar(parm[12])-4)

    ## Read current PMV file.
    PMV<-fread(file=args[3+kk], skip=4, header=FALSE, fill=TRUE,
               na.strings=c("occ","not"))
    # Reduce to data column, only and set column name.
    PMV <- PMV[ , c("V1","V3"):=NULL ]
    #    PMV <- PMV[ , c("V1","V3","V4","V5","V6","V7","V8","V9"):=NULL ]
    colnames(PMV)<-c(paste0("set_",kk))

    if (kk == 1) {
      allPMV <- PMV
    } else {
      allPMV <- cbind(allPMV,PMV)
    }
}

writeLines(" done.")

cat("\tCreating probability distributions of PMV ...")

## Set plot output file to type png
nrow<-1
ncol<-1

##########################################################################
##      P  M  V
##########################################################################

png(file = outputfile, width=6*ncol, height=6*nrow, units= "in", res=300, type="quartz", bg = "transparent")

## Create multiple graphs on single pane (here: one row, one column)
old.par<-par(mfrow = c(nrow, ncol))

## Plot
plot(NA,
     main="",
     xlab="PMV (-)",
     ylab="cumulative probability (-)",
     las=1,xaxs="i",yaxs="i",
     xaxp=c(-2.5,2.5,10),
     xlim=c(-2.5,2.5),
     ylim=c(0,1))

# Underlay approximate "comfort" region PPD <= 15 %
rect(-0.7,0, 0.7,1,col=rgb(0,1,0,alpha=0.1),lty=0)
rect( 0.7,0, 1.4,1,col=rgb(1,0,0,alpha=0.1),lty=0)
rect(-1.4,0,-0.7,1,col=rgb(0,0,1,alpha=0.1),lty=0)

# Add grid
grid(nx = 10, ny = 5,
     col = "lightgray",
     lty = "dotted",
     lwd = 1.5,
     equilogs = TRUE)

col=c("blue","red","orange","lightblue3","black","green")

# Draw distributions.
for (kk in 1:Nfiles) {
  lines(ecdf(allPMV[[kk]]), col=col[kk], lty=1, pch=20, cex=0.5)

  text(-2.4, (0.9-(kk-1)*0.15),
       paste("clo = ",     clo[kk],
             "\nmet = ",   met[kk],
             "\nveloc = ", veloc[kk]),
       cex = 0.9,
       adj = 0,
       col = col[kk])
}

# Common case parameters for distributions.
text(-2.4, 0.20,
     paste("zone   :",zl[idx(zone)],
           "\nobs      :",obs,
           "\nctl        :",ctl,
           "\nccon    :",ccon,
           "\nwcon   :",wcon,
           "\nPCM    :",pcm,
           "\nsim-per:",per),
     cex = 0.7,
     adj = 0,
     col = "black")

#text(1.4, 0.3,"sen 1",cex = 0.9,adj = 0,col = "blue")
#text(1.9, 0.3,"sen 4",cex = 0.9,adj = 0,col = "lightblue3")

dev.off.crop(file=outputfile)

## Calculate specific values for central output.
#<< cum. distr. for -0.7 taken from "ceiling fan off" and
#   cum. distr. for +0.7 taken from "ceiling fan on, max" >>
kmin<-which.min(veloc)
kmax<-which.max(veloc)

ecdfmin<-ecdf(allPMV[[kmin]])
ecdfmax<-ecdf(allPMV[[kmax]])

DataDF$too_cold<-format(round(ecdfmin(-0.7),3), nsmall = 3)
DataDF$too_warm<-format(round(1-ecdfmax(+0.7),3), nsmall = 3)
