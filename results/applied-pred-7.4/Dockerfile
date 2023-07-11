FROM rapt-base

USER root 

RUN R -e "install.packages('AppliedPredictiveModeling', repos='http://cran.rstudio.com/')"
RUN apt-get install -y -qq r-cran-caret 
RUN apt-get install -y -qq r-cran-doparallel 
RUN apt-get install -y -qq r-cran-earth 
RUN apt-get install -y -qq r-cran-elasticnet 
RUN apt-get install -y -qq r-cran-lars 
RUN apt-get install -y -qq r-cran-mlbench 
RUN apt-get install -y -qq r-cran-pls 
RUN apt-get install -y -qq r-cran-glmnet 

RUN mkdir -p /app 
COPY myScript-improved.R /app/ 

