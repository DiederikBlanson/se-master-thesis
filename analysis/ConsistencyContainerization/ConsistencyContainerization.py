import pandas as pd 
import matplotlib.pyplot as plt

def time_to_seconds(time_string):
    minutes, seconds = time_string.split('m')
    seconds = seconds.rstrip('s')
    total_seconds = int(minutes) * 60 + float(seconds)
    return total_seconds

"""
In order to gain insights into the reliability of the containerization time, we ran two algorithms (with and
without ”HiddenDependencies”) each six times for all projects, whose containerization data can be found in "db.csv".

This resulted in 60 data points (2*6*5) which we used to compare the containerization time of the algorithms in separate box plots. 
"""

# Subset of the "output.csv"
df = pd.read_csv('db.csv')

# Format dockerization time to seconds
df["dockergeneration-time-real"] = df["dockergeneration-time-real"].apply(lambda x: time_to_seconds(x))

# Get projects and loop through all projects
projects = df['source_folder'].unique()
for project in projects:

    # Extract "AdvancedDependencies" data (same as "HiddenDependencies")
    not_advanced = df[(df['source_folder'] == project) & (df['advanced-dependencies'] == 0)]['dockergeneration-time-real']
    advanced = df[(df['source_folder'] == project) & (df['advanced-dependencies'] == 1)]['dockergeneration-time-real']

    # Create a figure and axis
    fig, ax = plt.subplots()

    # Create the box plots
    boxplot1 = ax.boxplot(not_advanced, positions=[1], patch_artist=True, boxprops=dict(facecolor='skyblue'))
    boxplot2 = ax.boxplot(advanced, positions=[2], patch_artist=True, boxprops=dict(facecolor='lightgreen'))

    # Set labels and title
    ax.set_xticks([1, 2])
    ax.set_xticklabels(['Not Advanced', 'Advanced'])
    ax.set_ylabel('Dockerization time (in s)')
    ax.set_title('Project "{}"'.format(project.split("/")[1]))

    # Set the y-axis limit to start at 0
    ax.set_ylim(bottom=0)

    # Save the plot to a PNG file
    plt.savefig('results/{}-consistency-boxplot.png'.format(project.split("/")[1]))

    # Show the plot
    # plt.show()
