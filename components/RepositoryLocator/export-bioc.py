import rpy2.robjects as robjects
import json

# Set CRAN mirror to the Netherlands
robjects.r('chooseCRANmirror(ind=46)')
packages = list(robjects.r('library(BiocManager); BiocManager::available()'))
packages = [{ 'package': x} for x in packages]

# Save the JSON string to a file
with open('bioconductorPackages.json', 'w') as f:
    json.dump(packages, f)