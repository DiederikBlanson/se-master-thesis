library(liftr)
lift("/Users/diederik/Desktop/master-thesis/tools/liftr/us-500/demo.Rmd")

start <- Sys.time()
render_docker("/Users/diederik/Desktop/master-thesis/tools/liftr/us-500/demo.Rmd")
print( Sys.time() - start )

time docker build --no-cache -t liftr-us-500 -f Dockerfile .