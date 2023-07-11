FROM jupyr-base

USER root 

RUN R -e "if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager', repos='http://cran.rstudio.com/') "
RUN R -e "BiocManager::install('DESeq2')"

RUN mkdir -p /app 
COPY myScript-improved.R /app/ 

