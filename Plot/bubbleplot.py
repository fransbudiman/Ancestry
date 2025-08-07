# requires installing Kaleido and Plotly
"""
python3 -m venv $HOME/myenv
source $HOME/myenv/bin/activate
pip install --upgrade pip
pip install pandas plotly kaleido
"""


# for data manipulation and analysis
import pandas as pd
# for plotting 
import plotly.express as px
# for counting pairs
from collections import Counter
# for command line argument parsing
import argparse

# default values
col1_label = "HapMap3_Erika"
col2_label = "Self-reported_Ancestry"
file_path = "C:\\UNIFRANS\\Work\\JLE\\temp\\GENCOV_Result1.csv"
mode= "all"


parser = argparse.ArgumentParser()
parser.add_argument('-f', '--file', default=file_path, help='Path to the CSV file containing the data')
parser.add_argument('-c1', '--col1', default=col1_label, help='Column name for the first axis')
parser.add_argument('-c2', '--col2', default=col2_label, help='Column name for the second axis')
parser.add_argument('-m', '--mode', default=mode, help='Filter for the data (default: all)')
args = parser.parse_args()

col1_label = args.col1
col2_label = args.col2
file_path = args.file
mode = args.mode

# function to read data from csv file
def read_csv(file_path, col1, col2, mode="all"):
    pairlist = []
    dataframe = pd.read_csv(file_path, engine='python', quotechar='"')
    target = dataframe[[col1, col2]]
    for index, row in target.iterrows():
        result_tuple = (row[col1], row[col2])
        if mode == "all":
            pairlist.append(result_tuple)
        elif mode == "unadmixed":
            if col1 == "Self-reported_Ancestry":
                if ";" in str(row[col1]):
                    continue
                else:
                    pairlist.append(result_tuple)
            elif col2 == "Self-reported_Ancestry":
                if ";" in str(row[col2]):
                    continue
                else:
                    pairlist.append(result_tuple)
            else:
                # If mode is not "all" or "unadmixed", we assume we want to include all pairs
                pairlist.append(result_tuple)
        elif mode == "admixed":
            if col1 == "Self-reported_Ancestry":
                if ";" in str(row[col1]):
                    pairlist.append(result_tuple)
            elif col2 == "Self-reported_Ancestry":
                if ";" in str(row[col2]):
                    pairlist.append(result_tuple)
            else:
                # If mode is not "all" or "unadmixed", we assume we want to include all pairs
                pairlist.append(result_tuple)
        else:
            print(f"Unknown mode: {mode}. Please use 'all', 'unadmixed', or 'admixed'.")
            exit(1)
    print(f"Number of pairs collected: {len(pairlist)}")  # for debugging remove later
    return pairlist

sampledata = read_csv(file_path, col1_label, col2_label, mode)

xaxis = col1_label
yaxis = col2_label

counter = Counter(sampledata)
print(counter) # for debugging remove later
# counter is a dictionary with tuples as keys and counts as values

df = pd.DataFrame([
    {xaxis: res1, yaxis: res2, "count": count}
    for (res1, res2), count in counter.items()
])

fig = px.scatter(
    df,
    x=xaxis, 
    y=yaxis, 
    size="count",
    size_max=60,
    title=f"Bubble Plot for {xaxis} vs {yaxis}",
    category_orders={
        xaxis: sorted(df[xaxis].dropna().unique()),
        yaxis: sorted(df[yaxis].dropna().unique(), reverse=True)
    }
)

fig.show()
fig.write_html(f"bubble_{col1_label}_{col2_label}_{mode}.html")
# fig.write_image(f"bubble_{col1_label}_{col2_label}.png") # uncomment to save as png
