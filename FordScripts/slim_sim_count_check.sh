#!/bin/bash
set -e
set -u
set -o pipefail

######################################################################################
#
# slim_sim_count_check.sh
# Brett Ford
# Created 20180515
#
# This script prints the number of parameter combinations from the lists provided
#
# Usage: bash slim_sim_count_check.sh
#
#######################################################################################

#separate values in arrays by spaces
#create more lists for additional constants you wish to define
declare -a lista=(0.5, 1.0, 1.25)
declare -a listb=(0.5, 1.0, 1.25)
declare -a listc=(2.0, 3.0, 4.0)
declare -a listd=(0.008, 0.009)

#set counter to count number of combinations
count=0

#rep the for loop for the number of constants you are defining
for i in "${lista[@]}"
do
  for j in "${listb[@]}"
  do
      for k in "${listc[@]}"
      do
        for l in "${listd[@]}"
        do
          echo $i $j $k $l
          count=$(( $count + 1 ))
        done
      done
  done
done

#print total number of simulations
echo "Total number of simulations:" $count
