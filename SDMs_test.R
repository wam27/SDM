
# MODELOS DE NICHO ECOLOGICO ----
## Wilderson Medina
## Febrero 09, 2024

# README ----
# Estimate species distribution models from occurrence points. It uses either
# alpha hull or convex hull as extent boundary. It also has the option of using
# either dismo or the ENMval package to use the maxent function.

## Arguments

# spp_list    csv with all species with occurrences if GBIF is set as FALSE
# nmin        min number of occurrences to compute. Five is the default
# nmax        max number of occurrences to compute. Set 15 as default
# hull        uses a polygon to get the extent
# convex_hull Uses convex.hull function instead of alpha hull
# GBIF        Get occurrences from GBIF
# ENM         Uses ENMval to estimate the model
# res         resolution of the environmental variables 0.5, 2.5, 5, 10 minutes of a decimal degree
# spp.limit   limit the estimate to a species threshold. The default is 100.
# output      the path to store raster and report table outputs



# CONFIGURACION ----
rm(list=ls()) #Vaciar ambiente
dir=setwd("C:/Users/wam27/Desktop")


## Librerias ----
if(!require(sf)){install.packages("sf");library(sf)}  #Convertir objetos  st a sf para el manejo de datos espaciales
if(!require(dplyr)){install.packages("dplyr");library(dplyr)} #Manipular los datos de manera mas eficiente
if(!require(dismo)){install.packages("dismo"); library(dismo)} #Modelador de distribucion basado en Maxent
if(!require(raster)){install.packages("raster"); library(raster)} # Manipular objetos raster
if(!require(rgbif)){install.packages("rgbif");library(rgbif)} # Descargar datos de gbif
if(!require(ENMeval)){install.packages("ENMeval"); library(ENMeval)} #Alternativa para generar modelos de distribución
if(!require(virtualspecies)){install.packages("virtualspecies");library(virtualspecies)} #Estimate collinearity
if(!require(rJava)){install.packages("rJava");library(rJava)} # Requisito para correr Maxent


# PREPARACION DE VARIABLES ----
spp_list_path<- file.choose() #Cargar lista de especies de interes
spp_list<-read.delim(spp_list_path, header=TRUE)
GBIF<-FALSE
ENM<-FALSE
nmin=5
nmax=15
spp.limit=100
hull=TRUE
convex_hull=TRUE
res<-10
output<-"C:/Users/wam27/Desktop/Models10/"
# Funci[on para estimar un umbral que defina la distribución potencial de las especies
sdm.threshold <- dget(paste0(dir,"/sdm_threshold.R"))


len.spp<- length(spp_list)    #Numero de especies

WGS84.proj <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs") #Definir datum


# Reporte final
report.table <- data.frame(SciName = character(),
                           TotalPresences = double(),
                           Errors = character(),
                           Time = double(),
                           stringsAsFactors = FALSE)

## Occurrencias


