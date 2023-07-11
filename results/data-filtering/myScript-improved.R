# Set working directory such that it matches the Docker container
setwd("/app")

library(dplyr)

#datain is the input file 
#clusterin one or more among country,locality,year,month,day,parenteventid,eventid
#taxlev one among scientificname,kingdom,phylum,class,order,family,genus
#paramin one or more among totalbiovolume,totalcarboncontent,density
#thresholdin between 0 and 1

datain <- 'TraitsOutput_Advanced_Progetto_Strategico_Australia.csv'
#clusterin <- c('country','locality','year','month','day','parenteventid','eventid')
clusterin <- "WHOLE"
taxlev <- 'scientificname'
paramin <- c('density','totalbiovolume') 
#paramin<-'density'
thresholdin <- 0.75

dataset <- read.csv(datain,stringsAsFactors=F,sep = ";", dec = ".")

cluster <- c(scan(text = clusterin, what = "", sep = ","))

param <- c(scan(text = paramin, what = "", sep = ","))

#sostituzione eventuali virgole con il punto decimale
threshold <- as.numeric(gsub("[,]", ".", thresholdin))

if(!'density'%in%names(dataset))dataset$density=1
if(!'biovolume'%in%names(dataset))dataset$biovolume=1
if(!'cellcarboncontent'%in%names(dataset))dataset$cellcarboncontent=1

if(!'totalbiovolume'%in%names(dataset))dataset$totalbiovolume=dataset$biovolume*dataset$density
if(!'totalcarboncontent'%in%names(dataset))dataset$totalcarboncontent=dataset$cellcarboncontent*dataset$density

if(cluster[1]!="WHOLE") {
  if(length(cluster)>1) ID<-apply(dataset[,cluster],1,paste,collapse='.')
  if(length(cluster)==1) ID<-dataset[,cluster]
} else if(cluster[1]=="WHOLE") {
  ID<-rep('all',dim(dataset)[1]) }

if ('density' %in% param) {
  
  IDZ<-unique(ID)  
  IDLIST<-list()
  length(IDLIST)<-length(IDZ)
  names(IDLIST)<-IDZ
  
  # ranked distribution of the taxa
  for(j in 1:length(IDZ)){
    ddd<-dataset[ID==IDZ[j],]
    totz<-sum(ddd[,'density'],na.rm=T)
    matz<-tapply(ddd[,'density'],ddd[,taxlev],function(x)sum(x,na.rm=T)/totz)
    matz<-sort(matz,decreasing=T) 
    
    # cumulative contribution to the overall density
    k<-2
    trs<-max(matz)
    while (trs<threshold) {
      matz[k]<-matz[k-1]+matz[k]
      trs<-matz[k]
      k<-k+1 }
    
    matzx<-matz[1:k-1]
    
    IDLIST[[j]] <- ddd[ddd[,taxlev]%in%names(matzx),]
  }
  
  # filtered dataset for density
  dataset.d <- do.call('rbind',IDLIST)
  
} else dataset.d <- dataset[FALSE,]

if ('totalbiovolume' %in% param) {
  
  IDZ<-unique(ID)  
  IDLIST<-list()
  length(IDLIST)<-length(IDZ)
  names(IDLIST)<-IDZ
  
  # ranked distribution of the taxa
  for(j in 1:length(IDZ)){
    ddd<-dataset[ID==IDZ[j],]
    totz<-sum(ddd[,'totalbiovolume'],na.rm=T)
    matz<-tapply(ddd[,'totalbiovolume'],ddd[,taxlev],function(x)sum(x,na.rm=T)/totz)
    matz<-sort(matz,decreasing=T) 
    
    # cumulative contribution to the overall total biovolume
    k<-2
    trs<-max(matz)
    while (trs<threshold) {
      matz[k]<-matz[k-1]+matz[k]
      trs<-matz[k]
      k<-k+1 }
    
    matzx<-matz[1:k-1]
    
    IDLIST[[j]] <- ddd[ddd[,taxlev]%in%names(matzx),]
  }
  
  # filtered dataset for total biovolume
  dataset.b <- do.call('rbind',IDLIST)
  
} else dataset.b <- dataset[FALSE,]

if ('totalcarboncontent' %in% param) {
  
  IDZ<-unique(ID)  
  IDLIST<-list()
  length(IDLIST)<-length(IDZ)
  names(IDLIST)<-IDZ
  
  # ranked distribution of the taxa
  for(j in 1:length(IDZ)){
    ddd<-dataset[ID==IDZ[j],]
    totz<-sum(ddd[,'totalcarboncontent'],na.rm=T)
    matz<-tapply(ddd[,'totalcarboncontent'],ddd[,taxlev],function(x)sum(x,na.rm=T)/totz)
    matz<-sort(matz,decreasing=T) 
    
    # cumulative contribution to the overall total cell carbon content
    k<-2
    trs<-max(matz)
    while (trs<threshold) {
      matz[k]<-matz[k-1]+matz[k]
      trs<-matz[k]
      k<-k+1 }
    
    matzx<-matz[1:k-1]
    
    IDLIST[[j]] <- ddd[ddd[,taxlev]%in%names(matzx),]
  }
  
  # filtered dataset for total cell carbon content
  dataset.c <- do.call('rbind',IDLIST)
  
} else dataset.c <- dataset[FALSE,]

# merge the datasets
dtc=as.data.frame(bind_rows(dataset.d,dataset.b,dataset.c))
# eliminate duplicated rows
dataset=unique(dtc)

# add the threshold value in the title of the output file
threshold.str <- paste('_ThresholdValue_',threshold,sep="")   

# write the output as csv file
write.table(dataset,paste('FilteringOutput_',threshold.str,'.csv',sep=''),row.names=F,
            sep = ";",dec = ".",quote=F)

