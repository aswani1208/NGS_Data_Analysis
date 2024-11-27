

# install SRA tool kit to download the data

sudo apt-get install sra-toolkit

# configure SRA toolkit to save in current directory

vdb-config -i

### Note: Select tools option using tab and choose current directory to save files (up and down key)

or

# Download the file for ubuntu system

wget --output-document sratoolkit.tar.gz https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/3.1.1/sratoolkit.3.1.1-ubuntu64.tar.gz

# Unzip the archive

tar -vxzf sratoolkit.tar.gz

# Modify your .bashrc file

export PATH=$PATH:$PWD/sratoolkit/bin

# Verify that the binaries will be found by the shell

which fastq-dump

### Output : /Users/JoeUser/sratoolkit.3.0.0-mac64/bin/fastq-dump



# downloading data
# select an accession id from sra
# example SRR21019393	
# gather data using prefetch (WGS Homo sapiens)

mkdir sra_data
cd sra_data
prefetch SRR21019393  

# generate reads from pre-fetched download

fastq-dump --split-files --gzip \
    -X 10000 SRR21019393/SRR21019393.sra

### --split-files will split the paired data as two files
### --gzip will compress the file
### -x 10000 will include only the first 10000 reads

# READ QC using FASTQC
# install FASTQC


wget -P /workspace/NGS_Data_Analysis https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.12.1.zip

# Unzip the archive

unzip /workspace/NGS_Data_Analysis/fastqc_v0.12.1.zip

# Run fastQC

/workspace/NGS_Data_Analysis/FastQC/fastqc SRR21019393_1.fastq.gz SRR21019393_2.fastq.gz

### html files will be created for both the Read 1 and Read 2 data.It can be opened and viewed in any browsers.

# Read Trimming - Trimmomatic, fastp, cutadapt to remove adapters
# Install fastp

wget -P /workspace/NGS_Data_Analysis http://opengene.org/fastp/fastp
## wget http://opengene.org/fastp/fastp --no-check-certificate

chmod a+x /workspace/NGS_Data_Analysis/fastp

# trimming reads

/workspace/NGS_Data_Analysis/fastp -i SRR21019393_1.fastq.gz -I SRR21019393_2.fastq.gz \
     -o SRR21019393_1_trimmed.fastq.gz -O SRR21019393_2_trimmed.fastq.gz