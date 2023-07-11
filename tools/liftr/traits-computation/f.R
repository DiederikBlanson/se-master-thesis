library(liftr)
lift("/Users/diederik/Desktop/master-thesis/tools/liftr/traits-computation/demo.Rmd")

start <- Sys.time()
render_docker("/Users/diederik/Desktop/master-thesis/tools/liftr/traits-computation/demo.Rmd")
print( Sys.time() - start )

time docker build --no-cache -t liftr-traits-computation -f Dockerfile .