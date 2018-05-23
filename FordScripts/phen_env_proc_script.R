######################################
#
# phen_env_proc_script.R
# Brett Ford
# Created 20180514
# Added annotations and fixed plot name 20180515 
# Modified to create two-pane plot to display correlations for both phenotypes
#
# This script takes the PhenEnv files in the results folder
# and plots the correlation between the phenotypes and environments specified 
# (e.g. phenotype 1 and environment 1)
# as a function of simulation generation,
# with a lable specifying the seed number
#
# The current script plots correlation of phenotype 0 with environment 1
# and phenotype 1 with environment 2 (the enviornments they are adapting to)
#
# Each simulation in plot will have a unique color
# Works best for simulations with same number of total generations
#
# Things that may need to be changed depending on simulation:
# xlim and ylim (currently set to hard limits of c(0,10000) and c(-0.3, 0.5)
# what correlation you want to look at (currently set to corr0_1; phen 0 and env 1)
#
# Usage: Rscript phen_env_proc_script.R
#
######################################

#Change the following to your working directory and results folder within wd
setwd("/home/br.ford/br.ford_remote/slim")
results_path <- "/home/br.ford/br.ford_remote/slim/results/"

#Load libraries
library(tidyr)
library(grid)
library(ggplot2)
library(RColorBrewer)

#Obtain phenenv files
filename <- list.files(path=results_path, pattern=".+outputPhenEnv_")

#Create unique color list for plot
n <- length(filename)
qual_col_pals = brewer.pal.info[brewer.pal.info$category == 'qual',]
color_list <- unlist(mapply(brewer.pal, qual_col_pals$maxcolors, rownames(qual_col_pals)))

#Create an empty vector to keep track of colors used; so as not to repeat in plot
colors_used <- character()

#Create output parameters for plot before plotting
png("phen_env_corr.png", width=10, height = 8, units="in", res=500)

#Prepare two-pane plot
par(mfcol=c(1,2))

#Cycle through each file, get seed, read in table, and plot points and line with seed label
for (i in filename) {
  print(i)
  file_contents <- unlist(strsplit(i, split="[_]"))
  
  #line below works if seed is at the beginning of file name
  seed <- file_contents[1]
  
  #make sure file is tab separated
  phen_env_table <- read.table(paste0(results_path, i), header = T, sep = "\t")
  
  linecolor <- sample(color_list, 1, replace = FALSE)
  plot(phen_env_table$sim.generation, phen_env_table$corr0_1, pch=19, type= "p",
       col= linecolor, bg= linecolor, xlim=c(0, 10000), ylim= c(-0.3, 0.5),
       xlab="Simulation Generation", ylab= "Phenotype-Environment Correlation")
  lines(phen_env_table$sim.generation, phen_env_table$corr0_1, col= linecolor)
  
  #add seed as a label to the end of each line
  text(x = max(as.numeric(phen_env_table$sim.generation), na.rm = T),
       y = phen_env_table$corr0_1[nrow(phen_env_table)], labels= as.character(seed),
       pos=4, col=linecolor, cex= 0.8)

  #Keep track of colors used so they aren't used twice
  colors_used <- c(colors_used, linecolor)
  color_list <- color_list[!color_list %in% colors_used]
  
  #Add additional lines to plot
  par(new=TRUE)
}

#Run following code to switch to plotting to second pane
par(new=FALSE)

k=0
for (i in filename) {
  print(i)
  k=k+1
  file_contents <- unlist(strsplit(i, split="[_]"))
  seed <- file_contents[1]
  phen_env_table <- read.table(paste0(results_path, i), header = T, sep = "\t")
  #linecolor <- sample(color_list, 1, replace = FALSE)
  linecolor <- colors_used[k]
  plot(phen_env_table$sim.generation, phen_env_table$corr1_2, pch=19, type= "p",
       col= linecolor, bg= linecolor, xlim=c(0, 10000), ylim= c(-0.3, 0.5),
       xlab="Simulation Generation", ylab= "Phenotype-Environment Correlation")
  lines(phen_env_table$sim.generation, phen_env_table$corr1_2, col= linecolor)
  text(x = max(as.numeric(phen_env_table$sim.generation), na.rm = T),
       y = phen_env_table$corr1_2[nrow(phen_env_table)], labels= as.character(seed),
       pos=4, col=linecolor, cex= 0.8)

  #Keep track of colors used so they aren't used twice
  colors_used <- c(colors_used, linecolor)
  color_list <- color_list[!color_list %in% colors_used]
  par(new=TRUE)
}

# write png file
dev.off()
