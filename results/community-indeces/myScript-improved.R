# Set working directory such that it matches the Docker container
setwd("/app")


require('vegan')

#datain is the input file 
#clusterin one or more among country,locality,year,month,day,parenteventid,eventid
#index one or more among index_list

source('1_INDEX_LIST.R')


datain <- 'TraitsOutput_Advanced_Progetto_Strategico_Australia.csv'
clusterin <- c('country','locality','year','month','day','parenteventid','eventid')
#clusterin <- "WHOLE"
index = c("R","Shannon_H","Shannon_H_Eq","Simpson_D","Simpson_D_Eq","Menhinick_D",
          "Margalef_D","Gleason_D","McInthosh_M","Hurlbert_PIE",
          "Pielou_J","Sheldon_J","LudwReyn_J","BergerParker_B",
          "McNaughton_Alpha","Hulburt")
  
dataset=read.csv(datain,stringsAsFactors=F,sep = ";", dec = ".")
cluster<- c(scan(text = clusterin, what = "", sep = ","))

index_fun2<-index_fun[c(scan(text = index, what = "", sep = ","))]

index_list<-list()
length(index_list)<-length(index_fun2)
names(index_list)<-names(index_fun2)


if(!'density'%in%names(dataset))dataset$density=1
if(!'biovolume'%in%names(dataset))dataset$biovolume=NA
if(!'cellcarboncontent'%in%names(dataset))dataset$cellcarboncontent=NA

if(length(cluster)>1) {
  ID<-apply(dataset[,cluster],1,paste,collapse='.')
  info<-as.matrix(unique(dataset[,cluster]))
  rownames(info)<-apply(info,1,paste,collapse='.')
  subt <- paste('cluster: ',paste(clusterin,collapse = ', '))  
  subtitle <- paste(strwrap(subt,width=50),collapse="\n")
} else if(length(cluster)==1 && cluster[1]!="WHOLE") {
  ID<-dataset[,cluster]
  info<-as.matrix(unique(dataset[,cluster]))
  rownames(info)<-info[,1]
  colnames(info)<-cluster
  subt <- paste('cluster: ',clusterin)  
  subtitle <- paste(strwrap(subt,width=50),collapse="\n")
} else if(cluster[1]=="WHOLE") {
  ID<-rep('all',dim(dataset)[1]) }

if (length(unique(ID))>1) {
  file_graph=paste('Index_Graph_test','.pdf',sep='')
  pdf(file_graph)
}

for(i in 1:length(index_fun2)){
  funz<-index_fun2[[i]]
  den_matz<-tapply(dataset[,'density'],list(ID,dataset$scientificname),sum,na.rm=T)
  den_matz[is.na(den_matz)]<-0
  index_list[[i]]<-apply(den_matz,1,funz)
  
  #####PLOT####
  if(length(index_list[[i]][!is.na(index_list[[i]])])>1){
    par(las=2,mar = c(5.2,4.6,3.5,1.8))
    ttxx=index_list[[i]][!is.na(index_list[[i]])]
    ttxx=ttxx[ttxx!=Inf]
    if (max(nchar(ID))<10) {
    barplot(ttxx,main=names(index_list)[i],ylab='value',ylim=range(pretty(c(0,ttxx))))
    } else {
      barplot(ttxx,main=names(index_list)[i],ylab='value',ylim=range(pretty(c(0,ttxx))),
              names.arg=paste("Cluster",1:length(names(index_list[[i]]))))
    }
    mtext(line = -0.7,subtitle,las=1)
  }
  #############
}

ind<-do.call('cbind',index_list)
if (cluster[1]=="WHOLE") {final<-ind
} else {
  if (length(unique(ID))>1) final<-cbind(info[rownames(ind),],round(ind,3))
  if (length(unique(ID))==1) final<-cbind(info,round(ind,3))
  if(length(cluster)==1) colnames(final)[1]<-cluster
}

if (length(unique(ID))>1) dev.off()


if (max(nchar(ID))>10) {
  cl.legend<-final[,cluster]
  rownames(cl.legend)<-paste("Cluster",1:length(names(index_list[[i]])))
  write.table(cl.legend,paste('Index_Cluster_Legend','.csv',sep=''),row.names=T,
              sep = ";",dec = ".",quote=F,col.names=NA)
}

write.table(final,paste('Index_Output_test','.csv',sep=''),row.names=F,sep = ";",dec = ".",quote=F)
