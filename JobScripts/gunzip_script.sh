#!/bin/bash
#SBATCH --job-name=gunzip_vcf          # Job name
#SBATCH --output=gunzip_vcf_output_%j.txt  # Output file for the job
#SBATCH --ntasks=1                     # Number of tasks
#SBATCH --cpus-per-task=40              # Number of CPU cores per task
#SBATCH --time=10:00:00                # Max time for job (adjust as needed)

# Set the directory where your VCF files are stored
BASE_DIR="/scratch/j/jle/frans/gencov"

# Find all .vcf.gz files in the BASE_DIR and its subdirectories, excluding .tbi files
find "$BASE_DIR" -type f -name "*.vcf.gz" | while read -r dataFile; do
    # Check if it's a .vcf.gz file and not a .tbi file
    if [[ "$dataFile" == *.vcf.gz && ! "$dataFile" =~ \.tbi$ ]]; then
        # Unzip the .vcf.gz file, creating the .vcf file in the same directory
        echo "Unzipping: $dataFile"
        gunzip "$dataFile"  # This will replace the .vcf.gz with the .vcf file in the same directory
    fi
done
