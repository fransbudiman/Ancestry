#!/bin/bash

# Enable debugging
set -x

# Set arguments
# o = original directory
# r = result directory
while getopts ":o:r:" flag
do
    case "${flag}" in
        o) ORIGINAL_DIR=${OPTARG};;
        r) RESULT_DIR=${OPTARG};;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
        :)  echo "Missing argument for -$OPTARG" >&2; exit 1 ;;
    esac
done

# check if directory exists
if [ ! -d "$ORIGINAL_DIR" ]; then
    echo "Original directory does not exist."
    exit 1
fi
if [ ! -d "$RESULT_DIR" ]; then
    echo "Result directory does not exist."
    exit 1
fi

find "$ORIGINAL_DIR" -mindepth 1 -maxdepth 1 -type d | awk -F/ '{print $NF}'> "$RESULT_DIR/all_samples_temp.txt"
find "$RESULT_DIR" -type f -name '*_ancestry.txt' | awk -F/ '{print $NF}' | sed 's/_ancestry.txt//' > "$RESULT_DIR/completed_samples_temp.txt"


# Compare the two files and find missing samples
comm -23 <(sort $RESULT_DIR/all_samples_temp.txt) <(sort $RESULT_DIR/completed_samples_temp.txt) > $RESULT_DIR/missing_samples.txt
rm $RESULT_DIR/*_temp.txt

# cat $RESULT_DIR/missing_samples.txt

mkdir -p $RESULT_DIR/missing_samples
while read sample; do
    vcf_path=$(find $ORIGINAL_DIR -type f -name "$sample*.vcf")
    if [ -n $vcf_path]; then
        ln -s $vcf_path $RESULT_DIR/missing_samples/
    else
        echo "No VCF file found for sample $sample"
    fi
done < $RESULT_DIR/missing_samples.txt




