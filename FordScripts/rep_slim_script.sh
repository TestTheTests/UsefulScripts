#!/bin/bash
set -e
set -u
set -o pipefail

######################################################################################
#
# rep_slim_script.sh
# Brett Ford
# Created 20180515
#
#
# This script runs simulations for all unique combinations of parameters
# provided
#
# Usage: bash rep_slim_script.sh
#
#######################################################################################

#separate values in arrays by spaces
#create more lists for additional constants you wish to define
declare -a lista=(0.5 1.0 1.25)
declare -a listb=(0.5 1.0 1.25)
declare -a listc=(2.0 3.0 4.0)
declare -a listd=(0.008 0.009)

#rep the for loop for the number of constants you are defining

for i in "${lista[@]}"
do
  for j in "${listb[@]}"
  do
    for k in "${listc[@]}"
    do
      for l in "${listd[@]}"
      do
          #change slim file depending on base parameters you want to run with the constants you are defining
          # & specifies to run script in the background
          slim -d "sigma_K=${i}" -d "QTL_var=${j}" -d "sigma_stat=${k}" -d "sigma_d=${l}" LocalAdapt2trait_1mut_2env_20180514_d0.009_c0.027_var.slim &
          # sleep for a bit before running next simulation
          sleep 10s
      done
    done
  done
done
