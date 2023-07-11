# Set working directory such that it matches the Docker container
setwd("/app")

require('vegan')
require('fields')
#datain is the input file 
#clusterin one or more among country,locality,year,month,day,parenteventid,eventid
#taxlev one among scientificname,phylum,class,order,family,genus
#paramin one among totalbiovolume,totalcarboncontent,density
#analysis one among rarefaction,nmds,cluster,betadiversity,distance
#cexin numeric
#displayin  one or both between site and species, default both, relevant if analysis = nmds or cluster
#type one among ('t','p')
#method one among c("manhattan","euclidean","canberra","clark","bray","kulczynski","jaccard","gower","altGower","morisita","horn", "mountford", "raup", "binomial", "chao", "cao", "mahalanobis", "chisq","chord") relevant in analysis = cluster

datain <- 'TraitsOutput_Advanced_Progetto_Strategico_Australia.csv'
clusterin <- c('country','locality','year','month','day','parenteventid','eventid')
#clusterin <- "WHOLE"
taxlev <- 'scientificname'
paramin <- 'density'
analysis <- 'nmds'
cexin <- 1
displayin <- 'site'
type <- 't'
method <- "manhattan"
  
###################################COMMUNITY MATRIX ######################################

dataset=read.csv(datain,stringsAsFactors=F,sep = ";", dec = ".")
cluster<- c(scan(text = clusterin, what = "", sep = ","))

if(!'density'%in%names(dataset))dataset$density=1
if(!'biovolume'%in%names(dataset))dataset$biovolume=NA
if(!'cellcarboncontent'%in%names(dataset))dataset$cellcarboncontent=NA
if(!'totalbiovolume'%in%names(dataset))dataset$totalbiovolume=dataset$biovolume*dataset$density
if(!'totalcarboncontent'%in%names(dataset))dataset$totalcarboncontent=dataset$cellcarboncontent*dataset$density

if(length(cluster)>1)
  ID<-apply(dataset[,cluster],1,paste,collapse='.')
if(length(cluster)==1 && cluster[1]!="WHOLE") 
  ID<-dataset[,cluster]
if(cluster[1]=="WHOLE")
  ID<-rep('all',dim(dataset)[1])  ## attenzione! vedi DataFiltering

matz<-tapply(dataset[,paramin],list(ID,dataset[,taxlev]),sum,na.rm=T)
matz[is.na(matz)]<-0

write.table(matz,paste('Matrix_test_',paramin,'.csv',sep=''),row.names=T,sep = ";",dec = ".",quote=F,col.names=NA)  

###########################################COMMUNITY ANALYSIS##############################################
dataset<- matz  

display<- c(scan(text = displayin, what = "", sep = ","))
cex= as.numeric(cexin)

file_graph=paste('CommunityAnalysis_',analysis,'_','.pdf',sep='')
pdf(file_graph)

#####PLOT####
if(analysis=='rarefaction') {
  rarecurve(round(dataset),step=1000,cex=cex,col=4)
  #rarecurve(round(dataset),step=1000,cex=cex,col=4,xlim=c(0,5000))
}

if(analysis=='nmds'){
  mm=metaMDS(dataset)
  plot(mm,display=c(display),cex=cex,type=type)
}

if(analysis=='cluster'){
  if(display[1]=='site') mm=vegdist(dataset,method=method)
  if(display[1]=='species') mm=vegdist(t(dataset),method=method)
  plot(hclust(mm),cex=cex)
}

if(analysis=='betadiversity'){
  mm=betadiver(dataset)
  plot(mm,cex=cex)
}

if(analysis=='distance'){
  if(display[1]=='site') mm=as.matrix(vegdist(dataset,method=method))
  if(display[1]=='species') mm=as.matrix(vegdist(t(dataset),method=method))
  mm=mm[order(apply(mm,1,sum)),order(apply(mm,1,sum))]
  par(mar=c(7,7,3,3))
  image.plot(mm,cex=cex,col=rev(heat.colors(10)),xaxt='n',yaxt='n',main=paste(method,'distance'))
  axis(1,at=(1:dim(mm)[1])/dim(mm)[1],labels=rownames(mm),las=2,cex.axis=cex)
  axis(2,at=(1:dim(mm)[1])/dim(mm)[1],labels=rownames(mm),las=2,cex.axis=cex)
}

