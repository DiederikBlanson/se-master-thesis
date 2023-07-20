docker pull rocker/r-apt:bionic
docker pull jupyter/r-notebook:70178b8e48d7
docker pull rocker/r-ver:4.1.1

docker build -t jupyr-base -f Dockerfile.jupyr-base .
docker build -t ncmisc-base -f Dockerfile.ncmisc-base .
docker build -t rapt-base -f Dockerfile.rapt-base .
docker build -t rver-base -f Dockerfile.rver-base .