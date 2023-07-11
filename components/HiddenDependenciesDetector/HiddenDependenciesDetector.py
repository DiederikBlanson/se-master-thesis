import pandas as pd 
import os
import openai
import re
GPT_MODEL = "gpt-3.5-turbo"

"""
    This module represents the "HiddenDependencies" component which includes a knowledgebase with dependency relations.
    The records are tuples of the format <package,dependency>.
    In case a 'package' is used in a script, the 'dependency' will be added to the list of dependencies to be installed.
"""

def get_additional_packages(value):
    result = ""
    pattern = r"\$\$(.+?)\$\$"
    matches = re.findall(pattern, value)

    # get the content of each match
    for match in matches:
        result += match.strip()
    if result == "":
        return []
    
    result = result.replace(' ', '').split(',')
    return result

class HiddenDependenciesDetector:

    """
        'insert_hidden_dep' inserts dependencies on a list of packages. For example, we have:
        - packages = [a,b]
        - dependencies = [c,d,e]

        Then the following tuples are added to the knowledgebase:
        <a,c>
        <a,d>
        <a,e>
        <b,c>
        <b,d>
        <b,e>

        This granularity is called 'Package Level'
    """
    @staticmethod
    def insert_hidden_dep(packages, dependencies):
  
        # read current db
        current_directory = os.path.dirname(os.path.abspath(__file__))
        db_csv_path = os.path.join(current_directory, 'db.csv')
        df = pd.read_csv(db_csv_path)

        # Loop over the packages and dependency combinations
        new_rows = []
        for package in packages:
            for dependency in dependencies:
                new_rows.append({
                    'package': package["package"], 
                    'dependency': dependency
                })

        # Concatenate the new rows with the existing DataFrame
        new_df = pd.concat([df, pd.DataFrame(new_rows)], ignore_index=True)

        # Write the updated DataFrame back to a CSV file
        new_df = new_df.drop_duplicates()
        new_df.to_csv(db_csv_path, index=False)


    """
        'get_hidden_dep' returns all dependencies based on a list of dependencies.
    """
    @staticmethod 
    def get_hidden_dep(packages):

        i_packages = [package["package"] for package in packages]
        
        # read current db
        current_directory = os.path.dirname(os.path.abspath(__file__))
        db_csv_path = os.path.join(current_directory, 'db.csv')
        df = pd.read_csv(db_csv_path)

        # Filter the DataFrame based on the given packages
        filtered_df = df[df['package'].isin(i_packages)]

        # Get all unique dependencies from the filtered DataFrame
        unique_dependencies = filtered_df['dependency'].unique()

        # Merge unique dependencies with the input packages and obtain the unique ones
        hidden_dependencies = [x for x in unique_dependencies if x not in [pack['package'] for pack in packages]]

        return [{"package": pkg, "inScript": True, "toDownload": True} for pkg in hidden_dependencies]
    

    def chatgpt_packages(obj, out, API_KEY):
        chatgpt_packages = []
        openai.api_key = API_KEY

        with open('{}/myScript.r'.format(obj['source_folder']), 'r', newline='') as f:
            gpt_result = ''
            file_contents = f.read()

            # print("This is the error message: " + str(out)[-4000:])
            response = openai.ChatCompletion.create(
                model=GPT_MODEL,
                messages=[
                    {
                        "role": "system",
                        "content": "You are a chatbot"
                    }
                    ,{
                        "role": "user",
                        "content": "This is the R script that I wrote: " + file_contents
                    },
                    {
                        "role": "user",
                        "content": "This is the error message: " + str(out)[-4000:]
                    },
                    {
                        "role": "user",
                        "content": "The R script that I wrote cannot be executed successfully. I would like to know if there are any additional R dependencies that I need to install based on the error message. Can you provide me with a list of these additional R-only dependencies? You must format the list as follows: $$package1, package2, package3$$"
                    }
                ]
            )

            for choice in response.choices:
                gpt_result += choice.message.content

            # print("ChatGPT Prompt Result: ", gpt_result)
            chatgpt_packages = get_additional_packages(gpt_result)
            # print("Formatted result", chatgpt_packages)

            # only the dependencies that are not already included. this is because chatgpt not always gives the correct result
            chatgpt_packages = [x for x in chatgpt_packages if x not in [pack['package'] for pack in obj['original_dependencies']]]
            # print("Formatted result (filtered packages): ", chatgpt_packages)
        
        return chatgpt_packages