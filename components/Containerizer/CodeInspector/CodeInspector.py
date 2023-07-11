import shutil
import os
from dotenv import load_dotenv
from utils import Utils
load_dotenv(override=True)
from components.HiddenDependenciesDetector.HiddenDependenciesDetector import HiddenDependenciesDetector
from components.ProjectPackages.ProjectPackages import ProjectPackages
from components.PackageSetMinimizer.PackageSetMinimizer import PackageSetMinimizer
from components.RepositoryLocator.RepositoryLocator import RepositoryLocator
from components.PackageDetector.PackageDetector import PackageDetector
from components.SmartBaseImage.SmartBaseImage import SmartBaseImage
from rpy2.robjects.packages import importr
base = importr('base')

# Additional commands. There might be some additional commands that we have to perform based on the image
def additional_commands(obj, file):
    file.write("USER root \n")
    file.write("\n")

    # file.write("RUN apt-get update && apt-get install -y r-base \n") necessary for buildpack-deps:bionic
    if obj["base_image"] == "rocker/r-ver:4.1.1" or obj["base_image"] == "rver-base": # This is for the tidyverse package
        if obj["extended-base"] == 1:
            file.write("ENV DEBIAN_FRONTEND=noninteractive \n")
            file.write("RUN apt-get update \n")
            file.write("RUN apt install -y libxml2 libodbc1 \n")
            file.write("\n")

class CodeInspector:
    def inspect(obj):
        print("Starting the 'CodeInspection' =>")

        result_folder_name = 'results/{}'.format(obj["source_folder"].split("/")[1])
        R_FILE_NAME_RAW = "myScript"
        CONTAINER_WD = "/app"
        R_FILE_NAME = "{}.R".format(R_FILE_NAME_RAW)
        R_FILE_IMPROVED = "{}/{}-improved.R".format(result_folder_name, R_FILE_NAME_RAW)

        # variables
        source_file = "{}/{}".format(obj["source_folder"], R_FILE_NAME)

        # Create result folder and copy the contents
        if os.path.exists(result_folder_name):
            shutil.rmtree(result_folder_name)
        shutil.copytree(obj["source_folder"], result_folder_name)

        # get packages from script
        packages = []
        print("\t- Detect packages using 'PackageDetector'")
        if obj["package_extraction"] == "naive":
            packages = PackageDetector.packages_naive(source_file)
        elif obj["package_extraction"] == "renv":
            packages = PackageDetector.packages_renv(source_file)
        else:
            raise "No valid value for 'package_extraction'"
        obj['detected_dependencies'] = len(packages)

        # insert packages in knowledgebase
        ProjectPackages.insert_project_packages(obj["source_folder"], packages)

        # smart base image
        if "base_image" not in obj:
            smart_image = SmartBaseImage.get_image([package["package"] for package in packages])
            obj["base_image"] = smart_image
            print("\t- Using the 'SmartBaseImage' component, '{}' has been selected".format(smart_image))
        base_image = obj["base_image"]

        # check for advanced dependencies:
        hidden_dep = []
        if obj["advanced-dependencies"] == 1:
            print("\t- Detect hidden dependencies using 'HiddenDependenciesDetector'")
            hidden_dep = HiddenDependenciesDetector.get_hidden_dep(packages) 

        # check if the dependencies are included in the base image
        if obj["minimal-set"] == 1:
            print("\t- Extract minimal set of packages using 'PackageSetMinimizer'")
            packages = PackageSetMinimizer.get_minimum_set(obj, packages, os.getcwd())
        elif obj["ms-base-image"] == 1:
            packages = PackageSetMinimizer.packages_not_in_base(obj, packages)

        # add the hidden dependencies
        packages = packages + hidden_dep
        obj['original_dependencies'] = packages.copy()

        # add development libraries to the images.
        packages.append({
            "package": "NCmisc",
            "inScript": False,
            "toDownload": True,
        })
        packages = packages + [{
            "package": "optparse",
            "inScript": False,
            "toDownload": True,
        }, {
            "package": "jsonlite",
            "inScript": False,
            "toDownload": True,
        }]
        if obj["minimal-set"] == 1 or obj["ms-base-image"] == 1:
            packages = PackageSetMinimizer.packages_not_in_base(obj, packages)
    
        # set data in the result
        obj['installed_dependencies_list'] = packages
        obj['installed_dependencies'] = len(packages)

        # Generate a Dockerfile
        with open("{}/Dockerfile".format(result_folder_name), "w") as file:

            # Write base-image and additional commands
            file.write("FROM {}\n\n".format(base_image))
            additional_commands(obj, file)

            # Install packages
            packagesToDownload = [d for d in obj['installed_dependencies_list'] if d['toDownload']]
            
            if obj["dependency_installation"] == "cran-only-source":
                obj = packages_only_source_cran(obj, file, packagesToDownload)
            elif obj["dependency_installation"] == "spm-only-binary":
                obj = packages_only_binary_spm(obj, file, packagesToDownload)
            elif obj["dependency_installation"] == "rspm-only-binary":
                obj = packages_only_binary_rspm(obj, file, packagesToDownload)
            elif obj["dependency_installation"] == "all-only-source":
                obj = packages_only_source_all(obj, file, packagesToDownload)
            elif obj["dependency_installation"] == "smart":
                obj = packages_smart(obj, file, packagesToDownload)
            else:
                raise "No valid value for 'dependency_installation'"

            # Copy code and other assets
            file.write("RUN mkdir -p {} \n".format(CONTAINER_WD))
            file.write("COPY myScript-improved.R {}/ \n\n".format(CONTAINER_WD))
        
        # Add a working directory to the R script file
        print("\t- Generated Dockerfile")
        add_working_directory(obj, source_file, R_FILE_IMPROVED)
        return obj


