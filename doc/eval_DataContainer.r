# Make overview plots from DataContainer data.
#
library(tools)
library(lattice)
library(latticeExtra)
library(data.table)

myData<-fread("movable.table_180309.csv")

#head(myData)

## Extract set of variables w/ WallCon.
CD <-myData[, c("Obs.cm","Control","WallCon","CoolingDemand.kWh")]

# Reduce to cases != 0.
CD<-CD[CD$CoolingDemand.kWh!=0,]

#head(CoolingDemand.kWh)

stacked.CD = melt(CD, id = c('Obs.cm', 'Control', 'WallCon'))
stacked.CD = stacked.CD[, -4]
bwplot(value~WallCon | factor(Obs.cm) + Control, data=stacked.CD,
                                             ylab='Cooling demand in kWh',
                                             axis=axis.grid)

## Extract set of variables w/ CeilCon.
CD2<-myData[, c("Obs.cm","Control","CeilCon","CoolingDemand.kWh")]
CD2<-CD2[CD2$CoolingDemand.kWh!=0,]

stacked.CD2 = melt(CD2, id = c('Obs.cm', 'Control', 'CeilCon'))
stacked.CD2 = stacked.CD2[, -4]
bwplot(value~CeilCon | factor(Obs.cm) + Control, data=stacked.CD2,
                                             ylab='Cooling demand in kWh',
                                             axis=axis.grid)

## Extract set of variables w/ WallCon w/o cooling.
TW <-myData[, c("Obs.cm","Control","WallCon","CoolingDemand.kWh","too_warm")]

# Reduce to cases with CoolingDemand == 0, then remove CoolingDemand column(!).
TW <-TW[TW$CoolingDemand.kWh==0,]
TW$CoolingDemand.kWh<-NULL

# Make values of 'too_warm' to percentages.
TW$too_warm<-TW$too_warm*100

stacked.TW = melt(TW, id = c('Obs.cm', 'Control', 'WallCon'))
stacked.TW = stacked.TW[, -4]
bwplot(value~WallCon | factor(Obs.cm) + Control, data=stacked.TW,
                                             ylab='Percentage too warm',
                                             axis=axis.grid)


## Extract set of variables w/ CeilCon w/o cooling.
TW2<-myData[, c("Obs.cm","Control","CeilCon","CoolingDemand.kWh","too_warm")]

# Reduce to cases with CoolingDemand == 0, then remove CoolingDemand column(!).
TW2<-TW2[TW2$CoolingDemand.kWh==0,]
TW2$CoolingDemand.kWh<-NULL

# Make values of 'too_warm' to percentages.
TW2$too_warm<-TW2$too_warm*100

stacked.TW2 = melt(TW2, id = c('Obs.cm', 'Control', 'CeilCon'))
stacked.TW2 = stacked.TW2[, -4]
bwplot(value~CeilCon | factor(Obs.cm) + Control, data=stacked.TW2,
                                             ylab='Percentage too warm',
                                             axis=axis.grid)
