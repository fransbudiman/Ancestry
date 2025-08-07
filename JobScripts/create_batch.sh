#!/bin/bash

# this script will create a directory and copy the files from the list outputted by random_select.py

set -x

while getopts ":d:c:s:" flag
do
    case "${flag}" in
        d) DIRECTORY=${OPTARG};;
        c) CSV=${OPTARG};;
        s) SOURCE_DIR=${OPTARG};;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
        :)  echo "Missing argument for -$OPTARG" >&2; exit 1 ;;
    esac
done

mkdir -p "$DIRECTORY"
if [ ! -f "$CSV" ]; then
    echo "CSV file does not exist: $CSV"
    exit 1
fi

studyid_col_idx=$(head -n 1 "$CSV" | tr ',' '\n' | grep -n "Study_ID+N1Q1A1:R1" | cut -d: -f1)
tcagid_col_idx=$(head -n 1 "$CSV" | tr ',' '\n' | grep -n "TCAG_ID" | cut -d: -f1)

tail -n +2 "$CSV" | cut -d',' -f"$tcagid_col_idx" | while read sample; do
    # Remove any leading or trailing whitespace
    sample=$(echo "$sample" | xargs)
    
    # Find the corresponding file in the source directory
    file=$(find "$SOURCE_DIR" -type f -name "${sample}*.vcf")
    
    if [ -n "$file" ]; then
        ln -sf "$file" "gencov_100random/$(basename "$file")"
        echo "Copied $file to $DIRECTORY/"
    else
        echo "No file found for sample: $sample"
    fi
done

tail -n +2 "$CSV" | cut -d',' -f"$studyid_col_idx" | while read sample; do
    # Remove any leading or trailing whitespace
    sample=$(echo "$sample" | xargs)
    
    # Create a subdirectory for the study ID
    file=$(find "$SOURCE_DIR" -type f -name "$sample*.vcf*")
    
    if [ -n "$file" ]; then
        ln -sf "$file" "gencov_100random/$(basename "$file")"
        echo "Copied $file to $DIRECTORY/"
    else
        echo "No directory found for sample: $sample"
    fi
done





