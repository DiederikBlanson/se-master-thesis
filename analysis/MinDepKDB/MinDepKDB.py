import pandas as pd

"""
This script analyses which packages and functions are used in the 6 ecological scripts
"""

# Obtain the knowledge base of which packages/functions are used by R scripts
df = pd.read_csv('../../components/PackageSetMinimizer/db.csv')

# Filter on the 6 ecological scripts
projects_to_filter = [
    'data-filtering',
    "community-indeces",
    "community-matrix",
    "size-class",
    "size-density",
    "traits-computation"
]
df = df[df['project'].isin(projects_to_filter)]

# Group by package and count unique functions and projects
df = df.groupby('package').agg(
    unique_projects=('project', 'nunique'),
    unique_functions=('function', 'nunique')
).reset_index()

# Rename the count columns
df = df.rename(columns={
    'unique_projects': 'Unique Projects',
    'unique_functions': 'Unique Functions'
})

# Sort by Unique Projects in descending order, then by Unique Functions in descending order
df = df.sort_values(by=['Unique Projects', 'Unique Functions'], ascending=[False, False])

# Print dataset and export results
print(df)
df.to_csv("results/result.csv", index=False)

