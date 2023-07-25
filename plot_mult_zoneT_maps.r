#
# Expects dataframe "movable" to be defined/filled/available!
#
# Last changed: 06/08/2020
# Status: usable
#
# Generate color maps for zone air temperatures.
#

#building:Buecherraum:air point:temperature (oC) => building.Buecherraum.air.point.temperature..oC. (N  =  15 fields)
## Air temperatures.
#grx <- glob2rx("building.*.air.point.temperature..oC.")
## Operative tempertures
grx <- glob2rx("building.*.air.point.operative.temp..oC.")

mv_zoneT<-movable[,c("building.time.present..hours.","building.day.number.present..days.","thedate",
                   grep(grx, names(movable), ignore.case = TRUE, value = TRUE, perl = TRUE))]

## Set column names
# building.ff.bath.air.point.operative.temp..oC.
colnames(mv_zoneT)<-c("hour","day","thedate",sapply(strsplit(colnames(mv_zoneT[4:length(mv_zoneT)]),"\\."),
         FUN=function(x){ifelse(x[3]=="air",paste(x[2]),paste(x[2],x[3], sep="_"))},
         simplify = TRUE, USE.NAMES = TRUE))

if(colnames(mv_zoneT[1])=="hour") {
    firstD=4 # set first data column
} else {
    firstD=1 # assume only data in data.frame, no time information
}

# [1]  "hour"       "day"        "thedate"    "Bath1"      "BathRoom_2" "BedRoom_1"  "BedRoom_2"  "BedRoom_3"
# [9]  "Cellar"     "Garage"     "Kitchen"    "R_Pvt"      "R_Pvt"      "R_Pvt"      "R_Pvt"      "R_Pvt"
# [17] "R_Pvt"      "R_Pvt"      "R_Pvt"      "Roof"       "Salon"      "WC"

## Min and max. opr. temp for data collection.
DataDF$Bath1_min      <-format(round(min(mv_zoneT$Bath1     ),2), nsmall = 2)
DataDF$BathRoom_2_min <-format(round(min(mv_zoneT$BathRoom_2),2), nsmall = 2)
DataDF$BedRoom_1_min  <-format(round(min(mv_zoneT$BedRoom_1 ),2), nsmall = 2)
DataDF$BedRoom_2_min  <-format(round(min(mv_zoneT$BedRoom_2 ),2), nsmall = 2)
DataDF$BedRoom_3_min  <-format(round(min(mv_zoneT$BedRoom_3 ),2), nsmall = 2)
DataDF$Cellar_min     <-format(round(min(mv_zoneT$Cellar    ),2), nsmall = 2)
DataDF$Kitchen_min    <-format(round(min(mv_zoneT$Kitchen   ),2), nsmall = 2)
DataDF$Salon_min      <-format(round(min(mv_zoneT$Salon     ),2), nsmall = 2)
DataDF$WC_min         <-format(round(min(mv_zoneT$WC        ),2), nsmall = 2)

DataDF$Bath1_max      <-format(round(max(mv_zoneT$Bath1     ),2), nsmall = 2)
DataDF$BathRoom_2_max <-format(round(max(mv_zoneT$BathRoom_2),2), nsmall = 2)
DataDF$BedRoom_1_max  <-format(round(max(mv_zoneT$BedRoom_1 ),2), nsmall = 2)
DataDF$BedRoom_2_max  <-format(round(max(mv_zoneT$BedRoom_2 ),2), nsmall = 2)
DataDF$BedRoom_3_max  <-format(round(max(mv_zoneT$BedRoom_3 ),2), nsmall = 2)
DataDF$Cellar_max     <-format(round(max(mv_zoneT$Cellar    ),2), nsmall = 2)
DataDF$Kitchen_max    <-format(round(max(mv_zoneT$Kitchen   ),2), nsmall = 2)
DataDF$Salon_max      <-format(round(max(mv_zoneT$Salon     ),2), nsmall = 2)
DataDF$WC_max         <-format(round(max(mv_zoneT$WC        ),2), nsmall = 2)

#if (grepl("nov",outputfile,fixed=TRUE)==FALSE) {
  # Filter for first ventilation period 7.0 to 7.1 (filter full hour ?)
#  mv_zoneT<-subset(mv_zoneT, hour<7.0 | hour >=7.5)

  # (Conditionally) Filter for second ventilation period 12.5 to 12.6 (again, filter full hour ?)
#  if (grepl("vo2",outputfile,fixed=TRUE)==TRUE) {
#    mv_zoneT<-subset(mv_zoneT, hour<12.0 | hour >=12.5)
#  }

  # Filter for third ventilation period 18.0 to 18.1 (again, filter full hour ?)
