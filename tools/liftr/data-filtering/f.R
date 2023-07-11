library(liftr)
lift("/Users/diederik/Desktop/master-thesis/tools/liftr/data-filtering/demo.Rmd")

start <- Sys.time()
render_docker("/Users/diederik/Desktop/master-thesis/tools/liftr/data-filtering/demo.Rmd")
print( Sys.time() - start )

time docker build --no-cache -t liftr-data-filtering -f Dockerfile .