import argparse
import random
import os
import pandas as pd

parser = argparse.ArgumentParser(description="Randomly select a subset of rows from a CSV file.")
parser.add_argument("--input_file", "-i", type=str, required=True, help="Path to the input CSV file.")
parser.add_argument("--output_file", "-o", type=str, required=True, help="Path to save the output CSV file.")
parser.add_argument("--num_samples", "-n", type=int, required=True, help="Number of samples to randomly select.")
parser.add_argument("--seed", "-s", type=int, default=42, help="Random seed for reproducibility.")

args = parser.parse_args()
input_file = args.input_file
output_file = args.output_file
num_samples = args.num_samples
seed = args.seed

df = pd.read_csv(input_file)

column_name = "Self-reported_Ancestry"

groupby_object = df.groupby(column_name)
group_iters = {
    name: group.sample(frac=1, random_state=seed).iterrows()
    for name, group in groupby_object
}

selected_rows = []
group_ancestry= list(group_iters.keys())
done_ancestry = set()

while len(selected_rows) < num_samples:
    for ancestry in group_ancestry:
        if ancestry in done_ancestry:
            continue
        
        if len(selected_rows) >= num_samples:
            break
        try:
            _, row = next(group_iters[ancestry])
            selected_rows.append(row)
        except StopIteration:
            done_ancestry.add(ancestry)

    if len(done_ancestry) == len(group_ancestry):
        print("All groups exhausted. Stopping selection.")
        break

result_df = pd.DataFrame(selected_rows)
result_df.to_csv(output_file, index=False)
print(f"Randomly selected {len(result_df)} samples and saved to {output_file}.")