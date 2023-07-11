# Set working directory such that it matches the Docker container
setwd("/app")


datain <- 'Phytoplankton__Progetto_Strategico_2009_2012_Australia.csv'
CalcType <- 'advanced'
CompTraits <- c('biovolume','totalbiovolume','density','surfacearea','surfacevolumeratio','cellcarboncontent','totalcarboncontent')
CountingStrategy <- 'density0'

### DESCRIPTION ###
# Script to compute demographic and morphological traits such as biovolume (µm3), surface area (µm2), 
# surface/volume ratio, density (cells/L), cell carbon content (pg), total biovolume (µm³/L), 
# total carbon content (pg/L).
# OUTPUT: file in .csv format, including all input data and the new calculated traits


### INPUT VARIABLES ###
# datain: the input file 
# CalcType: the computation type simplified or advanced
# CompTraits: one or more among biovolume,totalbiovolume,density,surfacearea,surfacevolumeratio,cellcarboncontent,totalcarboncontent
# CountingStrategy: one among density0,density1,density2,density3 

  
df.datain=read.csv(datain,stringsAsFactors=F,sep = ";", dec = ".")
df.datain$measurementremarks <- tolower(df.datain$measurementremarks) # eliminate capital letters
df.datain$index <- c(1:nrow(df.datain)) # needed to restore rows order later

CalcType <- as.character(CalcType)
CompTraits <- as.list(scan(text = CompTraits, what = "", sep = ","))
CountingStrategy <- as.character(CountingStrategy)


df.operator<-read.csv('2_FILEinformativo_OPERATORE.csv',stringsAsFactors=F) ## load internal database 
df.operator[df.operator==('no')]<-NA
df.operator[df.operator==('see note')]<-NA
df.operator["missingdimensionsimplified"][df.operator["missingdimensionsimplified"] == "W"] <- "width"
df.operator["missingdimensionsimplified"][df.operator["missingdimensionsimplified"] == "L"] <- "length"
df.operator$measurementremarks <- tolower(df.operator$measurementremarks) ## eliminate capital letters

df.merged <- merge(x = df.datain, y = df.operator, by = c("scientificname","measurementremarks"), all.x = TRUE)

if(!'diameterofsedimentationchamber'%in%names(df.merged))df.merged$diameterofsedimentationchamber=NA
if(!'diameteroffieldofview'%in%names(df.merged))df.merged$diameteroffieldofview=NA
if(!'transectcounting'%in%names(df.merged))df.merged$transectcounting=NA
if(!'numberofcountedfields'%in%names(df.merged))df.merged$numberofcountedfields=df.merged$transectcounting
if(!'numberoftransects'%in%names(df.merged))df.merged$numberoftransects==df.merged$transectcounting
if(!'settlingvolume'%in%names(df.merged))df.merged$settlingvolume=NA
if(!'dilutionfactor'%in%names(df.merged))df.merged$dilutionfactor=1


if(CalcType=='advanced'){
  df.merged.concat <- df.merged[is.na(df.merged$formulaformissingdimension),]
  md.formulas <- unique(df.merged[!is.na(df.merged$formulaformissingdimension),]$formulaformissingdimension)
  for(md.form in md.formulas){
    df.temp <- subset(df.merged,formulaformissingdimension==md.form)
    for(md in unique(df.temp$missingdimension)){
      df.temp2 <- df.temp[df.temp$missingdimension==md,]
      df.temp2[[md]] <- round(with(df.temp2,eval(parse(text=md.form))),2)
      df.merged.concat <- rbind(df.merged.concat,df.temp2)
    }
  }
  df.merged.concat <- df.merged.concat[order(df.merged.concat$index),]
  df.merged <- df.merged.concat
} else if(CalcType=='simplified'){
  df.merged.concat <- df.merged[is.na(df.merged$formulaformissingdimensionsimplified),]
  md.formulas <- unique(df.merged[!is.na(df.merged$formulaformissingdimensionsimplified),]$formulaformissingdimensionsimplified)
  for(md.form in md.formulas){
    df.temp <- subset(df.merged,formulaformissingdimensionsimplified==md.form)
    for(md in unique(df.temp$missingdimensionsimplified)){
      df.temp2 <- df.temp[df.temp$missingdimensionsimplified==md,]
      df.temp2[[md]] <- round(with(df.temp2,eval(parse(text=md.form))),2)
      df.merged.concat <- rbind(df.merged.concat,df.temp2)
    }
  }
  df.merged.concat <- df.merged.concat[order(df.merged.concat$index),]
  df.merged <- df.merged.concat
}

