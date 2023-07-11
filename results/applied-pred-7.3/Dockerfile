FROM rver-base

USER root 

RUN R -e "install.packages('caret', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('doParallel', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('earth', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('mlbench', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('pls', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('glmnet', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('Rcpp', repos='http://cran.rstudio.com/')"

RUN mkdir -p /app 
COPY myScript-improved.R /app/ 

