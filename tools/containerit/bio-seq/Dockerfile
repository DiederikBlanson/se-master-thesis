FROM rocker/r-apt:bionic
LABEL maintainer="o2r"
RUN ["install2.r", "matrixStats"]
RUN ["install2.r", "-r https://bioconductor.org/packages/3.16/bioc -r https://bioconductor.org/packages/3.16/data/annotation -r https://bioconductor.org/packages/3.16/data/experiment -r https://bioconductor.org/packages/3.16/workflows", "Biobase", "BiocGenerics", "DESeq2", "GenomeInfoDb", "GenomicRanges", "IRanges", "MatrixGenerics", "S4Vectors", "SummarizedExperiment"]
WORKDIR /payload/
CMD ["R"]