if('biovolume'%in%CompTraits){
  if('biovolume'%in%names(df.datain)) df.datain<-subset(df.datain,select=-biovolume) # drop column if already present
  if(CalcType=='advanced'){
    df.merged$biovolume <- rep(NA,length=nrow(df.merged))
    df.merged.concat <- df.merged[is.na(df.merged$formulaforbiovolume),]
    bv.formulas <- unique(df.merged[!is.na(df.merged$formulaforbiovolume),]$formulaforbiovolume)
    for(bv.form in bv.formulas){
      df.temp <- subset(df.merged,formulaforbiovolume==bv.form)
      df.temp$biovolume <- round(with(df.temp,eval(parse(text=bv.form))),2)
      df.merged.concat <- rbind(df.merged.concat,df.temp)
    }
    df.merged.concat <- df.merged.concat[order(df.merged.concat$index),]
    df.merged <- df.merged.concat
    df.datain$biovolume <- df.merged$biovolume
  }
  else if(CalcType=='simplified'){
    df.merged$biovolume <- rep(NA,length=nrow(df.merged))
    df.merged.concat <- df.merged[is.na(df.merged$formulaforbiovolumesimplified),]
    bv.formulas <- unique(df.merged[!is.na(df.merged$formulaforbiovolumesimplified),]$formulaforbiovolumesimplified)
    for(bv.form in bv.formulas){
      df.temp <- subset(df.merged,formulaforbiovolumesimplified==bv.form)
      df.temp$biovolume <- round(with(df.temp,eval(parse(text=bv.form))),2)
      df.merged.concat <- rbind(df.merged.concat,df.temp)
    }
    df.merged.concat <- df.merged.concat[order(df.merged.concat$index),]
    df.merged <- df.merged.concat
    df.datain$biovolume <- df.merged$biovolume  # write column with the results at the end of the dataframe
  }
} 


if('cellcarboncontent'%in%CompTraits){
  if('cellcarboncontent'%in%names(df.datain)) df.datain<-subset(df.datain,select=-cellcarboncontent) # drop column if already present
  df.merged$cellcarboncontent <- rep(NA,length=nrow(df.merged))
  if('biovolume'%in%CompTraits){
    df.merged.concat <- df.merged[is.na(df.merged$biovolume),]
    df.cc <- df.merged[!is.na(df.merged$biovolume),]
    df.cc1 <- subset(df.cc,biovolume <= 3000)
    df.cc2 <- subset(df.cc,biovolume > 3000)
    cc.formulas1 <- unique(df.merged[!is.na(df.merged$formulaforweight1),]$formulaforweight1)
    for(cc.form in cc.formulas1){
      df.temp <- subset(df.cc1,formulaforweight1==cc.form)
      df.temp$cellcarboncontent <- round(with(df.temp,eval(parse(text=tolower(cc.form)))),2)
      df.merged.concat <- rbind(df.merged.concat,df.temp)
    }
    cc.formulas2 <- unique(df.merged[!is.na(df.merged$formulaforweight2),]$formulaforweight2)
    for(cc.form in cc.formulas2){
      df.temp <- subset(df.cc2,formulaforweight2==cc.form)
      df.temp$cellcarboncontent <- round(with(df.temp,eval(parse(text=tolower(cc.form)))),2)
      df.merged.concat <- rbind(df.merged.concat,df.temp)
    }
    df.merged.concat <- df.merged.concat[order(df.merged.concat$index),]
    df.merged <- df.merged.concat
    df.datain$cellcarboncontent <- df.merged$cellcarboncontent
  }
}

