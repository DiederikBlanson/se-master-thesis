FROM rocker/r-apt:bionic
LABEL maintainer="o2r"
RUN ["install2.r", "dplyr", "reshape"]
WORKDIR /payload/
CMD ["R"]