#!/bin/bash

# This script is will loop through the given directory,
# find the .gz vcf files, unzips them and then runs the submit_job.sh script
# to submit the job to the cluster

#Default values
JOBNAME="default_batch_job"
OUTPUT="default_batch_job%j.out"
NTASKS=1
TIME="48:00:00"
CPU=40
THREADS=40

# Parse command-line arguments
# DIR has to be the full path to the directory
# REF has to be the reference dataset type (hapmap, 1kgenomes, grafpop)
# CONFIG has to be the path to the configuration directory
while getopts "r:d:c:t:" opt; do
  case $opt in
    r) REF=$OPTARG ;;
    d) DIR=$OPTARG ;;
    c) CPU=$OPTARG ;;
    t) THREADS=$OPTARG ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
  esac
done

# Ensure both reference and directory are set before using them
if [ -z "$REF" ]; then
  echo "Error: Reference dataset (-r) is required."
  exit 1
fi

if [ -z "$DIR" ]; then
  echo "Error: Directory (-d) is required."
  exit 1
fi

JOBNAME="${REF}_batch_job"
OUTPUT="/scratch/j/jle/frans/${REF}_batch_job_%j.out"

# Ensure the directory exists
if [ ! -d "$DIR" ]; then
  echo "Error: Directory $DIR does not exist."
  exit 1
fi

echo "Debugging: $DIR and $OUTPUT"
# Loop through the directory
find -L "$DIR" -type f \( -name "*.vcf" -o -name "*.vcf.gz" \) | while read -r dataFile; do
    # Unzip the file if it hasn't been unzipped
    if [ ! -f "${dataFile%.gz}" ]; then
        echo "Unzipping: $dataFile"
        gunzip "$dataFile"
        dataFile=${dataFile%.gz}
    fi
    # Get the vcf file name and path
    VCF=$(basename "$dataFile" .vcf.gz | sed 's/.vcf$//')
    VCF_PATH=${dataFile%.gz}

    # Debugging prints
    echo "VCF: $VCF"
    echo "VCF_PATH: $VCF_PATH"

    # Submit the job by running the submit_job.sh script
    bash submit_job.sh -j $JOBNAME -o $OUTPUT -n $NTASKS -c $CPU -r $REF -a "-i ${VCF} -v ${VCF_PATH} -o ${PWD}/Result -c ${THREADS}"
done
