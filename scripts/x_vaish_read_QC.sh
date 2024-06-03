#!/bin/bash
echo "script start: download and initial sequencing read quality control"
## change directory
cd /home/x_vaish/../../proj/applied_bioinformatics/users/x_vaish/

## get accession info 
sqlite3 -batch ../../common_data/sample_collab.db "SELECT run_accession from sample_annot spl LEFT JOIN sample2bioinformatician s2b using(patient_code) WHERE username='x_vaish';" -noheader -csv > MedBioinfo/analyses/x_vaish_run_accessions.txt
  #ERR6913139
  #ERR6913235
  #ERR6913124
  #ERR6913220
  #ERR6913141
  #ERR6913237
  #ERR6913143
  #ERR6913239
## make subdirectory
# mkdir MedBioinfo/data/sra_fastq
## download fastq via ncbi
### check fastq-dump details via singularity exec meta.sif fastq-dump -h
### experiment with
  ## singularity exec meta.sif fastq-dump -A ERR6913139 --split-files --gzip --readids --disable-multithreading --O MedBioinfo/data/sra_fastq/ -X 10
srun --cpus-per-task=8 --time=00:30:00 --account=naiss2024-22-540 singularity exec meta.sif xargs -I{} -a MedBioinfo/analyses/x_vaish_run_accessions.txt fastq-dump -A {} --split-files --gzip --readids --disable-multithreading --O MedBioinfo/data/sra_fastq/
# can you count the number of reads in each FASTQ file with ordinary generic bash commands ?
  # count number of lines via wc -l <name of FASTQ file>
    # OR awk '{s++}END{print s-1}' <name of FASTQ file>
  # one read is 4 lines
  # divide by 4
#awk '{s++}END{print (s-1)/4}' <filename>
#awk '{s++}END{print (s-1)/4}' ERR6913239_2.fastq.gz
# how are the base call quality scores encoded in these specific FASTQ files ?
  # base call quality scores are found in the 4th line per sequence
    # lines 1,2,3 are seq identfier, sequence and + respectively


echo "script step 2: manipulate raw sequencing FASTQ files with seqkit"
# manipulate raw sequencing FASTQ files with seqkit
### check seqkit details via singularity exec meta.sif seqkit -h
## seqkit sub-command to print statistics on each of the downloaded FASTQ files
  ## singularity exec meta.sif seqkit stats <path to fastq file>
    # Tested with
    # singularity exec meta.sif seqkit stats MedBioinfo/data/sra_fastq/ERR6913239_2.fastq.gz
srun --cpus-per-task=2 --time=00:30:00 --account=naiss2024-22-540 singularity exec meta.sif xargs -I{} -a MedBioinfo/analyses/x_vaish_run_accessions.txt seqkit stats MedBioinfo/data/sra_fastq/{}_1.fastq.gz
srun --cpus-per-task=2 --time=00:30:00 --account=naiss2024-22-540 singularity exec meta.sif xargs -I{} -a MedBioinfo/analyses/x_vaish_run_accessions.txt seqkit stats MedBioinfo/data/sra_fastq/{}_2.fastq.gz

## seqkit sub-command to check if the FASTQ files have been de-replicated (duplicate identical reads removed)
  ## singularity exec meta.sif seqkit rmdup <path to fastq file> -s -o <path to output file>
    # Tested with
    # singularity exec meta.sif seqkit rmdup MedBioinfo/data/sra_fastq/ERR6913239_2.fastq.gz -s -o clean.fa.gz
srun --cpus-per-task=2 --time=00:30:00 --account=naiss2024-22-540 singularity exec meta.sif xargs -I{} -a MedBioinfo/analyses/x_vaish_run_accessions.txt seqkit rmdup MedBioinfo/data/sra_fastq/{}_1.fastq.gz -s -o {}_1_clean.fa.gz
srun --cpus-per-task=2 --time=00:30:00 --account=naiss2024-22-540 singularity exec meta.sif xargs -I{} -a MedBioinfo/analyses/x_vaish_run_accessions.txt seqkit rmdup MedBioinfo/data/sra_fastq/{}_1.fastq.gz -s -o {}_1_clean.fa.gz
srun --cpus-per-task=2 --time=00:30:00 --account=naiss2024-22-540 singularity exec meta.sif xargs -I{} -a MedBioinfo/analyses/x_vaish_run_accessions.txt seqkit rmdup MedBioinfo/data/sra_fastq/{}_2.fastq.gz -s -o {}_2_clean.fa.gz
srun --cpus-per-task=2 --time=00:30:00 --account=naiss2024-22-540 singularity exec meta.sif xargs -I{} -a MedBioinfo/analyses/x_vaish_run_accessions.txt seqkit rmdup MedBioinfo/data/sra_fastq/{}_2.fastq.gz -s -o {}_2_clean.fa.gz

