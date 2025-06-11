#!/bin/bash

while getopts ":c:o:" flag
do
    case "${flag}" in
        c) CSV_FILE=${OPTARG};;
        o) OUTPUT_FILE=${OPTARG};;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
        :)  echo "Missing argument for -$OPTARG" >&2; exit 1 ;;
    esac
done

awk -F',' '
BEGIN { OFS = " " }
NR > 1 {
    id = $1
    self_reported = $14
    inferred = $19

    # Skip if either is missing
    if (self_reported == "" || inferred == "") {
        next
    }

    # Print if they are mismatched
    if (self_reported != inferred) {
        print id, self_reported, inferred
    }
}
' "$CSV_FILE" > "$OUTPUT_FILE"

echo "Done. Mismatches saved to $OUTPUT_FILE"