for (i in 1:len.spp){
  has.error <- tryCatch({
    start.time <- Sys.time()
    
    if (i>spp.limit){
      print('You have reached the species limit to compute models') # Definir un número máximo de especies para calcular los modelos 
    }
    
    sci.name <- as.character(spp_list$species[i]) #Nombre de la i-esima especie
    print(paste(i,sci.name)) 
    
    report.table[i,"SciName"] <- sci.name # añadir al reporte
    
    ############.   Cargar occurrencias directamente desde GBIF  .#############
    if(GBIF){ # Si GBIF=TRUE, descargr datos de la plataforma
      occurr<-occ_search(scientificName = sci.name,
                           hasCoordinate = TRUE,
                           limit = 5000)
      occ<- occurr$data
      
      } else {
        # si GBIF=FALSE, cargar base de datos al argumento spp_list
        occ<- spp_list %>% 
          dplyr::filter(species == sci.name)
        
        occ<- spp_list[spp_list$species !="",] #Remover filas sin registro de especie
      }
      
      # Depurar base de datos 
      #- remover NAs
      occ <- occ %>%
        dplyr::filter(!(is.na(year)|
                          is.na(decimalLongitude)&
                          is.na(decimalLatitude)))
      #- remover registros no verificados
      if("georeferenceVerificationStatus" %in% colnames(occ)){
        occ <- occ %>%
          dplyr::filter(is.na(georeferenceVerificationStatus) |
                          (georeferenceVerificationStatus!="unverified" &
                            georeferenceVerificationStatus!="verification required" &
                             georeferenceVerificationStatus!="requires verification"))
        }
      #- remover registros espacialmente atipicos
      occ<- occ[!grepl("COUNTRY_COORDINATE_MISMATCH", occ$issue),]
      occ <- occ[!duplicated(occ[c("decimalLongitude", "decimalLatitude")]),] # Remover duplicados
      
      
      if(nrow(occ)>=nmin & nrow(occ)<=nmax){
        coordinates(occ) <- c("decimalLongitude", "decimalLatitude") # transformar dataframe a datos espaciales
        proj4string(occ) <- WGS84.proj
        } else {
        print(paste0(sci.name," has only ",nrow(occ) ," records to compute"))
        next
          }
      
      TotalPresences<-nrow(occ) # Número de registros
      report.table[i,"TotalPresences"] <- TotalPresences
      
      
      # Definir extent a partir de un poligono o area de interes construida a partir de la distribución de registros
      if (hull){
        occ_sf<-st_as_sf(occ)
        
        if (convex_hull){ # Consruir un convexhull a partir de los registros
          Hull <- occ_sf %>%  st_convex_hull() %>% st_buffer(dist = 100000)
          } else { # Consruir un alphahull a partir de los registros
            # Funciones para calcular alpha hulls
          arc2line <- dget(paste0(dir,"/arc2line.R"))
          ahull2lines <- dget(paste0(dir,"/ahull2lines_v3.R"))
          spLines2poly <- dget(paste0(dir,"/spLines2poly_v2.R"))
          alphahull <- dget(paste0(dir,"/alphahull_v5.R"))
          
          Hull<-alphahull(points=occ_sf,
                            buffer=1000,
                            n=4)
          Hull<-Hull[1][[1]]
          }
    
        extent_occur <- Hull # obtener el extent
        } else{

        extent_occur <- extent(occ)+5  #Generar extent directamente de los registros y usando un buffer
        }
      
      # Obtener Variables ambientales desde worldclim
      r <- getData("worldclim",var="bio",res=res, lon=extent_occur@xmax ,lat=extent_occur@ymax)
      
   
      rasters.crop<- stack(crop(r,extent_occur)) # Reducir el extent de las variables a la zona de interés
      
      # Calcular colinearidad 
      r.reduced <- removeCollinearity(rasters.crop, multicollinearity.cutoff = 0.75, 
                                      select.variables = TRUE, sample.points = FALSE, plot = TRUE)
      
      

      # Seleccionar variables a partir del analisis de colinearidad
      r.selected<- subset(rasters.crop, r.reduced)
      
      # CORRIDA DE MODELO ----
      # Opcion de correr ENMevaluate que permite generar distintos escenarios de modelos y seleccionar el mejor
      if (ENM){
        
        Results<- ENMevaluate(occ = occ@coords, envs = r.selected, algorithm="maxent.jar",
                              RMvalues = c(0.75, 1, 1.25), n.bg = 5000, method= "randomkfold",
                              overlap= F, bin.output = TRUE, fc = c("L", "LQ","LQP"))
        
        Models <- Results@results
        Models$ID <- 1:nrow(Models)
        Models <- Models %>% arrange(AICc)
        selected.model <- Results@models[[Models$ID[1]]]
        
        #Arrojar la hipótesis de predicción
        map.model.maxent <- predict(r.selected,selected.model, type='cloglog', na.rm=TRUE,
                                    filename=paste0(output,sci.name,"_dismo.tif"),
                                    overwrite= TRUE,
                                    progress= 'text')
        
        Thr<-sdm.threshold(map.model.maxent,occ,"p10",binary=TRUE) #usar un umbral para convertir el modelo en binomial
        writeRaster(Thr[[1]],paste0(output,sci.name,"_dismo_bi.tif"))
        
        } else {
        
        # Calcular el modelo de la forma clásica, extrayendo valores ambientales a partir de las ocurrencias
        pres <- extract(r.selected, occ@coords) #
        
        
        ## RUN
        
        set.seed(45)
        
        backgr <- randomPoints(r.selected, 1000) #Generar puntos aleatorios para el background
        abs <- extract(r.selected, backgr) #Extraer valores ambientales usando los puntos de background
        pb <- c(rep(1, nrow(pres)), rep(0, nrow(abs)))
        sdmdata.present <- data.frame(cbind(pb, rbind(pres, abs))) #Organizar datos de presencia y background
        
        #Generar el modelo
        model.maxent<- maxent(
          x=r.selected,
          p=occ@coords,
          a=backgr,
          args=c('randomtestpoints=35',
                 'betamultiplier=1',
                 'linear=true',
                 'quadratic=true',
                 'product=true',
                 'threshold=true',
                 'hinge=true',
                 'threads=2',
                 'responsecurves=true',
                 'jackknife=true'
          )
        )
        # EXPORTAR SALIDAS ----
        

        # Predecir el modelo
        map.model.maxent <- predict(
          object= model.maxent,
          x= r.selected,
          na.rm=TRUE,
          format='GTiff',
          filename=paste0(output,sci.name,"_dismo.tif"),
          overwrite= TRUE,
          progress= 'text'
        )
        
        
        Thr<-sdm.threshold(map.model.maxent,occ,"p10",binary=TRUE) #usar un umbral para convertir el modelo en binomial
        writeRaster(Thr[[1]],paste0(output,sci.name,"_dismo_bi.tif"))
        
        
        end.time <- Sys.time()
        report.table[i,"Time"] <- end.time - start.time
        }
      
      write.csv(report.table, paste0(output,"/Report_Table_dismo.csv"))
      
      

  }, error = function(e){
    conditionMessage(e)
  })
  if(is.null(has.error)){
    next
  } else{
    report.table[i,"Errors"] <- has.error
    has.error<-NULL
  }
}


















