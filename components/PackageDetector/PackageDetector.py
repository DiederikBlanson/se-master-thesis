import re
import pandas as pd
import rpy2.robjects.packages as rpackages
import rpy2

class PackageDetector:
    def packages_naive(file):
        with open(file, 'r') as f:
            r_code = f.read()
            packages = re.findall(r'(?:library|require)\((?:package=)?(?:")?(\w+)(?:")?\)', r_code) # matches cases: require(pkg), library(pkg), library("pkg"), library(package=pkg), library(package="pkg")
            return  [{"package": pkg, "inScript": True, "toDownload": True} for pkg in packages]

    def packages_renv(file):
        rpy2.robjects.r('sink("/dev/null")') 
        renv = rpackages.importr('renv')
        function_list = renv.dependencies(file)
        packages = list(pd.DataFrame(function_list).transpose().iloc[:, 1])
        return  [{"package": pkg, "inScript": True, "toDownload": True} for pkg in packages]