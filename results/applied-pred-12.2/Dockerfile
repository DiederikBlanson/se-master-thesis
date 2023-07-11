FROM jupyr-base

USER root 

RUN R -e "install.packages('AppliedPredictiveModeling', repos='http://cran.rstudio.com/')"
RUN apt-get install -y -qq r-cran-pamr 
RUN apt-get install -y -qq r-cran-sparselda 

RUN mkdir -p /app 
COPY myScript-improved.R /app/ 

