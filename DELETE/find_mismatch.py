#!/usr/bin/env python3
import csv
import sys
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-c', '--csv_file', required=True, help='Input CSV file')
parser.add_argument('-o', '--output_file', required=True, help='Output mismatch file')
args = parser.parse_args()

with open(args.csv_file, newline='', encoding='utf-8') as infile, \
     open(args.output_file, 'w', encoding='utf-8') as outfile:

    reader = csv.reader(infile)
    header = next(reader)  # skip header

    for row in reader:
        try:
            sample_id = row[0].strip()
            col14 = row[13].strip()
            col19 = row[18].strip()
            col18 = row[17].strip()

            if col14 and col19 and col18 and col14 != col19:
                outfile.write(f"{sample_id} {col14} {col19}\n")
        except IndexError:
            continue  # skip malformed lines

print(f"Done. Mismatches saved to {args.output_file}")
