FROM rocker/r-ver:4.1.1
LABEL maintainer="o2r"
RUN ["install2.r", "AppliedPredictiveModeling", "caret", "elasticnet", "ggplot2", "lars", "lattice", "MASS", "pls"]
WORKDIR /payload/
CMD ["R"]