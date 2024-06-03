#!/bin/sh
#SBATCH--account=naiss2024-22-540 
#SBATCH --mem=90G  # memory in Gb
#SBATCH -t 00:30:00  # time requested in hour:minute:second
#SBATCH -o /home/x_vaish/../../proj/applied_bioinformatics/users/x_vaish/MedBioinfo/analyses/krona/output/slurm.%A.%a.out   # standard output (STDOUT) redirected to these files (with Job ID and array ID in file names)
#SBATCH -e /home/x_vaish/../../proj/applied_bioinformatics/users/x_vaish/MedBioinfo/analyses/krona/output/slurm.%A.%a.err   # standard error  (STDERR) redirected to these files (with Job ID and array ID in file names)
#SBATCH --array=1-8

workdir="/home/x_vaish/../../proj/applied_bioinformatics/users/x_vaish"
accnum_file="/home/x_vaish/../../proj/applied_bioinformatics/users/x_vaish/MedBioinfo/analyses/x_vaish_run_accessions.txt"
inputdir="/home/x_vaish/../../proj/applied_bioinformatics/users/x_vaish/MedBioinfo/analyses/kraken2"
outputdir="/home/x_vaish/../../proj/applied_bioinformatics/users/x_vaish/MedBioinfo/analyses/krona"

echo START: `date`

cd ${workdir}

# this extracts the item number $SLURM_ARRAY_TASK_ID from the file of accnums
accnum=$(sed -n "$SLURM_ARRAY_TASK_ID"p ${accnum_file})
kraken_report="${inputdir}/${accnum}.report"
krona="${outputdir}/${accnum}.krona"
krona_html="${outputdir}/${accnum}.krona.html"

srun --job-name=krona_${accnum} python /home/x_vaish/../../proj/applied_bioinformatics/tools/KrakenTools/kreport2krona.py -r ${kraken_report} -o ${krona} 
srun --job-name=sed_${accnum}  sed -E 's/[a-z]__//g' -i.backup ${krona}
srun --job-name=kronahtml_${accnum} singularity exec -B /proj:/proj /home/x_vaish/../../proj/applied_bioinformatics/common_data/kraken2.sif ktImportText ${krona} -o ${krona_html} 

echo END: `date`
