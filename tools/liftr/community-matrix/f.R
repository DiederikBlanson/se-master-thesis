library(liftr)
lift("/Users/diederik/Desktop/master-thesis/tools/liftr/community-matrix/demo.Rmd")

start <- Sys.time()
render_docker("/Users/diederik/Desktop/master-thesis/tools/liftr/community-matrix/demo.Rmd")
print( Sys.time() - start )

time docker build --no-cache -t liftr-community-indeces -f Dockerfile .