Rscript -e "cran_mirror <- 'https://cloud.r-project.org/';
            options(repos = list(CRAN = cran_mirror));
            install.packages('renv')"