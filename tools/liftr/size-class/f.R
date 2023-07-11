library(liftr)
lift("/Users/diederik/Desktop/master-thesis/tools/liftr/size-class/demo.Rmd")

start <- Sys.time()
render_docker("/Users/diederik/Desktop/master-thesis/tools/liftr/size-class/demo.Rmd")
print( Sys.time() - start )

time docker build --no-cache -t liftr-size-class -f Dockerfile .