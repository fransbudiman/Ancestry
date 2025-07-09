import plotly.graph_objects as go
import pandas as pd
import argparse

# default values
source_label = "Self-reported_Ancestry"
target_label = "Inferred_Ancestry"
value_label = "Normalized_Proportions"

parser = argparse.ArgumentParser()
parser.add_argument('-s', '--source', default=source_label, help='Source label for the Sankey diagram')
parser.add_argument('-t', '--target', default=target_label, help='Target label for the Sankey diagram')
parser.add_argument('-v', '--value', default=value_label, help='Value label for the Sankey diagram')

args = parser.parse_args()
source_label = args.source
target_label = args.target
value_label = args.value

df = pd.read_csv("C:\\UNIFRANS\\Work\\JLE\\Sankey\\test_mock.csv", engine='python')
source_list = df[source_label].tolist()
target_list = df[target_label].tolist()
value_list = df[value_label].tolist()

unique_source = list(set(source_list))
unique_target = list(set(target_list))
unique_elements = unique_source + unique_target
unique_count = len(unique_elements)
counter = 0
for i in range(len(source_list)):
    source_list[i] = unique_elements.index(source_list[i])

for i in range(len(target_list)):
    target_list[i] = unique_elements.index(target_list[i])


name="Self-reported_Ancestry Sankey Diagram"
fig = go.Figure(data=[go.Sankey(
    node = dict(
      pad = 15,
      thickness = 20,
      line = dict(color = "black", width = 0.5),
      label = unique_elements,
    #   color = "blue"
    ),
    link = dict(
      source = source_list, # Source represents self-reported ancestry
      target = target_list, # Target represents ancestry inference results
      value = value_list, # Value represents the sum of the normalized ancestry proportions
    #   hovercolor=["midnightblue", "lightskyblue", "gold", "mediumturquoise", "lightgreen", "cyan"]

  ))])

fig.update_layout(title_text=name, font_size=10)
fig.show()