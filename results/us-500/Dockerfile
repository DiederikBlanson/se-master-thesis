FROM rapt-base

USER root 

RUN R -e "install.packages('dplyr', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('forcats', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('ggplot2', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('readr', repos='http://cran.rstudio.com/')"

RUN mkdir -p /app 
COPY myScript-improved.R /app/ 

