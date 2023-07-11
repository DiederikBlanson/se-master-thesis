import pandas as pd
import os

"""
    This script stores all packages used by the R script for analytical purposes. 

    The data is stored as a tuple in format <project,package>. For example, if we have:
    - project: PACK
    - packages: [a,b,c]

    Then the following tuples are added to the knowledgebase:
    <PACK,a>
    <PACK,b>
    <PACK,c>
"""

class ProjectPackages:
    @staticmethod 
    def insert_project_packages(project, packages):
        
        # read current db
        current_directory = os.path.dirname(os.path.abspath(__file__))
        db_csv_path = os.path.join(current_directory, 'db.csv')
        df = pd.read_csv(db_csv_path)

        # Loop over the packages and dependency combinations
        new_rows = []
        for package in packages:
            new_rows.append({'project': project, 'package': package["package"]})

        # Concatenate the new rows with the existing DataFrame
        new_df = pd.concat([df, pd.DataFrame(new_rows)], ignore_index=True)

        # Write the updated DataFrame back to a CSV file
        new_df = new_df.drop_duplicates()
        new_df.to_csv(db_csv_path, index=False)