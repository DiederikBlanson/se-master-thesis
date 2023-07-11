MPI_fun<-function(x,datas=dataz,chla='chlacontent',lagoon=lagoon_typology){
  datax<-datas[x,]
  datazz=datax  
  tr=unique(datazz[,c('scientificname','Taxonomic.rank')])
  if(!is.null(dim(datazz))&dim(datazz)[1]>10){ 
    countz<-tapply(datazz$density[datazz$Taxonomic.rank==1],datazz$scientificname[datazz$Taxonomic.rank==1],sum) 
	
    H<-((max(countz,na.rm=T)+max(countz[-which.max(countz)],na.rm=T))/sum(countz,na.rm=T))*100
    
    
    yearz=unique(datazz$year)
    eventidz=unique(datazz$parenteventid)
    FiFi=datas[datas$year==yearz&datas$parenteventid==eventidz,]
    dates=paste(FiFi$month,FiFi$year,sep='.')
    
    Fi_fun<-function(z){
      countz=tapply(FiFi[z,'density'],(FiFi[z,'scientificname']),sum)
      frq=max(countz,na.rm=T)/sum(countz,na.rm=T)
      frq
    }
    
    Fi=tapply(1:dim(FiFi)[1],dates,Fi_fun)
    Fi=length(Fi[Fi>.5])/length(Fi)
    
    det=table(datazz$Taxonomic.rank)
    det=det[1]/sum(det)
    M<-(length(countz[countz>0])/sqrt(sum(countz[countz>0],na.rm=T)))*det
    
    chl=datazz[,chla]
    chl_mean = geometric.mean(chl)
    
    refval=cbind(open=c(50,80,.007,.8),confined=c(50,80,.012,1))
    rownames(refval)=c('H','Fi','M','CHL')
    refvalz=refval[,lagoon]
    H<-H/refvalz['H']
    M<-M/refvalz['M']
    Fi<-Fi/refvalz['Fi']
    CHL=chl_mean/refvalz['CHL']
    
    out<-mean(c(H,M,Fi,CHL),na.rm=T)
  }
  else out<-NA
  
  return(out)
}


ISS_fun<-function(x,datas=dataz,species='scientificname',size='carboncontent',chla='chlacontent'){
  data<-datas[x,]
  data$log2size<-log(data[,size],2)
  ww<-vector(length=dim(data)[1])
  ww[data$log2size<(-2)]<-3
  ww[data$log2size>=-2&data$log2size<1]<-1  
  ww[data$log2size>=1&data$log2size<4]<-2  
  ww[data$log2size>=4&data$log2size<7]<-4  
  ww[data$log2size>=7&data$log2size<10]<-5  
  ww[data$log2size>=10]<-6  
  data$ww<-ww
  #xx<-as.numeric(as.character(cut(zz,breaks=c(-2,1,4,7,10,13,1000),labels=c(3,1,2,4,5,6))))
  tt<-table(data$ww)
  ttz<-tt/sum(tt)

  nspec<-length(unique(data[,species]))   
  if(nspec>=9) nn<-1
  if(nspec<9&nspec>=5) nn<-.8
  if(nspec<5&nspec>=4) nn<-.6
  if(nspec<4&nspec>=3) nn<-.4
  if(nspec<3) nn<-.2

  chl<-mean(data[,chla],na.rm=T)
  if(!is.na(chl)){
   if(chl<=9.9) chlz<-1
   if(chl>9.9&chl<=12.8) chlz<-.8
   if(chl>12.8&chl<=39.9) chlz<-.6
   if(chl>39.9&chl<=106) chlz<-.4
   if(chl>106) chlz<-.2
   
   out<-sum(ttz*as.numeric(names(ttz)))*chlz*nn
  }
  else out<-NA
  return(out)
}

#########################################
RAT_DIA_DIN_fun<-function(x,datas){
  tt<-tapply(datas[x,'carboncontent'],list(datas$phylum[x]),sum,na.rm=T)
  tt<-tt['Bacillariophyta']/tt['Myzozoa']
  return(tt)
}
#########################################
modefun<-function(k){
  xx<-k[!is.na(k)]
  a<-density(xx)
  return(a$x[which.max(a$y)]) 
}  

