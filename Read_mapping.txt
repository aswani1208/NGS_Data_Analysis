
### Download reference genome and perform read mapping ###

mkdir reference_genome
cd reference_genome

# ref genome data
# go to UCSC genome browser and download genome by chromosome

# Download chromosome 1 genome

wget https://hgdownload.soe.ucsc.edu/goldenPath/hg38/chromosomes/chr1.fa.gz
gunzip chr1.fa.gz

# install bwa
cd ..
git clone https://github.com/lh3/bwa.git
cd bwa
make

# Build index

cd ..
cd reference_genome
/workspace/NGS_Data_Analysis/bwa/bwa index chr1.fa

# mapping the reads

mkdir read_mapping

/workspace/NGS_Data_Analysis/bwa/bwa mem -t 5  \
    reference_genome/chr1.fa sra_data/SRR21019393_1_trimmed.fastq.gz sra_data/SRR21019393_2_trimmed.fastq.gz \
    > read_mapping/sample1.sam
