# Source: https://github.com/o2r-project/containerit

library(containerit)

my_dockerfile <- containerit::dockerfile(from = utils::sessionInfo())

rmd_dockerfile <- containerit::dockerfile(from = "demo.Rmd",
                                          image = "rocker/r-apt:bionic",
                                          maintainer = "o2r",
                                          filter_baseimage_pkgs = TRUE)

print(rmd_dockerfile)                               