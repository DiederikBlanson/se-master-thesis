FROM rver-base

USER root 

RUN install2.r --error \ 
	AppliedPredictiveModeling \
	caret \
	elasticnet \
	lars \
	pls \
	glmnet
RUN strip /usr/local/lib/R/site-library/*/libs/*.so 

RUN mkdir -p /app 
COPY myScript-improved.R /app/ 

