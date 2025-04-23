# for data manipulation and analysis
import pandas as pd
# for plotting 
import plotly.express as px
# for counting pairs
from collections import Counter

import os
print("Current working directory:", os.getcwd())

# some sample data for testing. Change to reading from file later
rawdata = [
    ("CEU","CEU"), ("CEU","CHB"), ("CEU","JPT"), ("CHB","JPT"),
    ("CHB","CEU"), ("CHB","CHB"), ("CHB","JPT"), ("CHB","CHB")
]

xaxis = "Hapmap3"
yaxis = "1000 Genomes"

counter = Counter(rawdata)
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
    title=f"Bubble Plot for {xaxis} vs {yaxis}"
)

fig.show()
fig.write_html("plot.html")
fig.write_image("plot.png") # uncomment to save as png