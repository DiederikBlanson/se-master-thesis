import pandas as pd 

"""
This scripts investigates which functions and packages are used in the 6 ecological scripts provided by Maria. 
"""

# Dataset with all packages and their functions, obtained by the NCmisc package
df = pd.read_csv('db.csv')

# Create "Dependency Count" column
dependencies_count = df.groupby('package')['dependency'].nunique().reset_index()
dependencies_count.columns = ['package', 'dependency_count']

# Create "Function Count" column
functions_count = df.groupby('package')['func'].nunique().reset_index()
functions_count.columns = ['package', 'function_count']

# Merge the results and print in the console
result = pd.merge(dependencies_count, functions_count, on='package')
print(result)

# Save the result to a CSV file
result.to_csv('results/result.csv', index=False)