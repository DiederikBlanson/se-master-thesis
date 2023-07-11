import sys
import os
import time
import json
import textwrap
from dotenv import load_dotenv
load_dotenv(override=True)
from components.ResultsContainerization.ResultsContainerization import ResultsContainerization
from components.Containerizer.Containerizer import Containerizer

''' ----------------------------------------
        ServiceHelper Component
---------------------------------------- '''

def ServiceHelper(debug):
    result = []
    i = 0
    MAX_ITER_ALGO = 4
    start_time = time.time()

    # Read project configuration file
    config_file = sys.argv[1] 
    config = None
    with open(config_file, 'r') as file:
        config = json.load(file)

    # Read config parameters
    projects = config["projects"]
    algorithms = config["algorithms"]

    # print welcome file
    os.system('cls' if os.name == 'nt' else 'clear')
    print(textwrap.dedent("""
    ================================================================= 

        Welcome to R-Containerizer!

        Using this tool, you can start containerizing R scripts.
        Note: The Docker Daemon should run.

        The following configurations are set:
            - Config file: {}
            - Number of projects: {}
            - Number of algorithms: {}
            - Total project and algorithm combinations: {} 

    =================================================================
    """.format(config_file, len(projects), len(algorithms), len(projects)*len(algorithms))))
    
    # Check every project
    for project in projects:
        algorithm_i = 0
        iter_algo = 1

        while algorithm_i < len(algorithms):
            algorithm = algorithms[algorithm_i]
            i += 1
            print(textwrap.dedent("""
            -------------- RUN {} ---------------     
            Configuration:
                - Project: {}
                - Iteration: {}
                - Base image: {}
                - Package extraction algorithm: {}
                - 'MinimalPackageSet': {}
                - 'HiddenDependencies': {}
            """.format(
                i, 
                project['source_folder'],
                iter_algo, 
                algorithm['base_image'] if 'base_image' in algorithm else 'Not specified. Determine using the "SmartBaseImage" component',
                algorithm['package_extraction'],
                bool(algorithm['minimal-set']),
                bool(algorithm['advanced-dependencies'])
            )))
            
            # containerize project
            obj = project
            obj['again'] = 0
            obj.update(algorithm)
            project_result = Containerizer.containerize(obj, debug)

            if project_result['again'] == 0:
                overall_time = time.time() - start_time
                project_result["overall-time"] = overall_time
                result.append(project_result)
                ResultsContainerization.write_dict_to_csv(project_result)
                algorithm_i += 1
                iter_algo = 0
                start_time = time.time()
            else:
                if iter_algo >= MAX_ITER_ALGO:
                    ResultsContainerization.write_dict_to_csv(project_result)
                    iter_algo = 0
                    algorithm_i += 1
                else:
                    pass # We will check the algorithm again 
                iter_algo += 1

if __name__ == "__main__":
    ServiceHelper(0)