#  mv_zoneT<-subset(mv_zoneT, hour<18.0 | hour >=18.5)
#}

## Create list of zones of interest (by column index)
myz<-c(4:9,11,21:22)

# Calculate and adapt y-axis start and end values
dayMIN<-min(mv_zoneT[,3])
dayMAX<-max(mv_zoneT[,3])


#round_any(132.1, 5, f = ceiling)   # returns 135
#dayMIN<-max(round_any(dayMIN, 5, f = floor),1)
#dayMAX<-min(round_any(dayMAX, 5, f = ceiling),365)

# doy to date (doy zero based!):
#as.Date(104, origin = "2014-01-01")

# Calculate and adapt min and max values for temperature scale
#scMIN<-min(apply(mv_zoneT[,firstD:length(mv_zoneT)],2,min))
scMIN<-min(apply(mv_zoneT[,myz],2,min))
if((floor(scMIN) %% 2) == 0) {
    scMIN<-floor(scMIN)
} else {
    scMIN<-floor(scMIN)-1
}

#scMAX<-max(apply(mv_zoneT[,firstD:length(mv_zoneT)],2,max))
scMAX<-max(apply(mv_zoneT[,myz],2,max))
if((ceiling(scMAX) %% 2) == 0) {
    scMAX<-ceiling(scMAX)
} else {
    scMAX<-ceiling(scMAX)+1
}

## Farbgradient Temperaturen festlegen
if (bFixedScales==F) {
   TL=scMIN
   TH=scMAX
} else {
   TL=20.0
   TH=21.0
}

color.gradient <- function(x, colors=c("darkblue","royalblue","lightblue","pink","red","red","darkred","darkred"), colsteps=(1*(TH-TL+1))) {
  return( colorRampPalette(colors) (colsteps) [ findInterval(x, seq(TL,TH, length.out=colsteps)) ] )
}

## Generate x1 factor for placing N figures, here (zone temperature) 4:7 and 14:17
Nfig=length(myz)
Nrows=1
Ncols=Nfig/Nrows

X1fac=trunc(100*(1/Nfig),2)/100
X20=trunc(100*(1/(Nfig-1)),2)/100

Y1=0.15
Y2=1.0

## Set plot output file to type png
png(file = outputfile, width=Ncols*3.5, height=Nrows*8, units= "in", res=300, type="quartz", bg = "transparent")


## Draw N Plots side by side
## First plot (scaled with date for y-axis ...)
par(fig=c(0,X20,Y1,Y2) )
plot(as.numeric(mv_zoneT$hour),as.numeric(mv_zoneT$thedate),
     col=color.gradient(round(as.numeric(mv_zoneT[,myz[1]]), digits = 0)),
     ylim=c(dayMAX,dayMIN),
     pch=15,main=colnames(mv_zoneT[myz[1]]),xlab="Hour",ylab="",xaxt="n",yaxt="n")
axis(1, at = seq(0, 24, by = 6), las=1)
#axis.Date(2, at = seq(dayMAX,dayMIN, by=-10),format= "%m-%d", las=1)
axis.Date(2, at = seq(dayMAX,dayMIN, by=-10), las=1)

## 2nd to Nth plot: loop jj=1 ... N-1
for(jj in 1:(Nfig-1))
{
    par(fig=c((jj*X1fac),(X20+(jj*X1fac)),Y1,Y2), new=TRUE)
        plot(as.numeric(mv_zoneT$hour),as.numeric(mv_zoneT$thedate),
        col=color.gradient(round(as.numeric(mv_zoneT[,myz[(jj+1)]]), digits = 0)),
        ylim=c(dayMAX,dayMIN),
        pch=15,main=colnames(mv_zoneT[myz[(jj+1)]]),xlab="Hour",ylab="",yaxt="n", xaxt="n")
    axis(1, at = seq(0, 24, by = 6), las=1)
}
## ... loop end ...

## Temperaturbalken unter den Hotplots
yyy<-seq(TL,TH, by=0.5)
yyy<-as.data.frame(yyy)
yyy<-cbind(yyy,1)

## Set subplot "temperature scale" dimensions (relative) and then plot
# ? how to set x1, x2 depending on number of plots?
par(fig=c(0.35,0.65,0,0.25), new=TRUE)
plot(yyy[,1],yyy[,2],col=color.gradient(yyy[,1]),ylim=c(0.99,1.01),pch=15,xaxt="n",
     xlab="Zone operative temperature in oC",yaxt="n",ylab="")
axis(1, at = seq(TL, TH, by=1), las=1)
