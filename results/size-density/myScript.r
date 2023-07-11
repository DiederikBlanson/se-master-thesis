
require(reshape)
require(dplyr)

### DESCRIPTION ###
# Script to calculate and describe the relationships between size 
# (average biovolume or average carbon content) and density for any given combination 
# of spatial, temporal and taxonomic level of observations.
# OUTPUT: .zip file containing:
# a summary table in .csv format with the values of density, average biovolume and carbon content 
# according to the taxonomic level and the selected cluster;
# a summary table in .csv format with the result of the distribution linear model;
# a scatter plot with the trend power law (y = k X^a) and confidence interval 0.95

### INPUT VARIABLES ###
# datain: the input file 
# clusterin: one or more among country,locality,year,month,day,parenteventid,eventid
# taxlev: one among scientificname,phylum,class,order,family,genus
# paramin: one among biovolume,cellcarboncontent


datain <- 'TraitsOutput_Advanced_Progetto_Strategico_Australia.csv'
clusterin <- c('country','locality','year','month','day','parenteventid','eventid')
#clusterin <- 'WHOLE'
taxlev <- 'community' 
paramin <- 'biovolume'
  
  
# read the input data
dataset=read.csv(datain,stringsAsFactors=F,sep = ";", dec = ".",encoding = "UTF-8")
cluster<- c(scan(text = clusterin, what = "", sep = ","))
param <- paramin

if (taxlev!='community') {    
  if (length(unique(dataset[,taxlev]))==1) taxlev<-'community'
}

# in case the mandatory fields are not provided, the script provides an empty output
if(!'density'%in%names(dataset))dataset$density=1
if(!'biovolume'%in%names(dataset))dataset$biovolume=NA
if(!'cellcarboncontent'%in%names(dataset))dataset$cellcarboncontent=NA