#########################################
index_fun<-list(
  ##taxonomic  
  R=function(x)length(x[x>0]),
  Shannon_H=function(x)diversity(x),
  Shannon_H_Eq=function(x)exp(diversity(x)),
  Simpson_D=function(x)diversity(x,index='simpson'),
  Simpson_D_Eq=function(x)1/diversity(x,index='simpson'),
  Menhinick_D=function(x)length(x[x>0])/sqrt(sum(x,na.rm=T)),
  Margalef_D=function(x)(length(x[x>0])-1)/log(sum(x,na.rm=T)),
  Gleason_D=function(x)length(x[x>0])/log(sum(x)),
  McInthosh_M=function(x)(sum(x)+sqrt(sum(x^2)))/(sum(x)+sqrt(sum(x))),
  Hurlbert_PIE=function(x)(length(x[x>0])/(length(x[x>0])-1))*(1-sum((x/sum(x))^2)),
  #eveness/dominance
  Pielou_J=function(x)diversity(x[!is.na(x)])/log(specnumber(x[!is.na(x)])),
  Sheldon_J=function(x)exp(diversity(x[!is.na(x)]))/specnumber(x[!is.na(x)]),
  LudwReyn_J=function(x)(exp(diversity(x[!is.na(x)]))-1)/(specnumber(x[!is.na(x)])-1),
  BergerParker_B=function(x)max(x,na.rm=T)/sum(x,na.rm=T),
  McNaughton_Alpha=function(x)(max(x,na.rm=T)+max(x[-which.max(x)],na.rm=T))/sum(x,na.rm=T),
  Hulburt=function(x)((max(x,na.rm=T)+max(x[-which.max(x)],na.rm=T))/sum(x,na.rm=T))*100,
  #size
  Biovolume_mean=function(x,datas)mean(datas[x,'biovolume'],na.rm=T),  
  Biovolume_sd=function(x,datas)sd(datas[x,'biovolume'],na.rm=T),
  Biovolume_quantile_05=function(x,datas)quantile(datas[x,'biovolume'],.05,na.rm=T),
  Biovolume_quantile_10=function(x,datas)quantile(datas[x,'biovolume'],.1,na.rm=T),
  Biovolume_quantile_25=function(x,datas)quantile(datas[x,'biovolume'],.25,na.rm=T),
  Biovolume_median=function(x,datas)median(datas[x,'biovolume'],na.rm=T),
  Biovolume_quantile_75=function(x,datas)quantile(datas[x,'biovolume'],.75,na.rm=T),
  Biovolume_quantile_90=function(x,datas)quantile(datas[x,'biovolume'],.9,na.rm=T),
  Biovolume_quantile_95=function(x,datas)quantile(datas[x,'biovolume'],.95,na.rm=T),
  Biovolume_interquartile_range=function(x,datas)quantile(datas[x,'biovolume'],.75,na.rm=T)-quantile(datas[x,'biovolume'],.25,na.rm=T),
  Biovolume_interdecile_range=function(x,datas)quantile(datas[x,'biovolume'],.9,na.rm=T)-quantile(datas[x,'biovolume'],.1,na.rm=T),
  Biomass_mean=function(x,datas)mean(datas[x,'carboncontent'],na.rm=T),
  Biomass_sd=function(x,datas)sd(datas[x,'carboncontent'],na.rm=T),
  Biomass_quantile_05=function(x,datas)quantile(datas[x,'carboncontent'],.05,na.rm=T),
  Biomass_quantile_10=function(x,datas)quantile(datas[x,'carboncontent'],.1,na.rm=T),
  Biomass_quantile_25=function(x,datas)quantile(datas[x,'carboncontent'],.25,na.rm=T),
  Biomass_median=function(x,datas)median(datas[x,'carboncontent'],na.rm=T),
  Biomass_quantile_75=function(x,datas)quantile(datas[x,'carboncontent'],.75,na.rm=T),
  Biomass_quantile_90=function(x,datas)quantile(datas[x,'carboncontent'],.9,na.rm=T),
  Biomass_quantile_95=function(x,datas)quantile(datas[x,'carboncontent'],.95,na.rm=T),
  Biomass_interquartile_range=function(x,datas)quantile(datas[x,'carboncontent'],.75,na.rm=T)-quantile(datas[x,'biovolume'],.25,na.rm=T),
  Biomass_interdecile_range=function(x,datas)quantile(datas[x,'carboncontent'],.9,na.rm=T)-quantile(datas[x,'biovolume'],.1,na.rm=T),
  #ecological_status
  ISS_phyto=ISS_fun,
  Ratio_DIA.DINO=RAT_DIA_DIN_fun
  #MPI=MPI_fun 
)

comm_mat<-c("R","Shannon_H","Shannon_H_Eq","Simpson_D","Simpson_D_Eq","Menhinick_D",
  "Margalef_D","Gleason_D","McInthosh_M","Hurlbert_PIE",
  "Pielou_J","Sheldon_J","LudwReyn_J","BergerParker_B",
  "McNaughton_Alpha","Hulburt")
