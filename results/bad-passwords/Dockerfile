FROM rapt-base

USER root 

RUN apt-get install -y -qq r-cran-tidyverse 

RUN mkdir -p /app 
COPY myScript-improved.R /app/ 

