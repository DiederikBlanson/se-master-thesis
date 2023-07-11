
require(dplyr)    
require(stringr)

### DESCRIPTION ###
# Script to visualize the distribution of phytoplankton in different size classes 
# selected on the basis of logarithmic values of biovolume or carbon content.
# OUTPUT: .zip file containing a summary table in .csv format and one or more 
# bar plots according to the selected clusters in .pdf format
# if no selection of the spatial and temporal level is made, the analysis runs on the whole dataset

### INPUT VARIABLES ###
# datain: the input file 
# SizeUnit: one among biovolume or cellcarboncontent
# clusterin: one or more among country,locality,year,month,day,parenteventid,eventid
# basein: one numeric value among 2, e, 10 (2 as default)

datain <- 'Phytoplankton__Progetto_Strategico_2009_2012_Australia.csv'
SizeUnit <- 'biovolume'
clusterin <- c('country','locality','year','month','day','parenteventid','eventid')
#clusterin <- "WHOLE"
basein <- 2


dataset <- read.csv(datain,stringsAsFactors=F,sep = ";", dec = ".",encoding = "UTF-8")
cluster <- c(scan(text = clusterin, what = "", sep = ","))
base <- as.numeric(basein)

if(SizeUnit=='biovolume') {
  var<-dataset$biovolume[!is.na(dataset$biovolume)]   # use the biovolume values
  if (base==2 || base==10) {xlabz<-bquote(paste('log'[.(base)]*' biovolume (',mu,m^3,')'))   # x label for the graphs
  } else {xlabz<-bquote(paste('ln biovolume (',mu,m^3,')'))}
} else if (SizeUnit=='cellcarboncontent'){
  var<-dataset$cellcarboncontent[!is.na(dataset$cellcarboncontent)]   # use the carbon content values
  if (base==2 || base==10) {xlabz<-bquote(paste('log'[.(base)]*' cell carbon content (pg C)'))         # x label for the graphs
  } else {xlabz<-'ln cell carbon content (pg C)'}
}


if (cluster[1]=="WHOLE") {      # if no temporal/spatial selection, no clusterization (the whole dataset is used)
  
  logvar=round(log(var,base=base))    # logarithmic value of biovolume/carbon content
  ttz=table(logvar)                   # frequency table
  
  # plot and export the graph as pdf
  if (base==2 || base==10) {file_graph=paste('SizeClassOutput_',paste("log",base,SizeUnit,sep=""),'.pdf',sep='')  
  } else {file_graph=paste('SizeClassOutput_',paste("ln",SizeUnit,sep=""),'.pdf',sep='')}
  pdf(file_graph)
  par(mar=c(5.1,5.1,4.1,2.1))
  barplot(ttz,xlab=xlabz,ylab='N of cells',main="Whole dataset",ylim=range(pretty(c(0, ttz))))
  
  cctab<-as.data.frame(ttz)          # data to be exported in .csv (N of cells)
  colnames(cctab)=c(paste("log",base,SizeUnit),"N of cells")
  
} else {                        # if temporal/spatial selection -> clusterization
  
  if(length(cluster)>1) {
    ID<-apply(dataset[, cluster], 1, paste, collapse = '.')[!is.na(dataset$biovolume)]
    info<-as.matrix(unique(dataset[,cluster]))
    rownames(info)<-apply(info,1,paste,collapse='.')
  } else if (length(cluster) == 1) {
    ID<-dataset[, cluster][!is.na(dataset$biovolume)]
    info<-as.matrix(unique(dataset[,cluster]))
    rownames(info)<-info[,1]
    colnames(info)<-cluster }
  
  
  subt <- paste('cluster: ',paste(clusterin,collapse = ', '))  
  subtitle <- paste(strwrap(subt,width=50),collapse="\n")       # subtitle with the spatial and temporal levels 
  
  # function to plot the size class distribution for each cluster
  ccfun<-function(x, mainz, xlb,subtitle) {            
    logvar = round(log(var[x], base = base))
    ttz = table(factor(logvar,levels=min(logvar,na.rm=T):max(logvar,na.rm=T)))
    par(mar=c(7,5.1,4.1,2.1))
    barplot(ttz,xlab=xlb,ylab='N of cells',main=paste(strwrap(mainz,width=50),collapse="\n"),ylim=range(pretty(c(0,ttz))))
    mtext(subtitle,side=1,line=5.5,cex=0.9)
    return(ttz)
  }
  
  # export the graphs as pf
  if (base==2 || base==10) {file_graph=paste('SizeClassOutput_',paste("log",base,SizeUnit,sep=""),'.pdf',sep='')  
  } else {file_graph=paste('SizeClassOutput_',paste("ln",SizeUnit,sep=""),'.pdf',sep='')}
  pdf(file_graph)
  
  # create a list containing the distribution information
  idz=unique(ID)
  cclist=list()
  length(cclist)=length(idz)
  names(cclist)=idz
  for (i in 1:length(idz))
    cclist[[i]]=ccfun(var[ID == idz[i]], mainz = idz[i],xlb=xlabz,subtitle=subtitle)    # call the function for plotting
  
  # merge the information in a data frame to export to csv
  # Whit bind_rows, columns are matched by name, and any missing columns will be filled with NA    
  data_rbind <- as.data.frame(bind_rows(cclist))                  
  data_rbind <- data_rbind[ ,str_sort(names(data_rbind), numeric = TRUE)]
  # Add columns with the spatial/temporal clusters
  if (length(unique(ID))>1)final<-cbind(info[names(cclist),],data_rbind)
  if (length(unique(ID))==1) final<-cbind(info,data_rbind)
  if(length(cluster)==1)colnames(final)[1]<-cluster
  final[is.na(final)] <- 0

}

dev.off()

# export the csv table
if (base==2 || base==10) {
  write.table(final,paste('SizeClassOutput_','log',base,SizeUnit,'.csv',sep=''),row.names=F,sep = ";",dec = ".",quote=F,fileEncoding = "latin1")
} else {write.table(final,paste('SizeClassOutput_',paste("ln",SizeUnit,sep=""),'.csv',sep=''),row.names=F,sep = ";",dec = ".",quote=F,fileEncoding = "latin1")}


