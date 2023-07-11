FROM rapt-base

USER root 

RUN apt-get install -y -qq r-cran-data.table 
RUN apt-get install -y -qq r-cran-dplyr 
RUN R -e "install.packages('sentimentr', repos='http://cran.rstudio.com/')"
RUN apt-get install -y -qq r-cran-sets 
RUN apt-get install -y -qq r-cran-slam 
RUN apt-get install -y -qq r-cran-tidytext 
RUN apt-get install -y -qq r-cran-tidyverse 
RUN apt-get install -y -qq r-cran-tm 

RUN mkdir -p /app 
COPY myScript-improved.R /app/ 

