import pandas as pd
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input', default='your_input_file.csv', help='Path to the input CSV file', required=True)
args = parser.parse_args()
input_file = args.input


# Load the data
df = pd.read_csv(input_file, engine='python')

# Define mappings from population labels to continental groups
grafpop_map = {
    "European": "Europe",
    "East Asian": "East Asia",
    "Latin American 1": "Americas",
    "Latin American 2": "Americas",
    "African American": "Africa",
    "African": "Africa",
    "South Asian": "South Asia",
    "Asian-Pacific Islander": "East Asia / Oceania",
    "Other": "Unassigned / Other"
}

hapmap_map = {
    "YRI": "Africa",
    "LWK": "Africa",
    "MKK": "Africa",
    "ASW": "Africa",
    "CHB": "East Asia",
    "CHD": "East Asia",
    "JPT": "East Asia",
    "GIH": "South Asia",
    "CEU": "Europe",
    "TSI": "Europe",
    "MEX": "Americas"  # Note: If you're using 1000G labels this becomes "MXL"
}

okg_map = {
    "CHB": "East Asia",
    "CHS": "East Asia",
    "CHD": "East Asia",
    "CDX": "East Asia",
    "JPT": "East Asia",
    "KHV": "East Asia",
    "GIH": "South Asia",
    "PJL": "South Asia",
    "BEB": "South Asia",
    "STU": "South Asia",
    "ITU": "South Asia",
    "CEU": "Europe",
    "TSI": "Europe",
    "GBR": "Europe",
    "FIN": "Europe",
    "IBS": "Europe",
    "YRI": "Africa",
    "LWK": "Africa",
    "GWD": "Africa",
    "MSL": "Africa",
    "ESN": "Africa",
    "ASW": "Africa",
    "ACB": "Africa",
    "MXL": "Americas",
    "PUR": "Americas",
    "CLM": "Americas",
    "PEL": "Americas"
}

self_reported_map = {
    "White/European(e.g.English,Greek,Italian)": "Europe",
    "AshkenaziJewish": "Europe / Middle East",
    "Asian-SouthEast(e.g.Vietnamese,Filipino)": "Southeast Asia",
    "Asian-East(e.g.Chinese,Japanese)": "East Asia",
    "Asian-South(e.g.Indian,SriLankan,Indo-Caribbean)": "South Asia",
    "Black-African(e.g.Ghanaian,Somalian)": "Africa",
    "Black-Caribbean(e.g.Jamaican,Trinidadian,Barbadian)": "Africa",
    "Black-NorthAmerican": "Africa",
    "Latin-American(e.g.Argentinian,Chilean,Cuban)": "Americas",
    "MiddleEastern(e.g.Egyptian,Iranian,Israeli)": "Middle East",
    "Indigenous(e.g.Inuit,FirstNations,Metis)": "Americas",
    "Other": "Other"
}

df["Self-reported_Ancestry_clean"] = (
    df["Self-reported_Ancestry"]
    .fillna("")
    .str.replace(" ", "", regex=False)  # remove ALL spaces
)

# Map the columns to continental groups
df_out = pd.DataFrame()
df_out["Study_ID"] = df["Study_ID+N1Q1A1:R1"]
df_out["GP_CG"] = df["GrafPop_Ancestry"].map(grafpop_map)
df_out["HM_CG"] = df["HapMap3_Ancestry"].map(hapmap_map)
df_out["1KG_CG"] = df["1KGenomes_Ancestry"].map(okg_map)
df_out["Self_Reported_CG"] = df["Self-reported_Ancestry_clean"].map(self_reported_map)

# Save to new CSV
df_out.to_csv("ancestry_by_continental_group.csv", index=False)