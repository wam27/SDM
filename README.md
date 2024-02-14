# SDM
## Take species occurrences to run Maxent in the dismo package

Estimate species distribution models from occurrence points. It uses either alpha hull or convex hull (the default) as an extent boundary. It also has the option of using either dismo (the default) or the ENMval package to use the maxent function.

## Basic variables

#### spp_list -----   csv with occurrences for species. Here GBIF is set as FALSE. The file can be downloaded directly from https://www.gbif.org/occurrence/download/0243969-200613084148143 or accessed from the GBIF API
#### nmin   -----     min number of occurrences to compute
#### nmax   -----     max number of occurrences to compute. Set as Inf by default
#### hull   -----     uses a polygon to get the extent. This is the default. Otherwise, get the extent of the occurrences.
#### convex_hull ----- uses convex.hull function instead of alpha hull. This is the default.
#### GBIF   -----     get occurrences from GBIF
#### ENM   -----      uses ENMval to estimate a model
#### res   -----      resolution of the environmental variables 0.5, 2.5, 5, 10 minutes of a decimal degree
#### spp.limit -----  limit the analysis to a species threshold.
#### output -----    the path to store raster and report table outputs
