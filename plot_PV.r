#
# Last changed: 15/08/2020
# Status: usable
#
# Results for PV modules / selfconsumption etc.
#
# Expects dataframe "movable" to be defined/filled/available!
#
# building.spmatl.CT.pv.mod.1.misc.data.efficiency..%.
# building.spmatl.CT.pv.mod.1.misc.data.pv.power..W.
#    1        2    3  4  5  6   7    8   9   10
grx <- glob2rx("building.spmatl.CT.pv.*")    # PV data
pveff<-movable[,c("thedate","ndt",
                  grep(grx, names(movable),
                       ignore.case = TRUE, value = TRUE, perl = TRUE)
                  )]

## Set column names
colnames(pveff)<-c("thedate","ndt",
                   sapply(strsplit(colnames(pveff[3:length(pveff)]),"\\."),
                          FUN=function(x){
                                ifelse(x[9]=="pv",
                                paste(x[5],x[6],x[9],x[10], sep="_"),
                                paste(x[5],x[6],x[9], sep="_"))},
                          simplify = TRUE, USE.NAMES = TRUE))

# [1] "thedate"          "ndt"            "mod_1_efficiency  "mod_1_pv_power"
# [5] "mod_2_efficiency  "mod_2_pv_power" "mod_3_efficiency  "mod_3_pv_power"
# [9] ...

## Power & efficiency columns.
pc<-c(4,6,8,10,12,14,16,18)
ec<-c(3,5,7, 9,11,13,15,17)


## Cooling load data.
# building.Bath1     .thermal.loads.cooling.total..W.
# building.Bathroom.2.thermal.loads.cooling.total..W.
# building.all. zones.thermal.loads.cooling.total..W.
#    1       2      3    4      5      6      7
grx <-glob2rx("building.*.thermal.*.cooling.total..W.") # Cooling load data
cool<-movable[,c("thedate","ndt",
                  grep(grx, names(movable),
                       ignore.case = TRUE, value = TRUE, perl = TRUE)
                  )]

## Set column names
colnames(cool)<-c("thedate","ndt",
                   sapply(strsplit(colnames(cool[3:length(cool)]),"\\."),
                          FUN=function(x){
                                ifelse(x[3]=="thermal",
                                paste(x[2]),
                                paste(x[2],x[3], sep="_"))},
                          simplify = TRUE, USE.NAMES = TRUE))

# [1] "thedate"    "ndt"       "Bath1"     "Bathroom_2"
# [5] "Bedroom_1"  "Bedroom_2" "Bedroom_3  "Cellar"
# [9] ...                                  "all_zones"

## Internal electric load data.
# building.Bath1   .equipment.power..W.
# building.Bathroom.   2   .lighting.power..W.
#    1       2         3       4       5
grx <- glob2rx("building.*.power..W.") # Internal electric load data
ipow<-movable[,c("thedate","ndt",
                  grep(grx, names(movable),
                       ignore.case = TRUE, value = TRUE, perl = TRUE)
                  )]

## Set column names
colnames(ipow)<-c("thedate","ndt",
                   sapply(strsplit(colnames(ipow[3:length(ipow)]),"\\."),
                          FUN=function(x){
                                ifelse(x[4]=="power",
                                paste(x[2],x[3], sep="_"),
                                paste(x[2],x[3],x[4], sep="_"))},
                          simplify = TRUE, USE.NAMES = TRUE))

#  [1] "thedate"             "ndt"                 "Bath1_equipment"
#  [4] "Bath1_lighting"      "Bedroom_1_equipment" "Bedroom_1_lighting"
#  [7] "Bedroom_2_equipment" "Bedroom_2_lighting"  "Bedroom_3_equipment"
# [10] ...

## TS total power from all modules (rowsum of all panels, pc[i]).
pveff$pv_power_tot.W <-apply(pveff[pc], 1, sum)

## TS yield from all modules.
pveff$pv_yield_tot.Wh<-pveff$pv_power_tot.W/TSTEP

## TS average efficiency from all modules (ec[i]).
pveff$ave_efficiency <-apply(pveff[ec], 1, mean)

## Max/mean (w/o 0)/sum values.
meanPVpower.W <-mean(pveff$pv_power_tot.W[pveff$pv_power_tot.W != 0])
maxPVpower.W  <- max(pveff$pv_power_tot.W)
sumPVyield.kWh<- sum(pveff$pv_yield_tot.Wh)/1000  # kWh

meanPVeff  <-mean(pveff$ave_efficiency[pveff$ave_efficiency != 0])
maxPVeff   <- max(pveff$ave_efficiency)

# Cooling energy.
TotCooling.kWh<-sum(cool$all_zones)/1000/TSTEP  # kWh
maxCooling.W  <-max(cool$all_zones)             # W

# Internal electric loads (rowsum of all zones, equipment + lighting).
ipow$tot.W <-apply(ipow[3:length(ipow)], 1, sum)

