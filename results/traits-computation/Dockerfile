FROM rapt-base

USER root 

RUN R -e "install.packages('NCmisc', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('optparse', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('jsonlite', repos='http://cran.rstudio.com/')"

RUN mkdir -p /app 
COPY myScript-improved.R /app/ 

