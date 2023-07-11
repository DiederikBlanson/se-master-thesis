import pandas as pd

"""
This script analyses the speed improvement of enabling the "Minimal Dependencies" component
"""

# Obtain dataset
df = pd.read_csv('../../final-data/input-output.csv')

# Obtain records where "Minimal Dependencies" is enabled
filtered_df = df[df['strategy'] == "native-python"]
columns_to_check = ['project', 'cell']

# Obtain records where "Minimal Dependencies" is disabled
old_df = df[df['strategy'] == "native-r"]
grouped_old_df = old_df.groupby(columns_to_check).first().reset_index()

# Merge the 2 subsets from above
merged_df = pd.merge(filtered_df, grouped_old_df, on=columns_to_check, how='left', suffixes=('', '_native-r'))

# Obtain time difference
merged_df['time_difference'] = pd.to_datetime(merged_df['time'], format='%Mm%S.%fs', errors='coerce') - pd.to_datetime(merged_df['time_native-r'], format='%Mm%S.%fs', errors='coerce')
merged_df['time_difference'] = merged_df['time_difference'].dt.total_seconds()
merged_df['time_difference'] = merged_df['time_difference'].apply(lambda x: '-{:02d}m{:06.3f}s'.format(int(abs(x) // 60), abs(x) % 60) if pd.notnull(x) and x < 0 else '{:02d}m{:06.3f}s'.format(int(x // 60), x % 60) if pd.notnull(x) else '')

# Measure the total number of seconds
reference_time = pd.to_datetime('00:00:00', format='%H:%M:%S')
merged_df['time_native-r'] = (pd.to_datetime(merged_df['time_native-r'], format='%Mm%S.%fs', errors='coerce') - reference_time).dt.total_seconds()
merged_df['time'] = (pd.to_datetime(merged_df['time'], format='%Mm%S.%fs', errors='coerce') - reference_time).dt.total_seconds()

# Measure the speedup generated by enabling "Minimal Dependencies". A positive value means that there is an improvement, a negative value indicates an increase of containerization time
merged_df['speedup'] = -100 * ((merged_df['time_native-r'] - merged_df['time']) / merged_df['time'])
merged_df['speedup'] = merged_df['speedup'].round(1)

# Prepare final assets, rename the column headers
columns_to_keep = ['project', 'cell', 'lines', 'time', 'time_native-r', 'time_difference', 'speedup']
merged_df = merged_df[columns_to_keep]
merged_df.columns = ['Project', 'Cell', 'Lines', 'Time (Native-Python)', 'Time (Native-R)', 'Time (Δ)', 'Speedup (in %)']

# Print the results and save to a CSV
print("----------------")
print(merged_df)
merged_df.to_csv("results/result.csv", index=False)
print("----------------")
print("Mean speedup (in %): ", merged_df['Speedup (in %)'].mean().round(1))