if(!(taxlev=='community' & cluster[1]=='WHOLE')) {      # either taxlev or cluster, or both, are selected by the user
  
  # for the selected levels, calculate the sum of the densities and the mean of biovolume and cell carbon content
  if (taxlev!='community' & cluster[1]!='WHOLE'){
    if(length(cluster)>1){
      ID<-apply(dataset[,cluster],1,paste,collapse='.')
      info<-as.matrix(unique(dataset[,cluster]))
      rownames(info)<-apply(info,1,paste,collapse='.')
    } else if(length(cluster)==1) {
      ID<-dataset[,cluster]
      info<-as.matrix(unique(dataset[,cluster]))
      rownames(info)<-info[,1]
      colnames(info)<-cluster }
    den<-melt(tapply(dataset[,'density'],list(ID,dataset[,taxlev]),sum,na.rm=T))  # sum of the densities
    biom<-melt(tapply(dataset[,'biovolume'],list(ID,dataset[,taxlev]),mean,na.rm=T))  # average biovolume
    cc<-melt(tapply(dataset[,'cellcarboncontent'],list(ID,dataset[,taxlev]),mean,na.rm=T))  # average cell carbon content
    mat=cbind(den,biom$value,cc$value)
    if (length(cluster)>1) colnames(mat)=c('cluster',taxlev,'density','biovolume','cellcarboncontent')
    else if (length(cluster)==1) colnames(mat)=c(cluster,taxlev,'density','biovolume','cellcarboncontent')
  } else if (taxlev=='community' & cluster[1]!='WHOLE') {  
    if(length(cluster)>1){
      ID<-apply(dataset[,cluster],1,paste,collapse='.')
      info<-as.matrix(unique(dataset[,cluster]))
      rownames(info)<-apply(info,1,paste,collapse='.')
    } else if(length(cluster)==1) {
      ID<-dataset[,cluster]
      info<-as.matrix(unique(dataset[,cluster]))
      rownames(info)<-info[,1]
      colnames(info)<-cluster }
    den<-tapply(dataset[,'density'],list(ID),sum,na.rm=T)   # sum of the densities
    biom<-tapply(dataset[,'biovolume'],list(ID),mean,na.rm=T)   # average biovolume
    cc<-tapply(dataset[,'cellcarboncontent'],list(ID),mean,na.rm=T)   # average cell carbon content
    mat=cbind(den,biom,cc)
    colnames(mat)=c('density','biovolume','cellcarboncontent')
    if (dim(mat)[1]==1) {   # plot with only one point (if the selected cluster has only one value)
      xx=mat[,param]
      plot(xx,den,xlab="",ylab="")
      # title and subtitle of the graph
      if(param=='biovolume') {title(xlab=expression(paste('average biovolume (',mu,m^3,')')),line=2.5)
      } else if(param=='cellcarboncontent') title(xlab='average cell carbon content (pg C)',line=2.5)
      title(ylab=expression(paste('density (cell·',L^-1,')')),line=2.5)
      title(paste('cluster',taxlev,sep='*'), line = 2.5)
      subt <- paste('cluster: ',paste(clusterin,collapse = ', '))  
      subtitle <- paste(strwrap(subt,width=50),collapse="\n")
      mtext(line = 0.5, subtitle)
      # export cvs
      mat <- cbind(rownames(mat), data.frame(mat, row.names=NULL))
      colnames(mat)=c('density','average biovolume','average cell carbon content')
      final<-cbind(info,mat)
      write.table(final,paste('sizedensity_DATA_','.csv',sep=''),row.names=F,sep = ";",dec = ".",quote=F)
    }
  } else if (taxlev!='community' & cluster[1]=='WHOLE') {     
    den<-tapply(dataset[,'density'],list(dataset[,taxlev]),sum,na.rm=T)   # sum of the densities
    biom<-tapply(dataset[,'biovolume'],list(dataset[,taxlev]),mean,na.rm=T)   # average biovolume
    cc<-tapply(dataset[,'cellcarboncontent'],list(dataset[,taxlev]),mean,na.rm=T)   # average cell carbon content
    mat=cbind(den,biom,cc)
    colnames(mat)=c('density','biovolume','cellcarboncontent')   
  }
  
  if (dim(mat)[1]>1) {
    
    xx=mat[,param]
    
    # fit the regression model
    mod=lm(log(density)~log(xx),data=data.frame(mat))
    rr=summary(mod)[[4]]
    rr=cbind(rr,Rsquared=c(NA,summary(mod)$r.squared))
    rownames(rr)=c('Intercept',paste('log average',paramin))
    
    
    
    ########PLOT########    
    file_graph=paste('sizedensityOutput_','.pdf',sep='')
    pdf(file_graph)
    
    sq=seq(min(mat[,param],na.rm=T),max(mat[,param],na.rm=T),length.out=101)
    pr=exp(predict(mod,list(xx=sq),interval='confidence'))
    
    # subtitle of the graph
    if (cluster[1]!='WHOLE') {
      subt <- paste('cluster: ',paste(clusterin,collapse = ', '))  
      subtitle <- paste(strwrap(subt,width=50),collapse="\n")
    } else {
      subtitle <- "no temporal or spatial cluster"
    }
    par(mar = c(4,4.5,5,1.8))
    plot(density~xx,data=mat,log='xy',xlab="",ylab=expression(paste('density (cell·',L^-1,')')),
         ylim=range(c(mat[,'density'],pr),na.rm=T),xaxt="n",yaxt="n")
    
    # x and y axis ticks
    at.x <- 10^(log10(axTicks(1)))[10^(log10(axTicks(1))) %% 1 == 0]
    lab.x <- ifelse(log10(at.x) %% 1 == 0, sapply(log10(at.x),function(i) 
      as.expression(bquote(10^ .(i)))), NA)
    axis(1, at=at.x, labels=lab.x, las=1)
    at.y <- 10^(log10(axTicks(2)))[10^(log10(axTicks(2))) %% 1 == 0]
    lab.y <- ifelse(log10(at.y) %% 1 == 0, sapply(log10(at.y),function(i) 
      as.expression(bquote(10^ .(i)))), NA)
    axis(2, at=at.y, labels=lab.y, las=1)
    
    # x axis labels
    if(param=='biovolume') {title(xlab=expression(paste('average biovolume (',mu,m^3,')')),line=2.5)
    } else if(param=='cellcarboncontent') title(xlab='average cell carbon content (pg C)',line=2.5)
    
    # title
    if (cluster[1]!='WHOLE') title(paste('cluster',taxlev,sep='*'), line = 3)
    if (cluster[1]=='WHOLE') title(paste('taxonomic level: ',taxlev,sep=''), line = 3)
    mtext(line = 0.5, subtitle)
    
    # lines for the trend power law (y = k X^α) and confidence interval 0.95
    lines(sq,pr[,1],col=2,lwd=3)
    lines(sq,pr[,2],col=2,lwd=3,lty=2)
    lines(sq,pr[,3],col=2,lwd=3,lty=2)
    
    #legend
    eq=parse(text=paste(round(exp(coef(mod)[1]),2),'*M^',round(coef(mod)[2],2)))
    r2=parse(text=paste('R^2==',round(summary(mod)$r.squared,2)))
    legend('topright',legend=c(eq,r2),lty=c(1,NA),col=c(2,NA))
    
    ############
    
    
    # Write the files as CSV into working directory
    if (taxlev!='community' & cluster[1]!='WHOLE') {
      colnames(mat)=c('cluster',taxlev,'density','average biovolume','average cell carbon content')
      if (length(cluster)>1) {
        final<-cbind(info[mat$cluster,],mat)
        final <- subset(final,select = -cluster)}
      if (length(cluster)==1) {
        colnames(mat)[1]<-cluster
        final<-mat}
      final <- final[rowSums(is.na(final)) != 3,]
      final <- final %>% mutate_if(is.numeric, round, digits=2)
      write.table(final,paste('sizedensity_DATA_','.csv',sep=''),row.names=F,sep = ";",dec = ".",quote=F,fileEncoding = "latin1")  
    } else if (taxlev=='community' & cluster[1]!='WHOLE'){
      mat <- cbind(rownames(mat), data.frame(mat, row.names=NULL))
      colnames(mat)=c('cluster','density','average biovolume','average cell carbon content')
      final<-cbind(info[mat$cluster,],mat[,-1])
      if (length(cluster)==1) colnames(final)[1]<-cluster
      write.table(final,paste('sizedensity_DATA_','.csv',sep=''),row.names=F,sep = ";",dec = ".",quote=F,fileEncoding = "latin1")  
    } else if (taxlev!='community' & cluster[1]=='WHOLE') {
      mat <- cbind(rownames(mat), data.frame(round(mat,2), row.names=NULL))
      colnames(mat)=c(taxlev,'density','average biovolume','average cell carbon content')
      write.table(mat,paste('sizedensity_DATA_','.csv',sep=''),row.names=F,sep = ";",dec = ".",quote=F,fileEncoding = "latin1")  
    }  
    write.table(rr,paste('sizedensity_MODEL_LM_','.csv',sep=''),row.names=T,col.names=NA,sep = ";",dec = ".",quote=F,fileEncoding = "latin1")
    
    dev.off()
    #readBin(file_graph, "raw", n = file.info(file_graph)$size)
  }
  
} else {          # no taxlev and no cluster are selcted by the user: only one point on the graph and no regression model
  
  # calculate the sum of the densities, and the mean of biovolume and cell carbon content, on the whole dataset
  den<-sum(dataset[,'density'],na.rm=T)
  biom<-round(mean(dataset[,'biovolume'],na.rm=T),2)
  cc<-round(mean(dataset[,'cellcarboncontent'],na.rm=T),2)
  mat=c(den,biom,cc)
  names(mat)=c('density','biovolume','cellcarboncontent')
  xx=mat[param]
  
  
  
  ########PLOT######## 
  file_graph=paste('sizedensityOutput_','.pdf',sep='')
  pdf(file_graph)
  
  plot(xx,den,xlab="",ylab="",main="Whole dataset")
  if(param=='biovolume') {title(xlab=expression(paste('average biovolume (',mu,m^3,')')),line=2.5)
  } else if(param=='cellcarboncontent') title(xlab='average cell carbon content (pg C)',line=2.5)
  title(ylab=expression(paste('density (cell·',L^-1,')')),line=2.5)
  
  ###########
  
  # Write the data file as CSV into working directory
  names(mat)=c('density','average biovolume','average cell carbon content')
  write.table(mat,paste('sizedensity_DATA_','.csv',sep=''),row.names=T,col.names=F,sep = ";",dec = ".",quote=F,fileEncoding = "latin1")
  
  dev.off()

}

