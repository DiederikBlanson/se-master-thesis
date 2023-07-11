FROM rver-base

USER root 

RUN R -e "install.packages('dplyr', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('ggplot2', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('ggrepel', repos='http://cran.rstudio.com/')"
RUN R -e "if (!requireNamespace('remotes', quietly = TRUE)) install.packages('remotes') "
RUN R -e "remotes::install_github('aldomann/mariokart')"

RUN mkdir -p /app 
COPY myScript-improved.R /app/ 