## seqkit sub-command to guess if the FASTQ files have already been trimmed of their sequencing kit adapters (the authors in the Supp. Mat. paper in the docs/ folder indicate that they used NEBNext Ultra II Library Preparation for Illumina, which use the same adapters as Illumina TruSeq)?
  # use locate to search for adaptors AGATCGGAAGAGCACACGTCTGAACTCCAGTCA and AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT
  ## singularity exec meta.sif seqkit locate <path to fastq file> -p AGATCGGAAGAGCACACGTCTGAACTCCAGTCA
  ## singularity exec meta.sif seqkit locate <path to fastq file> -p AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT
    # Tested with
    # singularity exec meta.sif seqkit locate MedBioinfo/data/sra_fastq/ERR6913239_2.fastq.gz -p AGATCGGAAGAGCACACGTCTGAACTCCAGTCA
    # singularity exec meta.sif seqkit locate MedBioinfo/data/sra_fastq/ERR6913239_2.fastq.gz -p AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT
srun --cpus-per-task=2 --time=00:30:00 --account=naiss2024-22-540 singularity exec meta.sif xargs -I{} -a MedBioinfo/analyses/x_vaish_run_accessions.txt seqkit locate MedBioinfo/data/sra_fastq/{}_1.fastq.gz -p AGATCGGAAGAGCACACGTCTGAACTCCAGTCA
srun --cpus-per-task=2 --time=00:30:00 --account=naiss2024-22-540 singularity exec meta.sif xargs -I{} -a MedBioinfo/analyses/x_vaish_run_accessions.txt seqkit locate MedBioinfo/data/sra_fastq/{}_1.fastq.gz -p AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT
srun --cpus-per-task=2 --time=00:30:00 --account=naiss2024-22-540 singularity exec meta.sif xargs -I{} -a MedBioinfo/analyses/x_vaish_run_accessions.txt seqkit locate MedBioinfo/data/sra_fastq/{}_2.fastq.gz -p AGATCGGAAGAGCACACGTCTGAACTCCAGTCA
srun --cpus-per-task=2 --time=00:30:00 --account=naiss2024-22-540 singularity exec meta.sif xargs -I{} -a MedBioinfo/analyses/x_vaish_run_accessions.txt seqkit locate MedBioinfo/data/sra_fastq/{}_2.fastq.gz -p AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT

echo "script step 3: Quality control the raw sequencing FASTQ files with fastQC"
# Quality control the raw sequencing FASTQ files with fastQC
## mkdir MedBioinfo/analyses/fastqc
## check for fastqc help
  # singularity exec meta.sif fastqc -h
## to quality control reads
  # Tested with
  # singularity exec meta.sif fastqc MedBioinfo/data/sra_fastq/ERR6913239_1.fastq.gz MedBioinfo/data/sra_fastq/ERR6913239_2.fastq.gz -o MedBioinfo/analyses/fastqc/ -t 2 --noextract -q
srun --cpus-per-task=2 --time=00:30:00 --account=naiss2024-22-540 singularity exec meta.sif xargs -I{} -a MedBioinfo/analyses/x_vaish_run_accessions.txt fastqc MedBioinfo/data/sra_fastq/{}_1.fastq.gz MedBioinfo/data/sra_fastq/{}_2.fastq.gz -o MedBioinfo/analyses/fastqc/ -t 2 --noextract -q

echo "script step 4: Moving files from remote server to local laptop hard disk"
# Moving files from remote server to local laptop hard disk
## scp -r x_vaish@tetralith.nsc.liu.se:~/../../proj/applied_bioinformatics/users/x_vaish/MedBioinfo/analyses/fastqc/*.html  ~/
# can you conclude from your fastQC output files if:
  # reads have been trimmed to exclude bases with low quality scores (often found nearer the end of reads)?
      # Trimmed as high quality scores across per base sequence quality
  # reads have been trimmed to exclude sequencing library adapters?
    # Trimmed as no adapter content found
    
echo "script step 5: Merging paired end reads"
# Merging paired end reads
## mkdir MedBioinfo/data/merged_pairs
## singularity exec meta.sif flash -h
  # test with
#singularity exec meta.sif flash -z -t 2 -o MedBioinfo/data/merged_pairs/ERR6913239.flash MedBioinfo/data/sra_fastq/ERR6913239_1.fastq.gz MedBioinfo/data/sra_fastq/ERR6913239_2.fastq.gz 2>&1 | tee -a MedBioinfo/data/analyses/x_vaish_flash2.log 
#what proportion of your reads were merged successfully ?
  # 88.64% percent combined
