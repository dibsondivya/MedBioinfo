#!/bin/sh
#SBATCH--account=naiss2024-22-540 
#SBATCH --mem=90G  # memory in Gb
#SBATCH -t 01:00:00  # time requested in hour:minute:second
#SBATCH -o /home/x_vaish/../../proj/applied_bioinformatics/users/x_vaish/MedBioinfo/analyses/kraken2/output/slurm.%A.%a.out   # standard output (STDOUT) redirected to these files (with Job ID and array ID in file names)
#SBATCH -e /home/x_vaish/../../proj/applied_bioinformatics/users/x_vaish/MedBioinfo/analyses/kraken2/output/slurm.%A.%a.err   # standard error  (STDERR) redirected to these files (with Job ID and array ID in file names)
#SBATCH --array=1-8

workdir="/home/x_vaish/../../proj/applied_bioinformatics/users/x_vaish"
datadir="/home/x_vaish/../../proj/applied_bioinformatics/users/x_vaish/MedBioinfo/data/sra_fastq"
accnum_file="/home/x_vaish/../../proj/applied_bioinformatics/users/x_vaish/MedBioinfo/analyses/x_vaish_run_accessions.txt"
outputdir="/home/x_vaish/../../proj/applied_bioinformatics/users/x_vaish/MedBioinfo/analyses/kraken2"

echo START: `date`

cd ${workdir}

# this extracts the item number $SLURM_ARRAY_TASK_ID from the file of accnums
accnum=$(sed -n "$SLURM_ARRAY_TASK_ID"p ${accnum_file})
input_file1="${datadir}/${accnum}_1.fastq.gz"
input_file2="${datadir}/${accnum}_2.fastq.gz"
kraken_output="${outputdir}/${accnum}.output"
kraken_report="${outputdir}/${accnum}.report"
bracken_output="${outputdir}/${accnum}.brackenoutput"
bracken_report="${outputdir}/${accnum}.brackenreport"
bracken_sortedreport="${outputdir}/${accnum}.sortedbrackenreport"


srun --job-name=kraken2_${accnum} singularity exec -B /proj:/proj /home/x_vaish/../../proj/applied_bioinformatics/common_data/kraken2.sif kraken2 --db /home/x_vaish/../../proj/applied_bioinformatics/common_data/kraken_database/ --threads 2 --gzip-compressed --output ${kraken_output} --report ${kraken_report} --paired ${input_file1} ${input_file2} 
srun --job-name=bracken_${accnum} singularity exec -B /proj:/proj /home/x_vaish/../../proj/applied_bioinformatics/common_data/kraken2.sif bracken -d /home/x_vaish/../../proj/applied_bioinformatics/common_data/kraken_database/ -i ${kraken_report}  -o ${bracken_output}  -w ${bracken_report} 
# show bracken report in order of increasing species abundance
srun --job-name=sorting_${accnum} awk '($4 == "S")' ${bracken_report} | sort -s -n --key=1,1 > ${bracken_sortedreport}

echo END: `date`
