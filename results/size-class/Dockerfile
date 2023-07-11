FROM rapt-base

USER root 

RUN apt-get install -y -qq r-cran-dplyr 
RUN apt-get install -y -qq r-cran-stringr 

RUN mkdir -p /app 
COPY myScript-improved.R /app/ 

