
rm(list=ls()) #Vaciar ambiente
if(!require(divraster)){install.packages("divraster");library(divraster)}
if(!require(leaflet)){install.packages("leaflet"); library(leaflet)}
library(htmlwidgets)
dir=setwd("C:/Users/wam27/Desktop")
multiple.union <- dget(paste0(dir,"/unionMul.R"))


spp_list_path<- file.choose() #Cargar lista de especies de interes
spp_list<-read.delim(spp_list_path, header=TRUE)

spp_list<- spp_list[spp_list$species !="",]
spp_list_unique<- unique(spp_list$species)
len.spp<- length(spp_list_unique)


raster.list=list()
for (i in 1:len.spp){
  sci.name <- as.character(spp_list_unique[i])
  print(paste(i,sci.name))
  raster_path<-paste0(dir,"/Models4/",sci.name,"_dismo_bi.tif")
  
  if(file.exists(raster_path)){
    raster.spp<-raster(raster_path)
    raster.list[[length(raster.list)+1]] = raster.spp
  }else{
    print("No raster found")
  }
}

union.extent<-multiple.union(raster.list)


rasters_cropped <- lapply(raster.list, terra::extend, union.extent,0)
rs <- stack(rasters_cropped)
rs1 <- calc(rs, base::sum, na.rm=TRUE)
rs2<- reclassify(rs1,c(-Inf,0,-Inf))

#plot(rs2)
writeRaster(rs,paste0(dir,"/Models4/rs.tif"), overwrite=TRUE)

r3<-terra::rast(paste0(dir,"/Models4/Diversidad_alpha_bats.tif"))


classes<-as.numeric(c(1,120))
pal<-colorNumeric(('inferno'),domain =classes)
                  

s<-leaflet() %>%
  addProviderTiles(providers$CartoDB.DarkMatterNoLabels, group = 'Topographic') %>%
  addRasterImage(r3, colors = 'inferno', opacity = 1)%>%
  addLegend("bottomleft", 
            pal = pal, 
            values = classes,
            opacity = 1,
            title = 'Species Richness')

saveWidget(s,paste0(dir,"/Models4/Species_Richness"), background = "white")


##Beta diversity
r4<-terra::rast(paste0(dir,"/Models4/rs.tif"))
betaD<-spat.beta(r4)
plot(betaD)

b<-leaflet() %>%
  addProviderTiles(providers$CartoDB.DarkMatterNoLabels, group = 'Topographic') %>%
  addRasterImage(betaD, colors = 'inferno', opacity = 1)#%>%
  # addLegend("bottomleft", 
  #           pal = pal, 
  #           values = classes,
  #           opacity = 1,
  #           title = 'Species Richness')
              
              
              

test<-load.data()
              
