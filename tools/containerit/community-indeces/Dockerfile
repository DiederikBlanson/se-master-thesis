FROM rocker/r-apt:bionic
LABEL maintainer="o2r"
# CRAN packages skipped because they are in the base image: lattice
RUN ["install2.r", "permute", "vegan"]
WORKDIR /payload/
CMD ["R"]