#!/bin/bash

# this script is used to change the vcf names of the samples to be the study ID.
# It will require 2 files:
# 1. normalized_mapping.txt : merged text file from the shared directory
# 2. mapping_tcagid_studyid.txt : taken from the csv file. it contains TCAGID and Study ID

# File 2 will only be used if file 1 fails to map the sample.
# This is because Group0 samples from the shared directory does not have the group0.txt file.

while getopts "m:s:o:" opt; do
  case $opt in
    m) MAPPING_DIR=$OPTARG ;;
    s) SAMPLE_DIR=$OPTARG ;;
    o) OUTDIR=$OPTARG ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
  esac
done

if [ !-d "$MAPPING_DIR" ]; then
  echo "Error: $MAPPING_DIR does not exist."
  exit 1
fi
if [ ! -d "$SAMPLE_DIR" ]; then
  echo "Error: $SAMPLE_DIR does not exist."
  exit 1
fi

mkdir -p $OUTDIR
touch $OUTDIR/missing.txt

# Loops through samples in sample directory
for sample in $(find "$SAMPLE_DIR" -type f -name "*.vcf.gz"); do
    # trim the sample name
    sample_file=$(basename "$sample")
    sample_name=${sample_file%-gatk-haplotype.final.vcf.gz}
    echo "Processing sample: $sample_name"
    # Check if the sample name exists in the mapping file
    study_id=$(awk -v name="$sample_name" -F'\t' '
    {
        for (i=1; i<=NF; i++) {
            if ($i ~ name) {
                print $NF;
                exit;
            }
        }
    }' $MAPPING_DIR/normalized_mapping.txt)

    echo "Study ID found: $study_id"
    
    # if study_id is empty, try to find it in the mapping_tcagid_studyid.txt file
    if [ -z "$study_id" ]; then
        echo "Study ID not found in normalized_mapping.txt, trying mapping_tcagid_studyid.txt"
        id_no=$(echo "$sample_name" | cut -d'_' -f2)
        study_id=$(awk -v id="$id_no" -F'\t' '
        {
            if ($NF ~ id) {
                print $1;
                exit;
            }
        }' $MAPPING_DIR/mapping_tcagid_studyid.txt)

    fi

    if [ -z "$study_id" ]; then
        echo "No study ID found for sample: $sample_name"
        echo "$sample_name" >> $OUTDIR/missing.txt
        continue
    fi

    echo "Renaming sample: $sample_name to $study_id"
    # Rename the sample
    cp "$sample" "${OUTDIR}/${study_id}.vcf.gz"

done