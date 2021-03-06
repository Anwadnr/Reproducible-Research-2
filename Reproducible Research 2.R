library(dplyr)
library(ggplot2)
library(data.table)
library(gridExtra)
library(plyr)


## Data Processing
##### As a result of the large csv.bz2 file, using the readRDS function cuts time. For both goals data needs to be aggregated, summed, and sorted.

Events_Data <- read.csv("repdata_data_StormData.csv.bz2") 
saveRDS(Events_Data, "Events_Data.RDS")
Events_Data <- readRDS("Events_Data.RDS")



# Fatalities and Injuries
# Extracting only columns needed for analysis to increase processing speed.

We_Events<- Events_Data[c("EVTYPE", "FATALITIES", "INJURIES", 
                          "PROPDMG", "PROPDMGEXP", "CROPDMG", "CROPDMGEXP")]

# Summarizing injury and fatality data for human health impact analysis

Injuries <- aggregate(INJURIES~EVTYPE, We_Events, sum)
Fatalities <- aggregate(FATALITIES~EVTYPE, We_Events, sum)

# Ordering events by most hazardous to human health

Fatal_Num <- Fatalities[Fatalities$FATALITIES > 0, ]
Fatal_Rank <- Fatal_Num[order(Fatal_Num$FATALITIES, 
                              decreasing = TRUE), ]

Injuries_Num <- Injuries[Injuries$INJURIES > 0, ]
Injuries_Rank <- Injuries_Num[order(Injuries_Num$INJURIES, 
                                    decreasing = TRUE), ]



# Property and Crop Damage
# Assigning factors to numeric values for calculation of damage by event type.

We_Events$PROPDMGEXP2 <- mapvalues(We_Events$PROPDMGEXP, from = c("K", "M","", "B", 
                                                                  "m", "+", "0", "5", "6", "?", "4", "2", "3", "h", "7", 
                                                                  "H", "-", "1", "8"), to = c(10^3, 10^6, 1, 10^9, 10^6, 
                                                                                              0,1,10^5, 10^6, 0, 10^4, 10^2, 10^3, 10^2, 10^7, 10^2, 
                                                                                              0, 10, 10^8))
We_Events$PROPDMGEXP2 <- as.numeric(as.character(We_Events$PROPDMGEXP2))

We_Events$CROPDMGEXP2 <- mapvalues(We_Events$CROPDMGEXP, from = c("","M", "K", "m", 
                                                                  "B", "?", "0", "k","2"), to = c(1,10^6, 10^3, 10^6, 
                                                                                                  10^9, 0, 1, 10^3, 10^2))
We_Events$CROPDMGEXP2 <- as.numeric(as.character(We_Events$CROPDMGEXP2))

# Calulate total property and crop damage

We_Events$PROP_TOT <- (We_Events$PROPDMG * We_Events$PROPDMGEXP2)
We_Events$CROP_TOT <- (We_Events$CROPDMG * We_Events$CROPDMGEXP2)
We_Events$Exp_Total <- We_Events$PROP_TOT + We_Events$CROP_TOT


## Results
##### By taking the top 5 most dangerous and damaging events and plotting the result we can quickly see which events cause the most concern. 

# Fatalities and Injuries
# Grabbing top 5 events most hazardous to human health

Injuries_5 <- head(Injuries_Rank, n = 5)
Fatal_5 <- head(Fatal_Rank, n = 5)

Injuries_5
Fatal_5

# Securing list orders in Fatality and Injury plots by ordering levels

Fatal_5$EVTYPE <- factor(Fatal_5$EVTYPE, 
                         levels = Fatal_5$EVTYPE[order(-Fatal_5$FATALITIES)])
Injuries_5$EVTYPE <- factor(Injuries_5$EVTYPE, 
                            levels = Injuries_5$EVTYPE[order(-Injuries_5$INJURIES)])

# Fatality numbers by event type

Fatality_plot <- ggplot(data = Fatal_5, aes(x = EVTYPE, y = FATALITIES)) + 
  geom_bar(stat="identity") +
  ggtitle(label = "Fatalities by Weather Event Type") + 
  labs(x = "Event Type", y = "Fatalities") +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))

# Injury numbers by event type

Injury_plot<- ggplot(data = Injuries_5, aes(x = EVTYPE, y = INJURIES)) + 
  geom_bar(stat="identity") +
  ggtitle(label = "Injuries by Weather Event Type") + 
  labs(x = "Event Type", y = "Injuries") +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))
grid.arrange(Fatality_plot, Injury_plot, ncol = 2)  

# Property and Crop Damage
# Aggregate damage by event type and grab events with the 5 highest economic consequences

Gr_Econ_Event <- aggregate(We_Events$Exp_Total, by = list(We_Events$EVTYPE), 
                           FUN = sum)

Gr_Econ_Event <- head(Gr_Econ_Event[order(Gr_Econ_Event$x, 
                                          decreasing = TRUE),], n=5)   
Gr_Econ_Event

# Plotting property and crop damage by event type

Damage_plot <- ggplot(Gr_Econ_Event, aes(x = reorder(Group.1, -x), y = x)) +
  geom_bar(stat = "identity") + 
  labs( y= "Damage in U.S. Dollars", x = "Weather Event") +
  ggtitle ("Total Economical Consequences by Event 1950-2011") +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))
Damage_plot