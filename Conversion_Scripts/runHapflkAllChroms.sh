#!/usr/bin/bash
chrStart=2
chrFinish=10
K=15
ncpu=4
inputDir="/home/kevin/LOTTERHOS_LAB/UsefulScripts/hapflk/10944_split"

echo "chr $chrStart to  $chrFinish"
echo "running hapflk with K = $K"
echo

for i in $(seq $chrStart $chrFinish)
do
	hapflk --file "${inputDir}/10944_Invers_VCFallFILT_chr$i" \
		-p 10944_chr$i --kinship "${inputDir}/10944_hapflk_fij.txt" \
		-K $K --nfit=20 --ncpu=$ncpu
	wait
done

