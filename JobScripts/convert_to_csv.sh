#!/bin/bash

# Default values
TARGET_DIR="."
CSV="ancestry_output.csv"

# Parse command-line arguments
while getopts "d:c:r:" opt; do
  case $opt in
    d) TARGET_DIR=$OPTARG ;;
    c) CSV=$OPTARG ;;
    r) REF=$OPTARG ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
  esac
done

# Check if TARGET_DIR exists
if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: $TARGET_DIR does not exist."
  exit 1
fi

# Check if REF is set
if [ -z "$REF" ]; then
  echo "Error: Reference dataset (-r) is required. (Hapmap, 1KGenomes, GrafPop)"
  exit 1
fi

# Check if CSV file exists
if [ -f "$CSV" ]; then
    echo "CSV file already exists. Are you sure you want to modify the file? (y/n)"
    read next
    if [[ $next != "y" ]]; then
        exit 1
    fi
    echo "Appending to the existing CSV file."
else
    touch $CSV
    # create the header for the csv file
    echo "Sample, Hapmap, Hapmap, Hapmap, 1KGenomes, 1KGenomes, 1KGenomes, GrafPop" > $CSV
fi



# Search for all files that contain a *top3.txt file
for file in $(find $TARGET_DIR -type f -name "*top3.txt")
do
    echo "Processing file: $file"
    # get the name of the file
    FILE_NAME=$(basename $file)
    # get the sample name
    SAMPLE=$(echo $FILE_NAME | cut -d'_' -f1)
    # get the ancestry values
    ANCESTRY=$(awk 'NR==1 {for (i=1; i<=NF; i++) header[i]=$i} NR==2 {for (i=1; i<=NF; i++) printf "%s=%.6f%s", header[i], $i, (i<NF ? ", " : "")}' $file)
    echo "debugging: $ANCESTRY"
    IFS=', ' read -ra ANCESTRY_ARRAY <<< "$ANCESTRY"
    # Search if the sample is already in the csv file
    if ! grep -q "$SAMPLE" "$CSV"; then
        echo "$SAMPLE, -, -, -, -, -, -, -, -, -" >> $CSV
    fi

    # Store sample ancestry value in an array
    row=$(grep -n "$SAMPLE" "$CSV")
    line_number=$(echo $row | cut -d':' -f1)
    IFS=',' read -r -a row_array <<< "$row"
    echo "debugging: ${row_array[*]}"
    
    # Add the ancestry values to the csv file based on the reference dataset
    if [[ $REF == "Hapmap" ]]; then
        row_array[1]=${ANCESTRY_ARRAY[0]}
        row_array[2]=${ANCESTRY_ARRAY[1]}
        row_array[3]=${ANCESTRY_ARRAY[2]}
    elif [[ $REF == "1KGenomes" ]]; then
        row_array[4]=${ANCESTRY_ARRAY[0]}
        row_array[5]=${ANCESTRY_ARRAY[1]}
        row_array[6]=${ANCESTRY_ARRAY[2]}
    elif [[ $REF == "GrafPop" ]]; then
        row_array[7]=${ANCESTRY_ARRAY[0]}
        row_array[8]=${ANCESTRY_ARRAY[1]}
        row_array[9]=${ANCESTRY_ARRAY[2]}
    fi

    # Update the csv file with the new ancestry values
    new_row=$(IFS=,; echo "${row_array[*]}")
    sed -i "${line_number}s/.*/$new_row/" $CSV
    
done
