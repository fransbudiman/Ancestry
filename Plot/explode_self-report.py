# This python script is used to explode the self-reported ancestry data from a CSV file.
# Entry with multiple self-reported ancestries are exploded into multiple rows.
# The exploded data is then saved into a new CSV file.

import pandas as pd

filepath = "C:\\UNIFRANS\\Work\\JLE\\temp\\GENCOV_HM_RES.csv"

df= pd.read_csv(filepath, engine='python')
filename = filepath.split("\\")[-1]

for entry in df["Self-reported_Ancestry"]:
    entry = str(entry)
    if ";" in entry:
        print(f"{entry} contains multiple self-reported ancestries, store as a list")
        list = entry.split(";")
        print(list)
        df["Self-reported_Ancestry"] = df["Self-reported_Ancestry"].apply(lambda x: str(x).split(";") if ";" in str(x) else [x])

resultpath = filepath.replace(filename, f"exploded_{filename}")
df.to_csv(resultpath, index=False)