#use seqkit stat to check out the range of merged read lengths
  # singularity exec meta.sif seqkit stats MedBioinfo/data/merged_pairs/ERR6913239.flash.extendedFrags.fastq.gz
  # merged read lengths are 
    # format  type   num_seqs      sum_len  min_len  avg_len  max_len
    # FASTQ   DNA   1,039,867  159,816,258       35    153.7      292
#check out the .histogram file : what does this suggest concerning the length of the DNA library insert sizes ?
  # /MedBioinfo/data/merged_pairs/ERR6913239.flash.histogram
  # template length of 114 saw largest template count of 11054
srun --cpus-per-task=2 --time=00:30:00 --account=naiss2024-22-540 singularity exec meta.sif xargs -I{} -a MedBioinfo/analyses/x_vaish_run_accessions.txt flash -z -t 2 -o MedBioinfo/data/merged_pairs/{}.flash MedBioinfo/data/sra_fastq/{}_1.fastq.gz MedBioinfo/data/sra_fastq/{}_2.fastq.gz 2>&1 | tee -a MedBioinfo/analyses/x_vaish_flash2.log 
# compare how many base pairs you had in your initial unmerged reads, versus how many you have left after merging: 
  # have you lost information, or was it redundant information?
# initially, at least 1,000,000 base pairs in unmerged reads and at least still around 600,00 pairs left after
  # lost some information
  
echo "script step 6: Use read mapping to check for PhiX contamination (and more...)"
# Use read mapping to check for PhiX contamination (and more...)
## mkdir MedBioinfo/data/reference_seqs
singularity exec meta.sif efetch -db nuccore -id NC_001422 -format fasta > MedBioinfo/data/reference_seqs/PhiX_NC_001422.fna
#to check the head of the output file to verify that the sequence NC_001422 corresponds to what we need
## nano MedBioinfo/data/reference_seqs/PhiX_NC_001422.fna 
## mkdir MedBioinfo/data/bowtie2_DBs
srun --account=naiss2024-22-540 singularity exec meta.sif bowtie2-build -f MedBioinfo/data/reference_seqs/PhiX_NC_001422.fna MedBioinfo/data/bowtie2_DBs/PhiX_bowtie2_DB
# check what output index files have been created in
  # created 4 forward bt2 indexes
  # created 2 reverse bt2 indexes
## mkdir MedBioinfo/analyses/bowtie
## singularity exec meta.sif bowtie2 -h
srun --cpus-per-task=8 --account=naiss2024-22-540 singularity exec meta.sif bowtie2 --threads 8 -x MedBioinfo/data/bowtie2_DBs/PhiX_bowtie2_DB -U MedBioinfo/data/merged_pairs/ERR*.extendedFrags.fastq.gz -S MedBioinfo/analyses/bowtie/x_vaish_merged2PhiX.sam --no-unal 2>&1 | tee MedBioinfo/analyses/bowtie/x_vaish_bowtie_merged2PhiX.log
## do you observe any hits against PhiX? If so, have a look at the first few lines of the SAM output file and see if you can reconcile with the SAM format specification
  # 100% unpaired, no hits
# SARS COV 2
## align merged reads to PhiX but this time against the reference SAR-CoV-2 genome which accession number is NC_045512.
singularity exec meta.sif efetch -db nuccore -id NC_045512 -format fasta > MedBioinfo/data/reference_seqs/SC2_NC_045512.fna
## make the bowtie2-build reference DB for SC2
srun --account=naiss2024-22-540 singularity exec meta.sif bowtie2-build -f MedBioinfo/data/reference_seqs/SC2_NC_045512.fna MedBioinfo/data/bowtie2_DBs/SC2_DB
## align
srun --cpus-per-task=8 --account=naiss2024-22-540 singularity exec meta.sif bowtie2 --threads 8 -x MedBioinfo/data/bowtie2_DBs/SC2_DB -U MedBioinfo/data/merged_pairs/ERR*.extendedFrags.fastq.gz -S MedBioinfo/analyses/bowtie/x_vaish_merged2SC2.sam --no-unal 2>&1 | tee MedBioinfo/analyses/bowtie/x_vaish_bowtie_merged2SC2.log
# 776 aligned exactly 1 time
# nano MedBioinfo/analyses/bowtie/x_vaish_merged2SC2.sam
  # ERR6913220
  # ERR6913239

echo "script step 7: Combine quality control results into one unique report for all samples analysed"
# Combine quality control results into one unique report for all samples analysed
# singularity exec meta.sif multiqc -h
srun --account=naiss2024-22-540 singularity exec meta.sif multiqc --force --title "x_vaish sample sub-set" MedBioinfo/data/merged_pairs/ MedBioinfo/analyses/fastqc/ MedBioinfo/analyses/x_vaish_flash2.log MedBioinfo/analyses/bowtie/
## scp -r x_vaish@tetralith.nsc.liu.se:~/x_vaish-sample-sub-set_multiqc_report.html ~/

echo "script end."
