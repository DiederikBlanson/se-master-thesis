FROM rocker/r-apt:bionic
LABEL maintainer="o2r"
RUN ["install2.r", "dplyr", "ggplot2", "remotes"]
RUN ["installGithub.r", "aldomann/mariokart@04dd17aef00b4f3c6d2f41c2fae6bc2d785dc3aa"]
WORKDIR /payload/
CMD ["R"]