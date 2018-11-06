### Files
Trimmomatic_AutoBatchFastq.sh
+ Bash script that reads all paired end R1 and R2 uncompressed fastq files and outputs correctly named Paired/Unpaired files  
+ Requires primer sequence file TruSeq3-PE-2.fa to be in directory  
+ Trimmomatic parameters encoded (that can be modified) are: -threads 4; -phred33; ILLUMINACLIP:TruSeq3-PE-2.fa:2:30:10; LEADING:3; TRAILING:3; SLIDINGWINDOW:4:15; MINLEN:36.  
 
