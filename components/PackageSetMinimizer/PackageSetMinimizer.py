import subprocess
import os
import re
import pandas as pd

"""
    This module performs a script analysis which is used for the "MinimalPackageSet" component.
"""

class PackageSetMinimizer:

    # --------------- UTILITIES -----------------
    def get_path():
        current_directory = os.path.dirname(os.path.abspath(__file__))
        return os.path.join(current_directory, 'db.csv')

    def write_db(df):
        return df.to_csv(PackageSetMinimizer.get_path(), index=False)
    
    def get_db():
        return pd.read_csv(PackageSetMinimizer.get_path())

    # --------------- INSERT FUNCTIONS -----------------
    @staticmethod
    def insert_code_analysis(obj, pwd):
        PackageSetMinimizer.insert_dependency_functions(obj, pwd)

    @staticmethod
    def insert_dependency_functions(obj, pwd):
        packages = obj["installed_dependencies_list"]
        result = []

        # Step 1: import all used libraries in the environment of the user
        pkg = " ".join(['library({});'.format(x["package"]) for x in packages])

        # Step 2: retrieve response from NCmisc
        p = subprocess.Popen(
            'docker run -it --rm -v {}/{}:/app {} Rscript -e "{} list.functions.in.file(\'/app/myScript.R\')"'.format(pwd, obj["source_folder"], obj['docker_image_name'], pkg),
            shell=True, 
            stdout=subprocess.PIPE, 
            stderr=subprocess.PIPE
        )
        a, _ = p.communicate()
        a = a.decode("utf-8").strip().split('\n')
        result = PackageSetMinimizer.parse_ncmisc(a)

        PackageSetMinimizer.write_lib_func_db(obj, result)

    @staticmethod
    def write_lib_func_db(obj, result):
        df = PackageSetMinimizer.get_db()

        # Loop over the packages and dependency combinations
        new_rows = []
        
        for package, funcs in result.items():
            if package != "NONE": # Skip the NONE rows
                for func in funcs:
                    new_rows.append({
                        'project': obj["docker_image_name"], 
                        'package': package,
                        'function': func
                    })

        # Concatenate the new rows with the existing DataFrame
        new_df = pd.concat([df, pd.DataFrame(new_rows)], ignore_index=True)
        new_df = new_df.drop_duplicates()
        PackageSetMinimizer.write_db(new_df)

    # --------------- GET FUNCTIONS -----------------

    @staticmethod 
    def get_minimum_set(obj, packages, pwd):

        # Step 1: Get only the packages whose functions are used
        result = PackageSetMinimizer.get_function_packages(obj, packages, pwd)

        # Step 2: Get only the packages that are not included in the base image
        result = PackageSetMinimizer.packages_not_in_base(obj, result)
        return result
    
    """
        'packages_not_in_base' checks which packages are already included in the base image
    """
    @staticmethod 
    def packages_not_in_base(obj, packages):
        for i, package in enumerate(packages):
            try:
                cmd = "docker run --rm -it {} Rscript -e 'library({})'".format(obj["base_image"], package["package"])
                res = subprocess.check_output(cmd, shell=True, stderr=subprocess.DEVNULL)
                packages[i]["toDownload"] = False
            except Exception as e:
                a = 1
        return packages

    """
        'parse_ncmisc' is a custom parser that maps an R data object to a Python object.
    """
    @staticmethod 
    def parse_ncmisc(a):

        # Step 3: Find relations between functions and libraries using the R package "NCmisc"
        result = {}
        package_functions = []
        inGroup = False
        pkgs = []

        for line in a:
            pkg_line = re.search(r'\$`(.*?)`', line)
            funcs = re.findall(r'"(.*?)"', line)

            if "character(0)" in line: 
                pkgs = ["NONE"]
                inGroup = True
            elif pkg_line is not None:
                if inGroup:
                    for pk in pkgs:
                        result.setdefault(pk, []).extend(package_functions)
                else:
                    inGroup = True 
                package_functions = []

                # new packages parsers
                tmp = pkg_line.group(1)
                tmp_single = re.fullmatch(r'package:(.*?)', tmp)
                tmp_double = re.findall(r'"package:(.*?)"', tmp)

                if tmp_single is not None:
                    pkgs = [tmp_single.group(1)]
                elif tmp_double is not None:
                    pkgs = tmp_double
            elif funcs:
                package_functions.extend(func.strip() for func in funcs)

        if inGroup:
            for pk in pkgs:
                result.setdefault(pk, []).extend(package_functions)
        return result

    """
        'tmp_jupyter_cell' creates a temporary file in case we only want to containerize specific lines of a script
    """
    @staticmethod 
    def tmp_jupyter_cell(obj, pwd):
        inf = "{}/rdb/{}/myScript.R".format(pwd, obj["docker_image_name"]) # TODO: remove hardcoded string
        outf = "/tmp/{}-small.R".format(obj["docker_image_name"])
        
        with open(inf, 'r') as infile, open(outf, 'w') as outfile:
            lines = infile.readlines()
            start = 0 
            end = len(lines) - 1

            # get smaller set if lines are specified
            if "lines" in obj:
                start, end = obj["lines"]
                start = start - 1
            selected_lines = lines[start:end]

            # Copy the contents of the original file to the new file
            for line in selected_lines:
                outfile.write(line)

    """
        'get_function_packages' analyzes all functions and checks which dependencies are necessary. In case a function
        cannot be mapped to a package, called a 'MISS', we return all packages.
    """
    @staticmethod
    def get_function_packages(obj, packages, pwd):

        # for NCmisc we need a file to read all used functions
        # for this purpose we create a new file in the /tmp directory
        PackageSetMinimizer.tmp_jupyter_cell(obj, pwd)

         # Add additional packages
        default_pkgs = ['base', 'graphics', 'stats', 'utils', 'grDevices'] # This includes commonly used functions such as 'library()'
        inspect_pkg = [package["package"] for package in packages] + default_pkgs

        # Retrieve data
        p = subprocess.Popen('docker run -it --rm -v /tmp:/app ncmisc-base Rscript -e "library(NCmisc); list.functions.in.file(\'/app/{}-small.R\')"'.format(obj["docker_image_name"]), 
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        a, _ = p.communicate()
        a = a.decode("utf-8").strip().split('\n')
        result = PackageSetMinimizer.parse_ncmisc(a)

        # Initialize minimal set dictionary
        min_set = {}

        # Loop through functions and map them to packages
        df = PackageSetMinimizer.get_db()

        for _, funcs in result.items():
            for func in funcs:
                hasPackage = False
                for pkg in inspect_pkg:
                    record_exists = any((df['package'] == pkg) & (df['function'] == func))
                    if record_exists:
                        hasPackage = True
                        min_set[pkg] = True
                        break

                if not hasPackage:
                    print("The function '{}' cannot be found in previous code snippets, and we have to include all libraries for the minimal set.".format(func))
                    return packages

        # only keep the packages that are in the minimal set
        packages = [obj for obj in packages if obj['package'] in min_set.keys()]
        return packages