TotInternal.kWh<-sum(ipow$tot.W)/1000/TSTEP  # kWh
maxInternal.W  <-max(ipow$tot.W)             # W

#########  Calculate self-consumption, Grid.draw , grid feed-in, SCR, ATR
## Set cooling EER
CEER<-3.3

## Electric power for cooling.
ElecCool.W<-cool$all_zones/CEER

# PV yield & electric cooling load, Wh.
df     <-cbind(pveff$pv_yield_tot.Wh,ElecCool.W/TSTEP)

# PV yield & (internal + cooling) loads, Wh.
df_all <-cbind(pveff$pv_yield_tot.Wh,(ElecCool.W+ipow$tot.W)/TSTEP)

# Calculate self-consumptiopn (find min of each row: min(PV, load))
SC.Wh     <-apply(df    , 1, FUN = min)
SC_all.Wh <-apply(df_all, 1, FUN = min)

# Self-consumption rate SCR, autarky rate ATR, based on 5 min values
SCR    <-SC.Wh    /pveff$pv_yield_tot.Wh
SCR_all<-SC_all.Wh/pveff$pv_yield_tot.Wh

ATR    <-SC.Wh    /(ElecCool.W/TSTEP)
ATR_all<-SC_all.Wh/((ElecCool.W+ipow$tot.W)/TSTEP)


# Grid draw when load > PV, grid feed when load < PV.
grid.draw.Wh    <- ifelse(ElecCool.W/TSTEP > pveff$pv_yield_tot.Wh,
                          ElecCool.W/TSTEP - pveff$pv_yield_tot.Wh, 0)

grid.feed.Wh    <- ifelse(pveff$pv_yield_tot.Wh > (ElecCool.W/TSTEP),
                          pveff$pv_yield_tot.Wh - (ElecCool.W/TSTEP), 0)

grid.draw_all.Wh<- ifelse((ElecCool.W+ipow$tot.W)/TSTEP > pveff$pv_yield_tot.Wh,
                          (ElecCool.W+ipow$tot.W)/TSTEP - pveff$pv_yield_tot.Wh, 0)

grid.feed_all.Wh<- ifelse(pveff$pv_yield_tot.Wh > (ElecCool.W+ipow$tot.W)/TSTEP,
                          pveff$pv_yield_tot.Wh - (ElecCool.W+ipow$tot.W)/TSTEP, 0)

#writeLines(paste("\ngrid.draw_all.Wh max=",max(grid.draw_all.Wh),";"))

#=============================================
# Store data in collection file.
DataDF$TotPVyield.kWh       <-format(round(sum(pveff$pv_yield_tot.Wh)/1000,2), nsmall = 2)
DataDF$TotSC.kWh            <-format(round(sum(SC.Wh)/1000,2), nsmall = 2)
DataDF$TotSC_all.kWh        <-format(round(sum(SC_all.Wh)/1000,2), nsmall = 2)
DataDF$Tot.grid.draw.kWh    <-format(round(sum(grid.draw.Wh)/1000,2), nsmall = 2)
DataDF$Tot.grid.draw_all.kWh<-format(round(sum(grid.draw_all.Wh)/1000,2), nsmall = 2)
DataDF$Tot.grid.feed.kWh    <-format(round(sum(grid.feed.Wh)/1000,2), nsmall = 2)
DataDF$Tot.grid.feed_all.kWh<-format(round(sum(grid.feed_all.Wh)/1000,2), nsmall = 2)
DataDF$maxPVpower.kW        <-format(round(maxPVpower.W/1000,2), nsmall = 2)
DataDF$maxCooling.kW        <-format(round(maxCooling.W/1000,2), nsmall = 2)
DataDF$maxCoolingElec.kW    <-format(round(max(ElecCool.W)/1000,2), nsmall = 2)

DataDF$TotIL.kWh <-format(round(sum(ipow$tot.W)/TSTEP/1000,2), nsmall = 2)
DataDF$SCR       <-format(round(sum(SC.Wh)/sum(pveff$pv_yield_tot.Wh),2), nsmall = 2)
DataDF$ATR       <-ifelse(sum(ElecCool.W) > 0,
                          format(round(sum(SC.Wh)/(sum(ElecCool.W)/TSTEP),2), nsmall = 2),0)
DataDF$SCR_all   <-format(round(sum(SC_all.Wh)/sum(pveff$pv_yield_tot.Wh),2), nsmall = 2)
DataDF$ATR_all   <-format(round(sum(SC_all.Wh)/(sum(ElecCool.W+ipow$tot.W)/TSTEP),2), nsmall = 2)

#=====================================================
# Create some plots
#========================================================

## Generate x1 factor for placing N figures
Nfig =3
X1fac=trunc(100*(1/Nfig),2)/100
X20  =trunc(100*(1/Nfig),2)/100
Y1   =0.15
Y2   =1.0

