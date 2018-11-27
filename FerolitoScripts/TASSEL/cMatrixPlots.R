#!/usr/bin/env Rscript

########################################################################
# 
# File   :  cMatrixPlots.R
# History:  This program was written by Brian Ferolito   
#
########################################################################
# 
# This program loads the four files with the true positive, false 
# positive, false negative, and true positve information. A for loop is 
# used to do this for each of the 60 data sets. Expected vs observed
# is plotted for both additive and dominance effects for the true 
# positive values, false negative values, and false positive values. 
# The number of true positives, false negatives, false positives, and 
# true positives are written to an outfile with each row representing a 
# dataset. 
#
########################################################################

CM.outfile<-file.create("~/Desktop/Lotterhos_Lab/allPlots/confusion_matrix.txt")
fileConn<-file("~/Desktop/Lotterhos_Lab/allPlots/confusion_matrix.txt")
CM.header<-paste("True Positive", "False Negative", "False Positive", "True Negative", "False Negative Missing Values", sep = "\t")
writeLines(CM.header, fileConn)

for (i in c(10900:10920, 10922:10925, 10927:10961)) {

fileNumber<-i

TP.file<-paste0("~/Desktop/Lotterhos_Lab/VCF/", fileNumber, ".domAdd.TP.txt")
FN.file<-paste0("~/Desktop/Lotterhos_Lab/VCF/", fileNumber, ".domAdd.FN.txt")
FP.file<-paste0("~/Desktop/Lotterhos_Lab/VCF/", fileNumber, ".domAdd.FP.txt")
TN.file<-paste0("~/Desktop/Lotterhos_Lab/VCF/", fileNumber, ".domAdd.TN.txt")
FN.missing.file<-paste0("~/Desktop/Lotterhos_Lab/VCF/", fileNumber, ".domAddMissing.FN.txt")


TP.table<-read.table(TP.file, header = TRUE)
FN.table<-read.table(FN.file, header = TRUE)
FP.table<-read.table(FP.file, header = TRUE)
TN.table<-read.table(TN.file, header = TRUE)
FN.missing.table<-read.table(FN.missing.file, header = TRUE)

TN.table$expectedAdditive<-0
FN.missing.table$expectedAdditive<-0

#Path to write plots

path<-paste0("~/Desktop/Lotterhos_Lab/VCF/", fileNumber, ".plots/")

#TRUE POSITIVE
#########################################################################################################
library(ggplot2)
TP.table$expectedAdditive<-abs(TP.table$expectedAdditive)
TP.table$tasselAdditive<-abs(TP.table$tasselAdditive)

truePositiveNumber<-length(TP.table$basePairPosition)

x.min.add<-min(TP.table$expectedAdditive)
x.max.add<-max(TP.table$expectedAdditive)
y.min.add<-min(TP.table$tasselAdditive)
y.max.add<-max(TP.table$tasselAdditive)

#Determine how to set the x and y axis range

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

#True Positive additive effect

ggplot(data = TP.table) +
  geom_point(mapping = aes(x = expectedAdditive, y = tasselAdditive)) +
  xlab("Expected Additive") + ylab("Observed Additive") +
  ggtitle("Observed vs Expected Additive Effects for Significant and Causal Loci") +
  geom_abline(mapping = NULL, slope = 1, yintercept = 0) +
  theme(aspect.ratio = 1) +
  coord_cartesian(xlim = c(min.add, max.add), ylim = c(min.add, max.add), expand = FALSE) +
  theme(plot.title = element_text(hjust = 0.4))

outfile<-paste0(fileNumber, "_TP.EvsO.add.png")
ggsave(outfile, last_plot(), path = path)
unlink(outfile)

x.min.dom<-min(TP.table$expectedDominance)
x.max.dom<-max(TP.table$expectedDominance)
y.min.dom<-min(TP.table$tasselDominance)
y.max.dom<-max(TP.table$tasselDominance)

#Determine how to set the x and y axis range

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

#True Positive dominance effect

ggplot(data = TP.table) +
  geom_point(mapping = aes(x = expectedDominance, y = tasselDominance)) +
  xlab("Expected Dominance") + ylab("Observed Dominance") +
  ggtitle("Observed vs Expected Dominance Effects for Significant and Causal Loci") +
  geom_abline(mapping = NULL, slope = 1, yintercept = 0) +
  theme(aspect.ratio = 1) +
  coord_cartesian(xlim = c(min.dom, max.dom), ylim = c(min.dom, max.dom), expand = FALSE) +
  theme(plot.title = element_text(hjust = 0.4))

outfile<-paste0(fileNumber, "_TP.EvsO.dom.png")
ggsave(outfile, plot = last_plot(), path = path)
unlink(outfile)


#FALSE NEGATIVE
########################################################################################################

FN.table$expectedAdditive<-abs(FN.table$expectedAdditive)
FN.table$tasselAdditive<-abs(FN.table$tasselAdditive)

falseNegativeNumber<-length(FN.table$basePairPosition)

if(falseNegativeNumber > 0){

  x.min.add<-min(FN.table$expectedAdditive)
  x.max.add<-max(FN.table$expectedAdditive)
  y.min.add<-min(FN.table$tasselAdditive)
  y.max.add<-max(FN.table$tasselAdditive)

  #Determine how to set the x and y axis range
  
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

  #False Negative additive effect
  
  ggplot(data = FN.table) +
    geom_point(mapping = aes(x = expectedAdditive, y = tasselAdditive)) +
    xlab("Expected Additive") + ylab("Observed Additive") +
    ggtitle("Observed vs Expected Additive Effects for Nonsignificant and Causal Loci") +
    geom_abline(mapping = NULL, slope = 1, yintercept = 0) +
    theme(aspect.ratio = 1) +
    coord_cartesian(xlim = c(min.add, max.add), ylim = c(min.add, max.add), expand = FALSE) +
    theme(plot.title = element_text(hjust = 0.4))

  outfile<-paste0(fileNumber, "_FN.EvsO.add.png")
  ggsave(outfile, last_plot(), path = path)
  unlink(outfile)

  x.min.dom<-min(FN.table$expectedDominance)
  x.max.dom<-max(FN.table$expectedDominance)
  y.min.dom<-min(FN.table$tasselDominance)
  y.max.dom<-max(FN.table$tasselDominance)

  #Determine how to set the x and y axis range
  
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

  #False Negative dominance effect
  
  ggplot(data = FN.table) +
    geom_point(mapping = aes(x = expectedDominance, y = tasselDominance)) +
    xlab("Expected Dominance") + ylab("Observed Dominance") +
    ggtitle("Observed vs Expected Dominance Effects for Nonsignificant and Causal Loci") +
    geom_abline(mapping = NULL, slope = 1, yintercept = 0) +
    theme(aspect.ratio = 1) +
    coord_cartesian(xlim = c(min.dom, max.dom), ylim = c(min.dom, max.dom), expand = FALSE) +
    theme(plot.title = element_text(hjust = 0.4))
  

  outfile<-paste0(fileNumber, "_FN.EvsO.dom.png")
  ggsave(outfile, last_plot(), path = path)
  unlink(outfile)
}
#FALSE POSITIVE
########################################################################################################

FP.table$tasselAdditive<-abs(FP.table$tasselAdditive)
FP.table$expectedAdditive<-0

falsePositiveNumber<-length(FP.table$basePairPosition)

x.min.add<-min(FP.table$expectedAdditive)
x.max.add<-max(FP.table$expectedAdditive)
y.min.add<-min(FP.table$tasselAdditive)
y.max.add<-max(FP.table$tasselAdditive)

#Determine how to set the x and y axis range

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

#False Positive additive effect

ggplot(data = FP.table) +
  geom_point(mapping = aes(x = expectedAdditive, y = tasselAdditive)) +
  xlab("Expected Additive") + ylab("Observed Additive") +
  ggtitle("Observed vs Expected Additive Effects for Significant and Neutral Loci") +
  geom_abline(mapping = NULL, slope = 1, yintercept = 0) +
  theme(aspect.ratio = 1) +
  coord_cartesian(xlim = c(min.add, max.add), ylim = c(min.add, max.add), expand = TRUE) +
  theme(plot.title = element_text(hjust = 0.4))

outfile<-paste0(fileNumber, "_FP.EvsO.add.png")
ggsave(outfile, last_plot(), path = path)
unlink(outfile)

x.min.dom<-min(FP.table$expectedDominance)
x.max.dom<-max(FP.table$expectedDominance)
y.min.dom<-min(FP.table$tasselDominance)
y.max.dom<-max(FP.table$tasselDominance)

#Determine how to set the x and y axis range

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

#False Positive dominance effect

ggplot(data = FP.table) + 
  geom_point(mapping = aes(x = expectedDominance, y = tasselDominance)) +
  xlab("Expected Dominance") + ylab("Observed Dominance") +
  ggtitle("Observed vs Expected Dominance Effects for Significant and Neutral Loci") +
  geom_abline(mapping = NULL, slope = 1, yintercept = 0) +
  coord_cartesian(xlim = c(min.dom, max.dom), ylim = c(min.dom, max.dom), expand = TRUE) +
  theme(plot.title = element_text(hjust = 0.4))

outfile<-paste0(fileNumber, "_FP.EvsO.dom.png")
ggsave(outfile, last_plot(), path = path)
unlink(outfile)


#Store confusion matrix data in a table
########################################################################################################

trueNegativeNumber<-length(TN.table$basePairPosition)
falseNegativeMissingNumber<-length(FN.missing.table$basePairPosition)

CM.lines<-paste(truePositiveNumber, falseNegativeNumber, falsePositiveNumber, trueNegativeNumber, falseNegativeMissingNumber, sep = "\t")
fileConn<-file("~/Desktop/Lotterhos_Lab/allPlots/confusion_matrix.txt")
writeLines(CM.lines, fileConn)

message <-paste0("Done with ", fileNumber)
print(message)

}#End of Initial For Loop to Iterate Over Datasets

close(fileConn)
