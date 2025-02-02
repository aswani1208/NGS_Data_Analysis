## Perform some quality check of SAM files ##
## Following GATK best practices

# run the container for GATK-4 & updated docker container to run GATK-4

docker pull broadinstitute/gatk:latest

# Install docker to run the container in interactive mode
# It wil take the data in the current directory and mount it in data directory 

docker run -it -v $PWD:/data/ broadinstitute/gatk:latest

# Create bam file from sam file
cd /data/
cd read_mapping
samtools view -bo sample1.bam sample1.sam

# create another sample SAM file (useful for multi-sample comparison)
# download tumor and normal sample bam files

wget https://storage.googleapis.com/gatk-tutorials/workshop_2002/3-somatic/bams/normal.bam
wget https://storage.googleapis.com/gatk-tutorials/workshop_2002/3-somatic/bams/tumor.bam

# merge the bam files

samtools merge -r -o read_mapping/merged.bam read_mapping/normal.bam read_mapping/tumor.bam 

# index the merged bam file
samtools index merged.bam

# mark duplicates

gatk MarkDuplicates \
I=read_mapping/merged.bam  \ 
O=read_mapping/marked_duplicates.bam  \  
M=read_mapping/marked_dup_metrics.txt 

# sorting the records
gatk SortSam -I read_mapping/marked_duplicates.bam -O read_mapping/merged_sorted.bam -SORT_ORDER coordinate

# View the sorted bam with last few lines
samtools view read_mapping/merged_sorted.bam | tail -n 3

# BQSR
# download the file 
wget https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.dbsnp138.vcf

## Create dictionary for reference genome

wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.dict
gatk CreateSequenceDictionary -R reference_genome/chr1.fa

# Indexing the refrence genome file
gatk IndexFeatureFile --input read_mapping/Homo_sapiens_assembly38.dbsnp138.vcf

# create ref genome index using samtools
samtools faidx reference_genome/chr1.fa

## add read group info if not present already

# extract records from chr1 alone using bed file
samtools view -L reference_genome/bed_file2.bed read_mapping/merged_sorted.bam -o read_mapping/chr1_bamfile.bam


#BQSR
gatk BaseRecalibrator -I read_mapping/chr1_bamfile.bam -R reference_genome/chr1.fa --known-sites read_mapping/Homo_sapiens_assembly38.dbsnp138.vcf -O recal_data.table

# gatk BaseRecalibrator -I read_mapping/merged_sorted.bam -R reference_genome/Homo_sapiens_assembly38.fasta --known-sites read_mapping/Homo_sapiens_assembly38.dbsnp138.vcf -O recal_data.table

gatk ApplyBQSR -R reference_genome/chr1.fa -I read_mapping/chr1_bamfile.bam --bqsr-recal-file recal_data.table -O read_mapping/chr1_bqsr.bam

# gatk ApplyBQSR -R reference_genome/Homo_sapiens_assembly38.fasta -I read_mapping/merged_sorted.bam --bqsr-recal-file recal_data.table -O read_mapping/merged_bqsr_bqsr.bam

# Index bam file
samtools index read_mapping/chr1_bqsr.bam