## Set plot output file to type png
png(file = outputfile, width=Nfig*3.5, height=8, units= "in", res=300, type="quartz", bg = "transparent")

xlim=c(min(pveff$ndt),max(pveff$ndt))
#xlim=c(min(datetime),"2019-01-04 00:00:00")

##### 1. plot
# Calculate necessary plot range: min/max of frequence
# for x-axis, min/max of heat out for y-axis

ylim<-range(pveff$pv_yield_tot.Wh,pveff$pv_yield_tot.Wh)

par(fig=c(0,X20,Y1,Y2) )
plot(pveff$ndt,pveff$pv_yield_tot.Wh, main="", xlab="Datum",
     ylim=ylim, xlim=xlim, # log="y",
     ylab=paste("PV yield in Wh, efficiency (red) in %",""),
     las=1, type = "l", lwd=0.5, col="blue")

points(pveff$ndt,pveff$ave_efficiency, main="", col="red", type = "l")

#usr<-par("usr")
#text(0.15*usr[2], 0.50*usr[4],

mtext(
     paste(" mean/max/sum power:",sprintf("%.0f",meanPVpower.W ),"/",
                                  sprintf("%.0f",maxPVpower.W  ), " W,",
                                  sprintf("%.0f",sumPVyield.kWh), " kWh",
         "\n mean/max eff.:",sprintf("%.1f",meanPVeff),"/",
                             sprintf("%.1f",maxPVeff), " %"
      ),side = 3, cex=0.8)
                  

##### 2. plot
# Self-consumption, grid draw, load, PV, all in W.

ylim<-range(grid.draw.Wh*(-1)*TSTEP,max(pveff$pv_yield_tot.Wh*TSTEP,cool$all_zones))

jj=1

par(fig=c((jj*X1fac),min(1.,(X20+(jj*X1fac))),Y1,Y2), new=TRUE)

plot(pveff$ndt,ElecCool.W,
     main="", xlab="Date",
     ylim=ylim, xlim=xlim, # log="y",
     ylab=paste("Power in W",""),
     las=1, type = "l", lwd=0.5, col="blue")

points(pveff$ndt,pveff$pv_yield_tot.Wh*TSTEP, main="", col="red", type = "l")
points(pveff$ndt,SC.Wh*TSTEP,                 main="", col="green", type = "l")
points(pveff$ndt,grid.draw.Wh*(-1)*TSTEP,     main="", col="darkblue", type = "l")

mtext(
     paste(" PV (red), max/mean, sum:",sprintf("%.0f",meanPVpower.W ),"/",
                                       sprintf("%.0f",maxPVpower.W  ), " W, ",
                                       sprintf("%.0f",sumPVyield.kWh), " kWh",
         "\n load (blue), sum:",sprintf("%.0f",sum(ElecCool.W)/TSTEP/1000), " kWh",
         "\n self-consumption (green), sum:",sprintf("%.0f",sum(SC.Wh)/1000), " kWh",
         "\n grid draw (dark blue), sum:",sprintf("%.0f",sum(grid.draw.Wh)/1000), " kWh"
      ),side = 3, cex=0.8)

##### 3. plot
# Self-consumption, grid draw, total load, PV, all in W.

ylim<-range(grid.draw_all.Wh*(-1)*TSTEP,max(pveff$pv_yield_tot.Wh*TSTEP,(ElecCool.W+ipow$tot.W)))

jj=1+jj

par(fig=c((jj*X1fac),min(1.,(X20+(jj*X1fac))),Y1,Y2), new=TRUE)

plot(pveff$ndt,(ElecCool.W+ipow$tot.W),
     main="", xlab="Date",
     ylim=ylim, xlim=xlim, # log="y",
     ylab=paste("Power in W",""),
     las=1, type = "l", lwd=0.5, col="blue")

points(pveff$ndt,pveff$pv_yield_tot.Wh*TSTEP, main="", col="red", type = "l")
points(pveff$ndt,SC_all.Wh*TSTEP,             main="", col="green", type = "l")
points(pveff$ndt,grid.draw_all.Wh*(-1)*TSTEP, main="", col="darkblue", type = "l")

mtext(
     paste(" PV (red), max/mean, sum:",sprintf("%.0f",meanPVpower.W ),"/",
                                       sprintf("%.0f",maxPVpower.W  ), " W, ",
                                       sprintf("%.0f",sumPVyield.kWh), " kWh",
         "\n total load (blue), sum:",sprintf("%.0f",sum(ElecCool.W+ipow$tot.W)/TSTEP/1000), " kWh",
         "\n self-consumption (green), sum:",sprintf("%.0f",sum(SC_all.Wh)/1000), " kWh",
         "\n grid draw (dark blue), sum:",sprintf("%.0f",sum(grid.draw_all.Wh)/1000), " kWh"
      ),side = 3, cex=0.8)
