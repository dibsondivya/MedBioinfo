#! /usr/bin/env nextflow

workflow{
	ch_input = Channel.fromFilePairs(params.input_read_pairs, checkIfExists: true )	// separates path from ID naturally given the FilePairs
	// above line stores (file id, file path) as a tuple

	// quality control
	FASTQC ( ch_input ) // input is (file id, file path)
	
	// flash for merging read pairs
    FLASH2 ( ch_input )

	// read mapping to database
    BOWTIE2 ( Channel.fromPath(params.bowtie2_db, checkIfExists: true).toList(), // check that required db is there and list it
        FLASH2.out.merged_reads ) // also pipe in the output of merged_reads from FLASH2

	KRAKEN2 ( Channel.fromPath(params.kraken2_db, checkIfExists: true).toList(), 
        ch_input)

    BRACKEN ( Channel.fromPath(params.kraken2_db, checkIfExists: true).toList(), 
        KRAKEN2.out.kraken2_report,
        ch_input)

    KRAKENTOOLS ( KRAKEN2.out.kraken2_report,
        ch_input)
	
	CLEANKRONA ( KRAKENTOOLS.out.kronareport,
		ch_input )

	KRONA ( CLEANKRONA.out.krona_cleaned,
        ch_input)

	// assembling reports
	MULTIQC ( FASTQC.out.qc_zip.collect(), FLASH2.out.flash2_log.collect(), BOWTIE2.out.bowtie2_logs.collect(), KRAKEN2.out.kraken2_report.collect(), BRACKEN.out.bracken_output.collect() )

	PREPBRACKEN ( BRACKEN.out.bracken_output, ch_input )
	
	COMPILEKRONA ( CLEANKRONA.out.krona_cleaned.collect() )
}


// Publish directories are numbered to help understand processing order
// all variables named params.name are listed in params.yml

// fast quality control of fastq files
process FASTQC {

	input:
	tuple val(id), path(reads)

	// directives
	container 'https://depot.galaxyproject.org/singularity/fastqc:0.11.9--hdfd78af_1' // defined as such due to abilty to use singularity
	publishDir "$params.outdir/01_fastqc" // outdir defined in params.yml file

	script: 
	"""

	fastqc \\
	    --noextract \\
	    $reads

	"""

	output:
	path "${id}*fastqc.html", 	emit: qc_html
	path "${id}*fastqc.zip", 	emit: qc_zip

}


process MULTIQC {

	input: 
	path(fastqc_zips) 
	path(flash2_log) 
	path(bowtie2_logs) 
	path(kracken_report)
	path(bracken_output)

	// directives
	container 'https://depot.galaxyproject.org/singularity/multiqc:1.9--pyh9f0ad1d_0'
	publishDir "$params.outdir/09_multiqc"

	script: 
	"""
	multiqc \\
    	    --force \\
    	    --title "metagenomics" \\
		.
	"""

	output: 
	path "*"
}

process FLASH2 { // runs in parallel, per input tuple
    input:
    tuple val(id), path(reads)

    // directives
    container 'https://depot.galaxyproject.org/singularity/flash:1.2.11--h5bf99c6_6'
    publishDir "$params.outdir/02_flash2" 

    script:
	 // dont need to include threads since it is handled by nextflow
    """

    flash  \\
        $reads \\
        -o "${id}.flash2" \\
        -M 150 \\
        | tee -a ${id}_flash2.log

    """

    output:
    tuple val(id), path("${id}.flash2.extendedFrags.fastq"), emit: merged_reads // path is stored as also required for the next multiqc step
    path "${id}.flash2.notCombined*.fastq", emit: notCombined_fastq
    path "${id}.flash2.hist", emit: flash2_hist
    path "${id}.flash2.histogram", emit: flash2_histogram
    path "${id}_flash2.log", 	emit: flash2_log

}
process BOWTIE2 {
    input:
    path(bowtie2_db)
    tuple val (id), path(merged_reads)
   
    // directives
    container 'https://depot.galaxyproject.org/singularity/mulled-v2-ac74a7f02cebcfcc07d8e8d1d750af9c83b4d45a:f70b31a2db15c023d641c32f433fb02cd04df5a6-0'
    publishDir "$params.outdir/03_bowtie2"

    script:
	// remove ".rev.1.bt2" extension from end of file
	db_name = bowtie2_db.find{it.name.endsWith(".rev.1.bt2")}.name.minus(".rev.1.bt2")
    """

    bowtie2 \\
        -x $db_name \\
        -U $merged_reads \\
        -S ${id}_bowtie2_merged_${db_name}.sam \\
        --no-unal 2>&1 \\
        | tee -a ${id}_bowtie2_merged_${db_name}.log
     
    """

    output:
    path "${id}_bowtie2_merged_${db_name}.sam", emit: aligned_reads
    path "${id}_bowtie2_merged_${db_name}.log", emit: bowtie2_logs
}

