for R1 in *R1*
do 
R2=${R1//R1_001.fastq/R2_001.fastq}
R1paired=${R1//.fastq/_paired.fastq}
R1unpaired=${R1//.fastq/_unpaired.fastq}
R2paired=${R2//.fastq/_paired.fastq}
R2unpaired=${R2//.fastq/_unpaired.fastq}
trimmomatic PE -threads 4 -phred33 $R1 $R2 $R1paired $R1unpaired $R2paired $R2unpaired ILLUMINACLIP:TruSeq3-PE-2.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
done