# add working directory
def add_working_directory(obj, source, target):
    with open(source, 'r') as infile, open(target, 'w') as outfile:
        lines = infile.readlines()
        start = 0 
        end = len(lines) - 1

        # only select the lines
        if "lines" in obj:
            start, end = obj["lines"]
            start = start - 1
        selected_lines = lines[start:end]
    
        # Write the additional line to the new file
        outfile.write('# Set working directory such that it matches the Docker container\n')
        outfile.write('setwd("/app")\n\n')

        # write necessary packages, if we containerize individual cells. this also assumes that
        # the individual cell does not contain any imports
        if "lines" in obj:
            outfile.write("# include packages \n")
            for package in [d["package"] for d in obj['installed_dependencies_list'] if d['inScript']]:
                outfile.write("library({}) \n".format(package))
            outfile.write("\n")

        # this is done using the 'optparse' library, which does something similar as in the Python script
        if ("inputs" in obj) and (len(obj["inputs"]) > 0):
            inputs = obj["inputs"]
            outfile.write("# retrieve input parameters\n")
            outfile.write("library(optparse) \n")
            outfile.write("option_list = list( \n")

            for i, (value) in enumerate(inputs):
                my_type = Utils.get_type(value["type"])
                outfile.write('''\t make_option(c("--{}"), action="store", default=NA, type='{}', help="my description")'''.format(value["name"], my_type)) # https://gist.github.com/ericminikel/8428297
                
                if i != len(inputs) - 1:
                    outfile.write(",")
                outfile.write("\n")
            outfile.write(")\n\n")

            # set input type parameters
            outfile.write("# set input parameters accordingly \n")
            outfile.write("opt = parse_args(OptionParser(option_list=option_list)) \n")

            # replace inputs
            outfile.write("library(jsonlite) \n")
            for value in inputs:
                name = value["name"]
                if value["type"] == "list":
                    outfile.write('''{} = fromJSON(opt${}) \n'''.format(name, name))
                else:
                    outfile.write('''{} = opt${} \n'''.format(name, name))
            outfile.write("\n")

            # # check that the fields are set
            outfile.write("# check if the fields are set \n")
            for value in inputs: 
                name = value["name"]
                outfile.write("if(is.na({})){{ \n".format(name))
                outfile.write("   stop('the `{}` parameter is not correctly set. See script usage (--help)') \n".format(name))
                outfile.write("}\n")
            outfile.write("\n")
        
        # Copy the contents of the original file to the new file
        for line in selected_lines:
            outfile.write(line)