process KRAKEN2 {

	input: 
	path(kraken2_db)
	tuple val(id), path(reads)

	// directives:
	container 'https://depot.galaxyproject.org/singularity/mulled-v2-8706a1dd73c6cc426e12dd4dd33a5e917b3989ae:c8cbdc8ff4101e6745f8ede6eb5261ef98bdaff4-0'
	publishDir "$params.outdir/04_kraken2"

	script:
	"""

    kraken2 \\
        --db $kraken2_db \\
        --gzip-compressed \\
        --output ${id}_kraken2.output \\
        --report ${id}_kraken2.report \\
        --paired $reads

	"""

	output:
	path "${id}_kraken2.output", emit: kraken2_output
	path "${id}_kraken2.report", emit: kraken2_report
	
}

process BRACKEN {

	input: 
	path(kraken2_db)
    path(kraken_report)
	tuple val(id), path(reads)

	// directives:
	container 'https://depot.galaxyproject.org/singularity/bracken:2.9--py38h2494328_0'
	publishDir "$params.outdir/05_bracken"

	script:
	"""

    bracken \\
        -d $kraken2_db \\
        -i $kraken_report \\
        -o ${id}_bracken.output \\
        -w ${id}_bracken.report

	"""

	output:
	path "${id}_bracken.output", emit: bracken_output
	path "${id}_bracken.report", emit: bracken_report
	
}

process KRAKENTOOLS {

	input: 
    path(kraken_report)
	tuple val(id), path(reads)

	// directives:
	container 'https://depot.galaxyproject.org/singularity/krakentools:1.2--pyh5e36f6f_0'
	publishDir "$params.outdir/07_krakentools"

	script:
	"""

    kreport2krona.py \\
        -r $kraken_report \\
        -o ${id}.krona \\

	"""

	output:
	path "${id}.krona", emit: kronareport
	
}

process CLEANKRONA {
	input: 
    path(kronareport)
	tuple val(id), path(reads)


	container 'https://depot.galaxyproject.org/singularity/krakentools:1.2--pyh5e36f6f_0'
	publishDir "$params.outdir/07_krakentools"

	script:
	"""
	sed -E 's/[a-z]__//g' $kronareport > ${id}.krona
	"""

	output:
	path "${id}.krona", emit: krona_cleaned
}

process KRONA {

	input: 
    path(kronareport)
	tuple val(id), path(reads)

	// directives:
	container 'https://depot.galaxyproject.org/singularity/krona:2.8.1--pl5321hdfd78af_1'
	publishDir "$params.outdir/08_krona"

	script:
	"""
    ktImportText \\
        $kronareport \\
        -o ${id}.krona.html

	"""

	output:
	path "${id}.krona.html", emit: krona_html
	
}

process COMPILEKRONA {

	input: 
    path(kronareport)

	// directives:
	container 'https://depot.galaxyproject.org/singularity/krona:2.8.1--pl5321hdfd78af_1'
	publishDir "$params.outdir/10_compiledkrona"

	script:
	"""
    ktImportText \\
        $kronareport \\
        -o combined.krona.html

	"""

	output:
	path "combined.krona.html", emit: combined_krona_html
	
}

process PREPBRACKEN{
	input: 
    path(bracken_output)
	tuple val(id), path(reads)

	// directives:
	container 'https://depot.galaxyproject.org/singularity/gawk:5.3.0'
	publishDir "$params.outdir/06_prepbracken"

	script:
	"""
	awk 'BEGIN {FS=OFS="\t"}{\$0 = \$0 OFS (NR == 1 ? "sample_id" : "${id}")} 1' ${bracken_output} | awk 'NR>1' > ${id}_sortedbrackenreport.txt;
	cat ${id}_sortedbrackenreport.txt > sortedbrackenreport.txt	
	"""

	output:
	path "${id}_sortedbrackenreport.txt", emit: indiv_modified_bracken_report
	path "sortedbrackenreport.txt", emit: modified_bracken_report

}