if('density'%in%CompTraits){
  df.merged$density <- rep(NA,length=nrow(df.merged))
  # default method to calculate the density
  if(CountingStrategy=='density0'){  
    df.merged.concat <- df.merged[(is.na(df.merged$volumeofsedimentationchamber)) & (is.na(df.merged$transectcounting)),]
    df.temp <- df.merged[!is.na(df.merged$volumeofsedimentationchamber) & !is.na(df.merged$transectcounting),]
    df.temp1 <- subset(df.temp,volumeofsedimentationchamber <= 5)
    df.temp1$density <- df.temp1$organismquantity/df.temp1$transectcounting*1000/0.001979
    df.merged.concat <- rbind(df.merged.concat,df.temp1)
    df.temp2 <- subset(df.temp,(volumeofsedimentationchamber > 5) & (volumeofsedimentationchamber <= 10))
    df.temp2$density <- df.temp2$organismquantity/df.temp2$transectcounting*1000/0.00365
    df.merged.concat <- rbind(df.merged.concat,df.temp2)
    df.temp3 <- subset(df.temp,(volumeofsedimentationchamber > 10) & (volumeofsedimentationchamber <= 25))
    df.temp3$density <- df.temp3$organismquantity/df.temp3$transectcounting*1000/0.010555
    df.merged.concat <- rbind(df.merged.concat,df.temp3)
    df.temp4 <- subset(df.temp,(volumeofsedimentationchamber > 25) & (volumeofsedimentationchamber <= 50))
    df.temp4$density <- df.temp4$organismquantity/df.temp4$transectcounting*1000/0.021703
    df.merged.concat <- rbind(df.merged.concat,df.temp4)
    df.temp5 <- subset(df.temp,volumeofsedimentationchamber > 50)
    df.temp5$density <- df.temp5$organismquantity/df.temp5$transectcounting*1000/0.041598
    df.merged.concat <- rbind(df.merged.concat,df.temp5)
    df.merged.concat <- df.merged.concat[order(df.merged.concat$index),]
    df.merged <- df.merged.concat
    df.datain$density <- round(df.merged$density,2)
  }
  # counts per random field
  else if(CountingStrategy=='density1'){
    df.merged$areaofsedimentationchamber <- ((df.merged$diameterofsedimentationchamber/2)^2)*pi
    df.merged$areaofcountingfield <- ((df.merged$diameteroffieldofview/2)^2)*pi
    df.merged$density <- round(df.merged$organismquantity*1000*df.merged$areaofsedimentationchamber/df.merged$numberofcountedfields*df.merged$areaofcountingfield*df.merged$settlingvolume,2)
  }
  # counts per diameter transects
  else if(CountingStrategy=='density2'){
    df.merged$density <- round(((df.merged$organismquantity/df.merged$numberoftransects)*(pi/4)*(df.merged$diameterofsedimentationchamber/df.merged$diameteroffieldofview))*1000/df.merged$settlingvolume,2)
  }
  # counting method for whole chamber
  else if(CountingStrategy=='density3'){
    df.merged$density <- round((df.merged$organismquantity*1000)/df.merged$settlingvolume,2)
  }
  df.datain$density <- df.merged$density/df.merged$dilutionfactor
}

if('totalbiovolume'%in%CompTraits){
  if(!'density'%in%CompTraits&!'density'%in%names(df.datain)) df.datain$density<-NA
  if(!'biovolume'%in%CompTraits&!'biovolume'%in%names(df.datain)) df.datain$biovolume<-NA
  df.datain$totalbiovolume<-round(df.datain$density*df.datain$biovolume,2)
}

if('surfacearea'%in%CompTraits){
  if('surfacearea'%in%names(df.datain)) df.datain<-subset(df.datain,select=-surfacearea)
  if(CalcType=='advanced'){
    df.merged$surfacearea <- rep(NA,length=nrow(df.merged))
    df.merged.concat <- df.merged[is.na(df.merged$formulaforsurface),]
    sa.formulas <- unique(df.merged[!is.na(df.merged$formulaforsurface),]$formulaforsurface)
    for(sa.form in sa.formulas){
      df.temp <- subset(df.merged,formulaforsurface==sa.form)
      df.temp$surfacearea <- round(with(df.temp,eval(parse(text=sa.form))),2)
      df.merged.concat <- rbind(df.merged.concat,df.temp)
    }
    df.merged.concat <- df.merged.concat[order(df.merged.concat$index),]
    df.merged <- df.merged.concat
    df.datain$surfacearea <- df.merged$surfacearea
  }
  else if(CalcType=='simplified'){
    df.merged$surfacearea <- rep(NA,length=nrow(df.merged))
    df.merged.concat <- df.merged[is.na(df.merged$formulaforsurfacesimplified),]
    sa.formulas <- unique(df.merged[!is.na(df.merged$formulaforsurfacesimplified),]$formulaforsurfacesimplified)
    for(sa.form in sa.formulas){
      df.temp <- subset(df.merged,formulaforsurfacesimplified==sa.form)
      df.temp$surfacearea <- round(with(df.temp,eval(parse(text=sa.form))),2)
      df.merged.concat <- rbind(df.merged.concat,df.temp)
    }
    df.merged.concat <- df.merged.concat[order(df.merged.concat$index),]
    df.merged <- df.merged.concat
    df.datain$surfacearea <- df.merged$surfacearea
  }
}

if('surfacevolumeratio'%in%CompTraits){
  if(!'surfacearea'%in%CompTraits&!'surfacearea'%in%names(df.datain)) df.datain$surfacearea<-NA
  if(!'biovolume'%in%CompTraits&!'biovolume'%in%names(df.datain)) df.datain$biovolume<-NA
  df.datain$surfacevolumeratio<-round(df.datain$surfacearea/df.datain$biovolume,2)
}

if('totalcarboncontent'%in%CompTraits){
  if(!'density'%in%CompTraits&!'density'%in%names(df.datain)) df.datain$density<-NA
  if(!'cellcarboncontent'%in%CompTraits&!'cellcarboncontent'%in%names(df.datain)) df.datain$cellcarboncontent<-NA
  df.datain$totalcarboncontent<-round(df.datain$density*df.datain$cellcarboncontent,2)
}

df.datain <- subset(df.datain,select = -index)

write.table(df.datain,paste('TraitsOutputAU.csv',sep=''),row.names=F,sep = ";",dec = ".",quote=F) 
