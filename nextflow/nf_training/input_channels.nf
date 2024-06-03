// usage: nextflow run input_channels.nf
// https://www.nextflow.io/docs/latest/channel.html

// The channel.of method allows you to create a channel that emits the arguments provided to it, for example:
ch = Channel.of(1..5, 18, 'X', 'Y')
//ch.view() // produces 1,2,3,4,5 from 1..5, produces 18, produces, produces Y

// The channel.fromList method allows you to create a channel emitting the values provided as a list of elements:
channel
    .fromList( ['a', 'b', 'c', 'd'] )
//   .view { "value: $it" } // value:a, value:b, value:c, value:d


// You can create a channel emitting one or more file paths by using the channel.fromPath method and specifying a path string as an argument:
myFileChannel = channel.fromPath( './*.nf')	
// myFileChannel.view() // list all files in current directory that end with .nf

 myFileChannel = channel.fromPath( './*.nf' , checkIfExists: true )	
// myFileChannel.view() // list all files in current directory that end with .nf; same as above

//myFileChannel = channel.fromPath( './*.txt' , checkIfExists: true )	
//myFileChannel.view() // ERROR ~ No files match pattern `*.txt` at path: ./

// The channel.fromFilePairs method creates a channel emitting the file pairs matching a glob pattern provided by the user. The matching files are emitted as tuples in which the first element is the grouping key of the matching pair and the second element is the list of files (sorted in lexicographical order):
channel
    .fromFilePairs('/proj/applied_bioinformatics/users/x_vaish/MedBioinfo/data/sra_fastq/ERR*_{1,2}.fastq*')
//  .view() 
// [ID, [linktofastq1, linktofastq2]]
// [ERR6913235, [/proj/applied_bioinformatics/users/x_vaish/MedBioinfo/data/sra_fastq/ERR6913235_1.fastq.gz, /proj/applied_bioinformatics/users/x_vaish/MedBioinfo/data/sra_fastq/ERR6913235_2.fastq.gz]]

// The channel.fromSRA method queries the NCBI SRA database and returns a channel emitting the FASTQ files matching the specified criteria i.e project or accession number(s).
ids = ['ERR908507', 'ERR908506']
channel
    .fromSRA(ids)
//   .view() 
// [ID, [linktofastq1, linktofastq2]]
//[ERR908507, [/vol1/fastq/ERR908/ERR908507/ERR908507_1.fastq.gz, /vol1/fastq/ERR908/ERR908507/ERR908507_2.fastq.gz]]
//[ERR908506, [/vol1/fastq/ERR908/ERR908506/ERR908506_1.fastq.gz, /vol1/fastq/ERR908/ERR908506/ERR908506_2.fastq.gz]]


