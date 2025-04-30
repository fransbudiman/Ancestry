# requires installing Kaleido and Plotly
# pip install -U kaleido
# pip install plotly

# for data manipulation and analysis
import pandas as pd
# for plotting 
import plotly.express as px
# for counting pairs
from collections import Counter

# function to read data from csv file
def read_csv(file_path, col1, col2):
    pairlist = []
    dataframe = pd.read_csv(file_path, engine='python')
    col1 = "HapMap3_Erika"
    col2 = "Self-reported_Ancestry"
    target = dataframe[[col1, col2]]
    for index, row in target.iterrows():
        result_tuple = (row[col1], row[col2])
        pairlist.append(result_tuple)
    return pairlist

sampledata = read_csv("C:\\UNIFRANS\\Work\\JLE\\temp\\GENCOV_Result1.csv", "HapMap3_Erika", "Self-reported_Ancestry")

xaxis = "HapMap3_Erika"
yaxis = "Self-reported_Ancestry"

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
fig.write_html("plot.html")
fig.write_image("plot.png") # uncomment to save as png
