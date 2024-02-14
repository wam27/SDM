## Maps alpha and beta diversity based on binomial species distribution models.


rm(list=ls()) #Vaciar ambiente
if(!require(divraster)){install.packages("divraster");library(divraster)}
if(!require(leaflet)){install.packages("leaflet"); library(leaflet)}
if(!require(htmlwidgets)){install.packages("htmlwidgets"); library(htmlwidgets)}

dir=setwd("C:/Users/wam27/Desktop") # defines directory
multiple.union <- dget(paste0(dir,"/unionMul.R")) # calls the multiple union function to get the extent of the union of all raster layers


spp_list_path<- file.choose() #Load species manually
spp_list<-read.delim(spp_list_path, header=TRUE)

#Clean data
spp_list<- spp_list[spp_list$species !="",]
spp_list_unique<- unique(spp_list$species)
len.spp<- length(spp_list_unique)


raster.list=list()
for (i in 1:len.spp){
  sci.name <- as.character(spp_list_unique[i])
  print(paste(i,sci.name))
  raster_path<-paste0(dir,"/Models4/",sci.name,"_dismo_bi.tif")
  if(file.exists(raster_path)){
    raster.spp<-raster(raster_path) # read existing rasters and append them to the raster.list
    raster.list[[length(raster.list)+1]] = raster.spp
  }else{
    print("No raster found")
  }
}

union.extent<-multiple.union(raster.list) # extent of the union of inputs

## ALpha diversity
rasters_cropped <- lapply(raster.list, terra::extend, union.extent,0) # extend rasters to the largest extent. Add zeros to new cells
rs <- stack(rasters_cropped)
rs1 <- calc(rs, base::sum, na.rm=TRUE) # Sum all rasters to create richness raster dataset
rs2<- reclassify(rs1,c(-Inf,0,-Inf)) # Reclasify to remove Nodata value from the view

#plot(rs2)
writeRaster(rs,paste0(dir,"/Models4/Diversidad_alpha_bats.tif"), overwrite=TRUE) # Saves raster as raster format
r3<-terra::rast(paste0(dir,"/Models4/Diversidad_alpha_bats.tif")) # Read raster as terra format to map in leaflet.


# Create the map
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

saveWidget(s,paste0(dir,"/Models4/Species_Richness"), background = "white") # save as html


## Beta diversity
writeRaster(rs,paste0(dir,"/Models4/rs.tif"), overwrite=TRUE) # Saves raster as raster format
r4<-terra::rast(paste0(dir,"/Models4/rs.tif"))  # Read raster as terra format to map in leaflet.
betaD<-spat.beta(r4) # Function to estimate beta diversity
plot(betaD)

# View map
b<-leaflet() %>%
  addProviderTiles(providers$CartoDB.DarkMatterNoLabels, group = 'Topographic') %>%
  addRasterImage(betaD, colors = 'inferno', opacity = 1)
              
