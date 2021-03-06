# Packages:
  source('packages.R')

# Read in courtship data: 
  courtship <- read.csv("Immature.csv",h=T)

# Remove Temp, Humidity and BP: Believed to be covered by day effects:
  courtship <- subset(courtship, select = 
                        -c(Temp, Humidity, BP.12.00.am, BP.8.00.Am, BP.Room ))

# Change time (in HH:MM:SS) format to seconds (One had a value of -1, not sure, but changed to 0)
  
# Start time of behaviours will be the time at end of courtship bout of full trial (trial_latency_behav_end minus the courtship duration)
  
  courtship$startTimeSeconds <- (courtship$trial_latency_behav_end - courtship$court_duration)
  
  courtship$startTimeSeconds[1339] = 0
  
# Create new column of relative values for courtship start times (The start of observations are relative to the observation initiation of the certain vial (subtract observation initiation)

    courtship$relativeStartTimeSeconds <- (courtship$startTimeSeconds - courtship$Observation.Initiation)
  
# New column for relative values of trial duration at end of behaviour (the length of behaviours)
    
  courtship$relativeTrial_latency_end <- (courtship$relativeStartTimeSeconds + courtship$court_duration)
  
# Remove some unneeded columns:
  
  courtship <- subset(courtship, select = 
                        -c(Day, start_time_program, Activity, 
                           trial_latency_behav_end, Video_Initition, 
                           Video_End, startTimeSeconds) )
  
# Need to get all courtship under 900 seconds (relative court duration)
  
# First, transition step for finding values ending abov 900
  courtship$nineHundredTransition <- (900 - courtship$relativeTrial_latency_end)
  
# Second, if value for nineHundredTransition is negative, equate it to 900, all else stay as relativeTrial_latency_end
  
  courtship$relativeTrialLatency900 <- ifelse(courtship$nineHundredTransition<0,
                                              900,
                                              courtship$relativeTrial_latency_end)
  
# Third, relative courtship duration (not including values over 900)
  courtship$relativeCourtDuration <- (courtship$relativeTrialLatency900 - courtship$relativeStartTimeSeconds)
  
# Rename Box to treatment type, and make characters to factor
  
  courtship$Treatment <- ifelse(courtship$Box=="A",
                                "Predator",
                                "Control")
  
  courtship$Treatment <- factor(courtship$Treatment)

# Remove unnessary columns:
  courtship <- subset(courtship, select =
                        -c(Box, court_duration, relativeTrial_latency_end, 
                           nineHundredTransition))

# Calculate time courting in 900 seconds, count of courtship bouts and relative time courting in 900 seconds (15 minutes)
  courtship2 <- subset(courtship, relativeCourtDuration>0)
  
  courtship2 <- courtship2 %>%
    group_by(Date,Replicate,Vial_number,Observation.Initiation, Treatment) %>%
    summarise(Court_sum=sum(relativeCourtDuration), 
              count=n(), 
              court_prop=sum(relativeCourtDuration/900))
  
## Running 2 models: one for proportion of time courting, one of courtship bouts

# Model of proprtion of time courting:
  courtship_model1 <- lmer(court_prop ~ Treatment + 
                             (1|Date), 
                           data=courtship2 )
  
  corprop_eff <- effect("Treatment", courtship_model1)
  
  corprop_eff <- as.data.frame(corprop_eff)
  
  corprop_eff$Behaviour <- "Proportion Time Courting"
  
# Summary of model 1
  summary(courtship_model1)
  car::Anova(courtship_model1)
  
  gg_courtProp <- ggplot(corprop_eff, aes(x=Treatment, y=fit, shape=Treatment))
  gg_courtProp2 <- gg_courtProp + 
    ylab("Proportion of Time Courting") + 
    xlab("") +
    ylim(0,1) +
    geom_point(stat="identity", 
               position = position_dodge(.9), size=6, show.legend = F) +
    geom_errorbar(aes(ymin = lower, ymax = upper), 
                  position = position_dodge(.9), 
                  size = 1.2, 
                  width = 0.2, show.legend = F) + 
    theme(text = element_text(size=15), 
          #     axis.text.x=element_blank(),
          axis.text.x= element_text(size=12.5),
          axis.ticks.x=element_blank()) +
    scale_shape_manual(values=c(15, 17)) + 
    scale_color_manual(values=c("#999999", "#E69F00"))
  
  print(gg_courtProp2)
  
# Model 2: Count of courtship behaviours:
  
  courtship_model2 <- lmer(count ~ Treatment  + 
                             (1|Date), 
                           data = courtship2)
  
  
  corcount_eff<- effect("Treatment", courtship_model2)
  corcount_eff <- as.data.frame(corcount_eff)
  corcount_eff$Behaviour <- "Courtship Bouts"
  summary(courtship_model2)
  car::Anova(courtship_model2)
  
  gg_courtcount <- ggplot(corcount_eff, aes(x=Treatment, y=fit, shape=Treatment))
  gg_courtcount2 <- gg_courtcount + 
    ylab("Number of Courtship Bouts") + 
    xlab("") +
    ylim(9,20) +
    geom_point(stat="identity", 
               position = position_dodge(.9), size=6, show.legend = F) +
    geom_errorbar(aes(ymin = lower, ymax = upper), 
                  position = position_dodge(.9), 
                  size = 1.2, 
                  width = 0.2, show.legend = F) + 
    theme(text = element_text(size=15), 
          #     axis.text.x=element_blank(),
          axis.text.x= element_text(size=12.5),
          axis.ticks.x=element_blank()) +
    scale_shape_manual(values=c(15, 17))+
    scale_color_manual(values=c("#999999", "#E69F00"))
  
  print(gg_courtcount2)
  
  
# Plot both into two panels: 
multiplot(gg_courtProp2, gg_courtcount2, cols=2)
# N = 64 per treatment
## Attempt to facet wrap: 
#Xcx <- rbind(corcount_eff, corprop_eff)  

#ggplot(Xcx, aes(x = Treatment, y = fit)) + facet_wrap(~Behaviour, scales = "free") + geom_point()
