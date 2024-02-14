# SDM
## Take species occurrences to run Maxent in the dismo package

# Estimate species distribution models from occurrence points. It uses either
# alpha hull or convex hull as extent boundary. It also has the option of using
# either dismo or the ENMval package to use the maxent function.

## Basic variables

# spp_list    csv with all species with occurrences if GBIF is set as FALSE
# nmin        min number of occurrences to compute
# nmax        max number of occurrences to compute. Set ad Inf by default
# hull        uses a polygon to get the extent
# convex_hull Uses convex.hull function instead of alpha hull
# GBIF        Get occurrences from GBIF
# ENM         Uses ENMval to estimate the model
# res         resolution of the environmental variables 0.5, 2.5, 5, 10 minutes of a decimal degree
# spp.limit   limit the estimate to a species threshold.
# output      the path to store raster and report table outputs