def packages_only_binary_spm(obj, file, packages):
    # 1.2.3 (BSPM approach) is said to be the same.
    if len(packages) > 0:
        file.write("RUN apt-get update && \\ \n")
        file.write("    apt-get install -y -qq \\ \n")
        for i, package in enumerate(packages):
            pkgName = package["package"]
            packageInfo = RepositoryLocator.get_package_details(pkgName)
            
            if (packageInfo["repository"] == "CRAN") and (packageInfo["hasBinary"] == True):
                file.write("\t\tr-cran-{}".format(pkgName.lower())) 
                if i == len(packages) - 1:
                    file.write("\n".format(pkgName))
                else:
                    file.write(" \\\n".format(pkgName))
            else: 
                obj["dockerfile-error"] = "The package '{}' could not be located in the CRAN repository and/or does not have a binary format".format(pkgName)
                obj["error-label"] = "PKG_NO_BINARY_CRAN_VERSION"
        file.write("\n")

    return obj

def packages_smart(obj, file, packages):
    for package in packages:
        pkgName = package["package"]
        packageInfo = RepositoryLocator.get_package_details(pkgName)
        repository = packageInfo["repository"]
        
        if repository == "CRAN":
            hasBinary = packageInfo["hasBinary"]
            if hasBinary:
                file.write("RUN apt-get install -y -qq r-cran-{} \n".format(pkgName.lower()))
            else:
                file.write("RUN R -e \"install.packages('{}', repos='http://cran.rstudio.com/')\"\n".format(pkgName))
        elif repository == "BioConductor":
            file.write("RUN R -e \"if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager', repos='http://cran.rstudio.com/') \"\n".format(pkgName))
            file.write("RUN R -e \"BiocManager::install('DESeq2')\"\n".format(pkgName))
        elif repository == "GitHub":
            file.write("RUN R -e \"if (!requireNamespace('remotes', quietly = TRUE)) install.packages('remotes') \"\n".format(pkgName))
            file.write("RUN R -e \"remotes::install_github('{}')\"\n".format(packageInfo["full_package_name"]))
        else:
            obj["dockerfile-error"] = "The package '{}' could not be located in any package epository".format(pkgName)
            obj["error-label"] = "PKG_NOT_FOUND"

    file.write("\n")
    return obj


def packages_only_source_all(obj, file, packages):
    for package in packages:
        pkgName = package["package"]
        packageInfo = RepositoryLocator.get_package_details(pkgName)
        repository = packageInfo["repository"]

        if repository == "CRAN":
            file.write("RUN R -e \"install.packages('{}', repos='http://cran.rstudio.com/')\"\n".format(pkgName))
        elif repository == "BioConductor":
            file.write("RUN R -e \"if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager', repos='http://cran.rstudio.com/') \"\n".format(pkgName))
            file.write("RUN R -e \"BiocManager::install('DESeq2')\"\n".format(pkgName))
        elif repository == "GitHub":
            file.write("RUN R -e \"if (!requireNamespace('remotes', quietly = TRUE)) install.packages('remotes') \"\n".format(pkgName))
            file.write("RUN R -e \"remotes::install_github('{}')\"\n".format(packageInfo["full_package_name"]))
        else:
            obj["dockerfile-error"] = "The package '{}' could not be located in any Package Repository".format(pkgName)
            obj["error-label"] = "PKG_NOT_FOUND"
    
    file.write("\n")
    return obj

def packages_only_source_cran(obj, file, packages):
    # this approach assumes that we can download the latest version of the package
    # via the source CRAN. This needs to be revisited later.
    for package in packages:
        pkgName = package["package"]
        packageInfo = RepositoryLocator.get_package_details(pkgName)

        if packageInfo["repository"] == "CRAN":
            file.write("RUN R -e \"install.packages('{}', repos='http://cran.rstudio.com/')\"\n".format(package["package"]))
        else: 
            obj["dockerfile-error"] = "The package '{}' could not be located in the CRAN repository".format(pkgName)
            obj["error-label"] = "PKG_NOT_FOUND"

    file.write("\n")
    return obj

def packages_only_binary_rspm(obj, file, packages):
    # 1.2.1 PPM https://rocker-project.org/use/extending.html
    if len(packages) > 0:
        file.write("RUN install2.r --error \\ \n") 
        for i, package in enumerate(packages):
            pkgName = package["package"]
            file.write("\t{}".format(pkgName))
            if i == len(packages) - 1:
                file.write("\n".format(pkgName))
            else:
                file.write(" \\\n".format(pkgName))
        file.write("RUN strip /usr/local/lib/R/site-library/*/libs/*.so \n")
        file.write("\n")
    
    return obj