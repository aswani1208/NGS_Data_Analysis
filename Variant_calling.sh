# Variant Identification using GATK

# DATA ACCESS 

# BAM files from GATK example data
# Retrieve reference genome at gatk resource bundle

wget -p reference_genome/ https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta
wget -p reference_genome/ https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.dict

# index the reference genome
samtools faidx reference_genome/Homo_sapiens_assembly38.fasta

#Known variants
wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/hapmap_3.3.hg38.vcf.gz
gatk IndexFeatureFile -I hapmap_3.3.hg38.vcf.gz


# SOMATIC VARIANT DISCOVERY #

Steps:
1. Mutect2 - to call variants, identify SNPs and Indels
2. get pileup summaries
3. calculate contamination
4. filter mutect calls

# index the BQSR file; using another file for demo here
samtools index read_mapping/merged_bqsr.bam

mkdir somatic_variants
# Mutect2 -  identify SNPs and Indels

gatk Mutect2 -I read_mapping/merged_bqsr.bam \
     -R reference_genome/Homo_sapiens_assembly38.fasta \
     -O variant_calling/somatic_variants/somatic_variants.vcf.gz

# get pile ups - Get summaries and Calculate the contamination

gatk GetPileupSummaries -I read_mapping/merged_bqsr.bam \
   -V variant_calling/somatic_variants/hapmap_3.3.hg38.vcf.gz \
   -L variant_calling/somatic_variants/hapmap_3.3.hg38.vcf.gz \
   -O variant_calling/somatic_variants/sample_pileups.table

# calculate contamination
gatk CalculateContamination -I variant_calling/somatic_variants/sample_pileups.table -O variant_calling/somatic_variants/sample_contamination.table

# filter variants - filter and keep only high quality variants

gatk FilterMutectCalls \
   -R reference_genome/Homo_sapiens_assembly38.fasta \
   -V variant_calling/somatic_variants/somatic_variants.vcf.gz \
   --contamination-table variant_calling/somatic_variants/sample_contamination.table \
   -O variant_calling/somatic_variants/filtered.vcf.gz

# Select specific variants
## SNPs

gatk SelectVariants \
    -R reference_genome/Homo_sapiens_assembly38.fasta \
    -V variant_calling/somatic_variants/filtered.vcf.gz \
    --select-type-to-include SNP \
    -O variant_calling/somatic_variants/filtered_snps.vcf

## Indels

gatk SelectVariants \
    -R reference_genome/Homo_sapiens_assembly38.fasta \
    -V variant_calling/somatic_variants/filtered.vcf.gz \
    --select-type-to-include INDEL \
    -O variant_calling/somatic_variants/filtered_indels.vcf

# Reading VCF files

bcftools view variant_calling/somatic_variants/filtered_snps.vcf
bcftools view variant_calling/somatic_variants/filtered_indels.vcf

# GERMLINE VARIANT DISCOVERY #
Steps:
1. haplotype caller - GVCFs is generated
2. combine GVCFs
3. VQSR/hard filtering based on number of samples and resources
4. collecting metrics if using hard filtering

mkdir germline_variants

# haplotype calling
samtools index read_mapping/tumor.bam

gatk HaplotypeCaller  \
   -R reference_genome/Homo_sapiens_assembly38.fasta \
   -I read_mapping/tumor.bam \
   -O variant_calling/germline_variants/tumor.g.vcf.gz \
   -ERC GVCF

samtools index read_mapping/normal.bam

gatk HaplotypeCaller  \
   -R reference_genome/Homo_sapiens_assembly38.fasta \
   -I read_mapping/normal.bam \
   -O variant_calling/germline_variants/normal.g.vcf.gz \
   -ERC GVCF

# Combine GVCFs (old version only)
gatk CombineGVCFs \
   -R reference_genome/Homo_sapiens_assembly38.fasta \
   --variant variant_calling/germline_variants/normal.g.vcf.gz \
   --variant variant_calling/germline_variants/tumor.g.vcf.gz \
   -O variant_calling/germline_variants/cohort.g.vcf.gz

gatk  GenotypeGVCFs \
   -R reference_genome/Homo_sapiens_assembly38.fasta \
   -V variant_calling/germline_variants/cohort.g.vcf.gz \
   -O variant_calling/germline_variants/germline_variants.vcf.gz

# hard filtering on snps
gatk SelectVariants \
    -V variant_calling/germline_variants/germline_variants.vcf.gz \
    -select-type SNP \
    -O variant_calling/germline_variants/germline_snps.vcf.gz

gatk VariantFiltration \
    -V variant_calling/germline_variants/germline_snps.vcf.gz \
    -filter "QD < 2.0" --filter-name "QD2" \
    -filter "QUAL < 30.0" --filter-name "QUAL30" \
    -filter "SOR > 3.0" --filter-name "SOR3" \
    -filter "FS > 60.0" --filter-name "FS60" \
    -filter "MQ < 40.0" --filter-name "MQ40" \
    -filter "MQRankSum < -12.5" --filter-name "MQRankSum-12.5" \
    -filter "ReadPosRankSum < -8.0" --filter-name "ReadPosRankSum-8" \
    -O variant_calling/germline_variants/snps_filtered.vcf.gz

gatk CollectVariantCallingMetrics \
    -I variant_calling/germline_variants/snps_filtered.vcf.gz \
    --DBSNP read_mapping/Homo_sapiens_assembly38.dbsnp138.vcf \
    -SD reference_genome/Homo_sapiens_assembly38.dict \
    -O variant_calling/germline_variants/germline_snps_metrics

# hard filtering on Indels

gatk SelectVariants \
    -V variant_calling/germline_variants/germline_variants.vcf.gz \
    -select-type INDEL \
    -O variant_calling/germline_variants/germline_indel.vcf.gz

gatk VariantFiltration \
    -V variant_calling/germline_variants/germline_indel.vcf.gz \
    -filter "QD < 2.0" --filter-name "QD2" \
    -filter "QUAL < 30.0" --filter-name "QUAL30" \
    -filter "FS > 200.0" --filter-name "FS200" \
    -filter "ReadPosRankSum < -20.0" --filter-name "ReadPosRankSum-20" \ 
    -O variant_calling/germline_variants/indel_filtered.vcf.gz

gatk CollectVariantCallingMetrics \
    -I variant_calling/germline_variants/indel_filtered.vcf.gz \
    --DBSNP read_mapping/Homo_sapiens_assembly38.dbsnp138.vcf \
    -SD reference_genome/Homo_sapiens_assembly38.dict \
    -O variant_calling/germline_variants/germline_indel_metrics
