#!/usr/bin/env Rscript

library("tidyverse")
library("ggplot2")

setwd("~/Desktop/Lotterhos_Lab/VCF")

#Command Line options
args <- commandArgs(trailingOnly = TRUE)
fn <- args[1]
dataNumber <- args[2]

#Read file into R as df
tassel_data<-read.table(fn, header = T, sep = "\t")

#Benjamini Hochberg adjustment
q<-p.adjust(tassel_data$p, method = "BH")
tassel_data$Q<-q

#Significant loci stored in a df
tassel_data_significant<-tassel_data %>%
  filter(Q < 0.05) %>%
  filter(add_effect != "NaN")

#Non significant loci stored in a df
tassel_data_not_significant<-tassel_data %>%
  filter(Q > 0.05) %>%
  filter(add_effect != "NaN")

#Write data frames to separate outfiles
significant_outfile<-paste0("~/Desktop/Lotterhos_Lab/VCF/",dataNumber,".MLM.significant.txt")
not_significant_outfile<-paste0("~/Desktop/Lotterhos_Lab/VCF/",dataNumber,".MLM.not_significant.txt")

write.table(tassel_data_significant, significant_outfile, sep = "\t", row.names = FALSE)
write.table(tassel_data_not_significant, not_significant_outfile, sep = "\t", row.names = FALSE)