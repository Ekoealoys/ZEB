#
# Expects dataframe "movable" to be defined/filled/available!
#
# Last changed: 15/08/2020
# Status: usable
#
# Calculate cooling energy demand.
#

#  building/all_zones/supplied_energy/cooling
#  building.all.zones.supplied.energy.cooling..W.
grx   <- glob2rx("building.all.zones.supplied.energy.cooling.*")
q_cool<-movable[,c("thedate","ndt",
                    grep(grx, names(movable), ignore.case = TRUE, value = TRUE, perl = TRUE))]
colnames(q_cool)<-c("thedate","ndt","cool.W")

## Calculate supplied energy [Wh]
q_cool$cool.Wh          <-q_cool$cool.W/TSTEP
SCD                     <-sum(q_cool$cool.Wh)
DataDF$CoolingDemand.kWh<-format(round(SCD/1000.,2), nsmall = 2)

## Set plot output file to type png
png(file = outputfile, width=16, height=8, units= "in", res=300, type="quartz", bg = "transparent")

boxplot(q_cool$cool.Wh ~ observer.months,
#        main=colnames(mv_ZoneT[myz[k]]),
        ylab="SCD in Wh",
        xlab="Month",
        ylim=range(q_cool$cool.Wh), xaxt="n", border="blue", boxwex=0.25,
        at = 1:length(mons) - 0.15) #shift these left by -0.15
        axis(1, at=seq(smons), labels=as.character(smons), las=2)

## Set overall "cooled area" (i.e. all zones w/o garage)
coolA<-138.

usr<-par("usr")
text(0.03*usr[2], 0.92*usr[4],
                 paste0(" SCD : ",sprintf("%.1f",SCD/1000./coolA), " kWh/m2"),
                 cex = 0.75,
                 pos = 4, offset = 0,
                 col = "black")


# 1 Cellar          9.9   9    31.2     0.0     3.3
# 2 WC              7.2   8    23.5     0.5     2.4
#
# 4 BedRoom_1      70.6  14   114.7     2.5    23.5
# 5 Bath1          12.6  10    35.5     0.5     4.2
# 6 Salon         182.1  28   228.3     5.0    60.7
# 7 Kitchen        28.8   8    53.9     2.5     9.6
# 8 BedRoom_3      43.8  10    72.6     2.5    14.6
# 9 BedRoom_2      43.8   9    72.6     2.5    14.6
#10 BathRoom_2     15.0   7    37.0     0.0     5.0
#                                             138.0
#
# 3 Garage         66.0  11    99.8     0.6    22.0
