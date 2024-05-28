#!/bin/sh
#SBATCH--account=naiss2024-22-540 
#SBATCH --mem=90G  # memory in Gb
#SBATCH -t 00:30:00  # time requested in hour:minute:second

cd /home/x_vaish/../../proj/applied_bioinformatics/users/x_vaish
singularity exec -B /proj:/proj /home/x_vaish/../../proj/applied_bioinformatics/common_data/kraken2.sif kraken2 --db /home/x_vaish/../../proj/applied_bioinformatics/common_data/kraken_database/ --threads 1 --gzip-compressed --output MedBioinfo/analyses/kraken2/ERR6913237.output --report MedBioinfo/analyses/kraken2/ERR6913237.report --paired MedBioinfo/data/sra_fastq/ERR6913237_1.fastq.gz MedBioinfo/data/sra_fastq/ERR6913237_2.fastq.gz
