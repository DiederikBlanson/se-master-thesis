FROM ubuntu:20.04

USER root

ARG DEBIAN_FRONTEND=noninteractive

# Install Docker and necessary dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    r-base \
    && apt-get clean

# Create Docker images
# COPY standalone-images /
# RUN chmod +x /create-images.sh
# RUN /create-images.sh

# Copy requirement.txt and r.txt to the container
COPY requirements.txt /

# Install Python modules
RUN pip3 install --no-cache-dir -r /requirements.txt

# Install R packages
RUN Rscript -e "install.packages('renv')"

# Set the working directory
WORKDIR /app

COPY . . 



