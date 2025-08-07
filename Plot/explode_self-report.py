# This python script is used to explode the self-reported ancestry data from a CSV file.
# Entry with multiple self-reported ancestries are exploded into multiple rows.
# The exploded data is then saved into a new CSV file.

import pandas as pd
import argparse

filepath = "C:\\UNIFRANS\\Work\\JLE\\temp\\GENCOV_HM_RES.csv"

parser = argparse.ArgumentParser()
parser.add_argument('-f', '--file', default=filepath, help='Path to the CSV file containing the data')
args = parser.parse_args()
filepath = args.file

df= pd.read_csv(filepath, engine='python')
filename = filepath.split("\\")[-1]

for entry in df["Self-reported_Ancestry"]:
    entry = str(entry)
    if ";" in entry:
        print(f"{entry} contains multiple self-reported ancestries, store as a list")
        list = entry.split(";")
        print(list)
        df["Self-reported_Ancestry"] = df["Self-reported_Ancestry"].apply(lambda x: str(x).split(";") if ";" in str(x) else [x])

df = df.explode("Self-reported_Ancestry")
df["Self-reported_Ancestry"]= df["Self-reported_Ancestry"].astype("str").str.strip()
resultpath = filepath.replace(filename, f"exploded_{filename}")
df.to_csv(resultpath, index=False)