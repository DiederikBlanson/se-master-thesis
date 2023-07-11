import pandas as pd

"""
This script analyses each R script to determine if there is a combination of properties (e.g. base image and dependency algorithm) that results in an executable project.
"""

# Dataset containerization
df = pd.read_csv('../../final-data/results.csv')

# Replace "rdb/" in "source_folder" column
df['source_folder'] = df['source_folder'].str.replace("rdb/", "")
df['dockergeneration-time-real'] = pd.to_datetime(df['dockergeneration-time-real'], format='%Mm%S.%fs', errors='coerce')

# Group the dataframe by 'source_folder' and check if there is any entry with 'executable' set to 1
grouped = df.groupby('source_folder')['executable'].any().reset_index()

# Create the 'Executable' column based on the 'executable' values
grouped['Executable'] = grouped['executable'].apply(lambda x: 1 if x else 0)

# Drop the unnecessary 'executable' column
grouped.drop('executable', axis=1, inplace=True)

# Print the dataset, and save the result to a CSV file
print(grouped)
grouped.to_csv('results/result.csv', index=False)
