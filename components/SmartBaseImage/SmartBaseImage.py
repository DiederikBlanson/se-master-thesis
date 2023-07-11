from components.RepositoryLocator.RepositoryLocator import RepositoryLocator

# two candidate images
std_image="rapt-base"
rver_image="rver-base"

class SmartBaseImage:
    def get_image(packages):

        # check all packages
        for package in packages:
            packageInfo = RepositoryLocator.get_package_details(package)
            repository = packageInfo["repository"]

            if repository == None:
                exit("Repository of package '{}' cannot be found".format(package))
            elif repository == "CRAN":
                if not packageInfo["hasBinary"]: # If it is a CRAN package without a binary version, return the r-verse image
                    return rver_image
            else:  # If it is not a CRAN package, return the r-verse image
                return rver_image
        
        # return default
        return std_image

if __name__ == "__main__":
    packages = ["dplyr"]
    smartImage = SmartBaseImage.get_image(packages)