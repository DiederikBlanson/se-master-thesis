import json
import rpy2.robjects as robjects
import requests
import os

"""
    This module finds the package repository of any given package.
    We are supporting three repositories at the moment: CRAN, BioConductor and GitHub
"""

static_repos = [{
    "name": "CRAN",
    "file": "cranPackages"
}, {
    "name": "BioConductor",
    "file": "bioconductorPackages"
}, {
    "name": "GitHub",
    "file": "gitHubPackages"
}]

# Retrieve all packages from every package repository
def packages_repositories():
    repos = static_repos
    for i, repo in enumerate(repos):
        
        # read current db
        current_directory = os.path.dirname(os.path.abspath(__file__))
        json_path = os.path.join(current_directory, '{}.json'.format(repo['file']))
        
        with open(json_path, 'r') as f:
            json_string = f.read()
            packages = json.loads(json_string)
            repos[i]['len_packages'] = len(packages)
            repos[i]['packages'] = packages
    return repos


class RepositoryLocator:

    """
        'has_cran_binary' checks whether there exists a binary version of a CRAN package
    """
    @staticmethod 
    def has_cran_binary(package):

        # read current db
        current_directory = os.path.dirname(os.path.abspath(__file__))
        json_path = os.path.join(current_directory, 'bin-cran-libs.json')
        
        with open(json_path, 'r') as f:
            json_string = f.read()
            packages = json.loads(json_string)
        
        return "r-cran-{}".format(package.lower()) in packages


    """
        'get_package_details' retrieves the details of every package
    """
    @staticmethod
    def get_package_details(package):

        # Step 1: Check if package is available in the kernel (TODO: prevent output to terminal)
        # try:
        #     res = robjects.r("packageDescription('{}')".format(package))
        #     if res['Repository'] is not None:
        #         return res['Repository']
        # except Exception as e:
        #     pass

        # Step 2: Check Repository MetaData
        repos = packages_repositories()
        for repo in repos:
            for repo_package in repo['packages']:
                if repo_package["package"] == package:
                    merged_data = repo_package.copy()
                    merged_data.update({
                        'repository': repo['name']
                    })

                    if repo['name'] == "CRAN":
                        merged_data["hasBinary"] = RepositoryLocator.has_cran_binary(package)
                    return merged_data
        
        # Step 3: Check GitHub
        query = "topic:r-package language:R {}".format(package)
        url = "https://api.github.com/search/repositories?q={}".format(query)
        response = requests.get(url)
        try:
            if response.status_code != 200:
                raise Exception("")

            # Parse the JSON response
            data = response.json()
            items = data["items"]

            # check if there are results
            if len(items) == 0:
                raise Exception("")

            # TODO: Naive way: grab the first repository
            repo = items[0]

            # insert data in MetadataDB
            d = {
                'package': package,
                'repository': "GitHub",
                'full_package_name': repo["full_name"]
            }
            RepositoryLocator.insert_git_db(d)

            return d
        except Exception as e:
            return { "repository": None }


    """
        'insert_git_db' inserts a package in the knowledgebase when a GitHub package is detected
    """
    @staticmethod 
    def insert_git_db(obj):

        # read current db
        current_directory = os.path.dirname(os.path.abspath(__file__))
        db_path = os.path.join(current_directory, 'gitHubPackages.json')

        # Read the JSON file
        with open(db_path, 'r') as file:
            data = json.load(file)

        # Modify the parsed object
        data.append(obj)

        # Write the updated object back to the JSON file
        with open(db_path, 'w') as file:
            json.dump(data, file, indent=4)
    