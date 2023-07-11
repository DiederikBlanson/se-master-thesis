FROM rver-base

USER root 

RUN install2.r --error \ 
	ggplot2
RUN strip /usr/local/lib/R/site-library/*/libs/*.so 

RUN mkdir -p /app 
COPY myScript-improved.R /app/ 

