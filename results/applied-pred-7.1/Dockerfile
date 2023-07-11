FROM rapt-base

USER root 

RUN apt-get install -y -qq r-cran-caret 
RUN apt-get install -y -qq r-cran-ggplot2 
RUN apt-get install -y -qq r-cran-kernlab 

RUN mkdir -p /app 
COPY myScript-improved.R /app/ 

