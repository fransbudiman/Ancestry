# This one will need ancestry_by_continental_group.csv as input
# Create 3 confusion matrices, one for each tool.

import pandas as pd
import argparse
from sklearn.metrics import confusion_matrix
import seaborn as sns
import matplotlib.pyplot as plt
from sklearn.datasets import load_iris


df = pd.read_csv("C:\\UNIFRANS\\Work\\JLE\\Ancestry\\Plot\\ancestry_by_continental_group.csv", engine='python', quotechar='"')
sr_gp_df = df[['Self_Reported_CG', 'GP_CG']].dropna()
sr_hm_df = df[['Self_Reported_CG', 'HM_CG']].dropna()
sr_okg_df = df[['Self_Reported_CG', 'OKG_CG']].dropna()

okg_df = sr_okg_df['OKG_CG'].astype(str).tolist()
gp_df = sr_gp_df['GP_CG'].astype(str).tolist()
hm_df = sr_hm_df['HM_CG'].astype(str).tolist()

sr_gp_df = sr_gp_df['Self_Reported_CG'].dropna().astype(str).tolist()
sr_hm_df = sr_hm_df['Self_Reported_CG'].dropna().astype(str).tolist()
sr_okg_df = sr_okg_df['Self_Reported_CG'].dropna().astype(str).tolist()

sr_df = df['Self_Reported_CG'].dropna().astype(str).tolist()

# Get sorted list of unique classes (for labels and tick marks)
classes = sorted(set(sr_df))

# Compute confusion matrix
c_matrix_hm = confusion_matrix(sr_hm_df, hm_df, labels=classes)
c_matrix_okg = confusion_matrix(sr_okg_df, okg_df, labels=classes)
c_matrix_gp = confusion_matrix(sr_gp_df, gp_df, labels=classes)

sns.heatmap(c_matrix_hm, annot=True, fmt='d', cmap='YlGnBu',
            xticklabels=classes, yticklabels=classes)
plt.xlabel('Predicted (HapMap)', fontsize=12)
plt.ylabel('Actual (Self-Reported)', fontsize=12)
plt.title('Confusion Matrix: HapMap vs Self-Reported', fontsize=16)
plt.tight_layout()
plt.figure()

sns.heatmap(c_matrix_okg, annot=True, fmt='d', cmap='YlGnBu',
            xticklabels=classes, yticklabels=classes)
plt.xlabel('Predicted (OKG)', fontsize=12)
plt.ylabel('Actual (Self-Reported)', fontsize=12)
plt.title('Confusion Matrix: OKG vs Self-Reported', fontsize=16)
plt.tight_layout()
plt.figure()

sns.heatmap(c_matrix_gp, annot=True, fmt='d', cmap='YlGnBu',
            xticklabels=classes, yticklabels=classes)

plt.xlabel('Predicted (GP)', fontsize=12)
plt.ylabel('Actual (Self-Reported)', fontsize=12)
plt.title('Confusion Matrix: GP vs Self-Reported', fontsize=16)
plt.tight_layout()
plt.figure()

plt.show()