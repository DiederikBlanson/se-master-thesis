FROM rocker/r-apt:bionic
LABEL maintainer="o2r"
RUN ["install2.r", "dplyr", "forcats", "ggplot2", "readr"]
WORKDIR /payload/
CMD ["R"]