#!/usr/bin/env Rscript

########################################################################
# 
# File   :  determineSignificantLoci.R
# History:  This program was written by Brian Ferolito   
#
########################################################################
#
# This program loops through 60 data sets and obtains two files 
# associated with each data set. The first file is the output of a mixed
# linear model from TASSEL which contains observed additive and 
# dominance effects. The second file is scanResults which contains the 
# expected additive and dominance effects for each loci. The two files
# are merged into a single data frame. A new column is created to label
# the loci as significant (based on q value) for the TASSEL additive and
# dominance effect. 6 plots are then constructed comparing expected vs 
# observed for different scenarios. These plots are plotted together 
# and the plot is written to a png file.
#
########################################################################
#
# This first section takes the tassel file and selects for the variables 
# that are desired. The Tassel file, along with the scan results file, are 
# determined the manually entered data set number. The variables selected 
# are: chromosome, position, additive effects, additive p value, dominance 
# effect, and dominance p value. FDR adjustment is then conducted with the
# benjamini hochberg method. The new q values are stored as their own 
# columns.

library("tidyverse")
library("ggplot2")

setwd("~/Desktop/Lotterhos_Lab/VCF")

#skipping the 21st and 26th dataset 
for(j in c(10900:10920, 10922:10925, 10927:10961)){

dataNumber<-j

inFile<-paste0(dataNumber, ".MLM.txt")

#Read file into R as df
tassel_data<-read.table(inFile, header = T, sep = "\t")

tassel_data<-tassel_data %>%
  select(Chr, Pos, add_effect, add_p, dom_effect, dom_p) %>%
  filter(add_effect != "NaN")

#Benjamini Hochberg adjustment
add_q<-p.adjust(tassel_data$add_p, method = "BH")
tassel_data$add_q<-add_q

dom_q<-p.adjust(tassel_data$dom_p, method = "BH")
tassel_data$dom_q<-dom_q

########################################################################
#
# The q values are then looped over. If they are above 0.05 they are 
# deemed non significant and if they are less than 0.05 they are 
# significant. A lable is created for each loci. The labels are as 
# follows:
#   
# AS: Additive Significant
# AN: Additive Nonsignificant
# DS: Dominance Significant
# DN: Dominance Nonsignificant

n<-nrow(tassel_data)

tassel_data$add_label<-0
tassel_data$dom_label<-0

for (i in 1:n){
  if (tassel_data$add_q[i] < 0.05){
    tassel_data$add_label[i]<-"AS"
  }else{
    tassel_data$add_label[i]<-"AN"
  }
  
  if (tassel_data$dom_q[i] < 0.05){
    tassel_data$dom_label[i]<-"DS"
  }else{
    tassel_data$dom_label[i]<-"DN"
  }
  
}

########################################################################
#
# I then load the scanResults file into R. The appropriate variables are 
# then selected. The dominance effects are all set to zero. The column 
# names are changed to be more informative and to match with the Tassel 
# file. The NAs in the additive effects columns are set to zero.

scan.InFile<-paste0(dataNumber, "_Invers_ScanResults.txt")

scanResults<-read.table(scan.InFile, header = T)

scanResults <- scanResults %>%
  select(pos, chrom, muttype, selCoef)

scanResults$expDom<-0

colnames(scanResults)[colnames(scanResults)=="selCoef"] <- "expAdd"
colnames(tassel_data)[colnames(tassel_data)=="Pos"] <- "pos"

scanResults$expAdd<-ifelse(is.na(scanResults$expAdd), 0, scanResults$expAdd)

########################################################################
#
# Join tables with annotated data. There is a problem here with multiple 
# loci at the same base pair position. I solve this by setting the second 
# base pair to the postion plus 0.2. For instance postion 3 would be 3.2 
# where the 2 denotes that is the second at that position. After 
# accomplishing this, I then join the two tables with bothe the Tassel 
# and scanResults information contained in a single observation.

n<-nrow(scanResults)

for (i in 2:n) {
  if(scanResults$pos[i] == scanResults$pos[i-1]){
    scanResults$pos[i]<- scanResults$pos[i] + 0.2
    
  }
}

n<-nrow(tassel_data)

for (i in 2:n) {
  if(tassel_data$pos[i] == tassel_data$pos[i-1]){
    tassel_data$pos[i]<- tassel_data$pos[i] + 0.2
    
  }
}

exp.vs.obs<- tassel_data %>% 
  inner_join(scanResults, by = "pos")

# I then take the absolute value of the additive effects for both datasets. 

exp.vs.obs$add_effect<-abs(exp.vs.obs$add_effect)
exp.vs.obs$expAdd<-abs(exp.vs.obs$expAdd)

########################################################################
#
# I then created 6 new data frames for the additive and dominance effects. 
# The true positives are when the effect is significant and the loci is 
# expected to be causal. The false negative is when the effect is non 
# significant and the loci is causal. The false positive is when the 
# effect is significant and loci is neutral. 

true.positive.add<-exp.vs.obs %>%
  filter(add_label == "AS" & muttype == "MT=2")

true.positive.dom<-exp.vs.obs %>%
  filter(dom_label == "DS" & muttype == "MT=2")

false.negative.add<-exp.vs.obs %>%
  filter(add_label == "AN" & muttype == "MT=2")

false.negative.dom<-exp.vs.obs %>%
  filter(dom_label == "DN" & muttype == "MT=2")

false.positive.add<-exp.vs.obs %>%
  filter(add_label == "AS" & muttype == "MT=1")

false.positive.dom<-exp.vs.obs %>%
  filter(dom_label == "DS" & muttype == "MT=1")

########################################################################
#
# I then determine the maximum and minimum values for effects all three 
# additive data frames so that I can set the x and y axis range the same 
# for all three graphs without missing any data. 

expAddAll<-c(true.positive.add$expAdd, false.negative.add$expAdd, false.positive.add$expAdd)
obsAddAll<-c(true.positive.add$add_effect, false.negative.add$add_effect, false.positive.add$add_effect)

x.min.add<-min(expAddAll)
x.max.add<-max(expAddAll)
y.min.add<-min(obsAddAll)
y.max.add<-max(obsAddAll)

if(x.min.add < y.min.add){
  min.add<-x.min.add
}else{
  min.add<-y.min.add
}

if(x.max.add > y.max.add){
  max.add<-x.max.add
}else{
  max.add<-y.max.add
}

min.add<-min.add - 0.25
max.add<-max.add + 0.25

# I then do the same for the dominance data frames.

expDomAll<-c(true.positive.dom$expDom, false.negative.dom$expDom, false.positive.dom$expDom)
obsDomAll<-c(true.positive.dom$dom_effect, false.negative.dom$dom_effect, false.positive.dom$dom_effect)

x.min.dom<-min(expDomAll)
x.max.dom<-max(expDomAll)
y.min.dom<-min(obsDomAll)
y.max.dom<-max(obsDomAll)

if(x.min.dom < y.min.dom){
  min.dom<-x.min.dom
}else{
  min.dom<-y.min.dom
}

if(x.max.dom > y.max.dom){
  max.dom<-x.max.dom
}else{
  max.dom<-y.max.dom
}

min.dom<-min.dom - 0.15
max.dom<-max.dom + 0.15

########################################################################
#
# Next, I create the observed vs expected plots and store them in variables.

tp.a<-ggplot(data = true.positive.add) +
  geom_point(mapping = aes(x = expAdd, y = add_effect)) +
  xlab("Expected Additive") + ylab("Observed Additive") +
  ggtitle("True Positive") +
  #ggtitle("Observed vs Expected Additive Effects for Significant and Causal Loci") +
  geom_abline(mapping = NULL, slope = 1, yintercept = 0) +
  theme(aspect.ratio = 1) +
  coord_cartesian(xlim = c(min.add, max.add), ylim = c(min.add, max.add), expand = FALSE) +
  theme(plot.title = element_text(hjust = 0.4))

tp.d<-ggplot(data = true.positive.dom) +
  geom_point(mapping = aes(x = expDom, y = dom_effect)) +
  xlab("Expected Dominance") + ylab("Observed Dominance") +
  ggtitle("True Positive") +
  #ggtitle("Observed vs Expected Dominance Effects for Significant and Causal Loci") +
  geom_abline(mapping = NULL, slope = 1, yintercept = 0) +
  theme(aspect.ratio = 1) +
  coord_cartesian(xlim = c(min.dom, max.dom), ylim = c(min.dom, max.dom), expand = TRUE) +
  theme(plot.title = element_text(hjust = 0.4))

fn.a<-ggplot(data = false.negative.add) +
  geom_point(mapping = aes(x = expAdd, y = add_effect)) +
  xlab("Expected Additive") + ylab("Observed Additive") +
  ggtitle("False Negative") +
  #ggtitle("Observed vs Expected Additive Effects for Nonsignificant and Causal Loci") +
  geom_abline(mapping = NULL, slope = 1, yintercept = 0) +
  theme(aspect.ratio = 1) +
  coord_cartesian(xlim = c(min.add, max.add), ylim = c(min.add, max.add), expand = FALSE) +
  theme(plot.title = element_text(hjust = 0.4))

fn.d<-ggplot(data = false.negative.dom) +
  geom_point(mapping = aes(x = expDom, y = dom_effect)) +
  xlab("Expected Dominance") + ylab("Observed Dominance") +
  ggtitle("False Negative") +
  #ggtitle("Observed vs Expected Dominance Effects for Nonsignificant and Causal Loci") +
  geom_abline(mapping = NULL, slope = 1, yintercept = 0) +
  theme(aspect.ratio = 1) +
  coord_cartesian(xlim = c(min.dom, max.dom), ylim = c(min.dom, max.dom), expand = TRUE) +
  theme(plot.title = element_text(hjust = 0.4))

fp.a<-ggplot(data = false.positive.add) +
  geom_point(mapping = aes(x = expAdd, y = add_effect)) +
  xlab("Expected Additive") + ylab("Observed Additive") +
  ggtitle("False Positive") +
  #ggtitle("Observed vs Expected Additive Effects for Significant and Neutral Loci") +
  geom_abline(mapping = NULL, slope = 1, yintercept = 0) +
  theme(aspect.ratio = 1) +
  coord_cartesian(xlim = c(min.add, max.add), ylim = c(min.add, max.add), expand = FALSE) +
  theme(plot.title = element_text(hjust = 0.4))

fp.d<-ggplot(data = false.positive.dom) + 
  geom_point(mapping = aes(x = expDom, y = dom_effect)) +
  xlab("Expected Dominance") + ylab("Observed Dominance") +
  ggtitle("False Positive") +
  #ggtitle("Observed vs Expected Dominance Effects for Significant and Neutral Loci") +
  geom_abline(mapping = NULL, slope = 1, yintercept = 0) +
  theme(aspect.ratio = 1) +
  coord_cartesian(xlim = c(min.dom, max.dom), ylim = c(min.dom, max.dom), expand = TRUE) +
  theme(plot.title = element_text(hjust = 0.4))


########################################################################
#
# I write to an outfile using the arrangeGrob function from the 
# gridExtra package.

library(gridExtra)

plotTitle<-paste0("Expected vs Observed Additive and Dominance Effects of Dataset ", dataNumber)
path<-paste0("~/Desktop/Lotterhos_Lab/allPlots/plots/")

g<-arrangeGrob(tp.a, fn.a, fp.a, tp.d, fn.d, fp.d, nrow = 2)

outfile<-paste0(dataNumber, "_expected_vs_observed_effects.png")
ggsave(outfile, g, path = path)
unlink(outfile)

########################################################################

}#End for loop


