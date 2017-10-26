# ISSR-800
**Intermediate-scale gridded soil property and interpretation maps from averaged and aggregated SSURGO and STATSGO data.**

![](examples/pH-0-25cm-800m.jpg)

## Background 
There is a long-standing gap in analytical capacity for users of soil information, between the scales of SSURGO and STATSGO, that require a raster-based product that is both simple to use and sufficiently detailed for use at the LRU to MLRA scales. SDD staff has developed a product that provides raster maps of selected soil properties various depths and soil interpretations, provided at the 800m grid size, derived from SSURGO and STATSGO.

## Objective
Provide a set of continuous rasters for selected soil properties for selected depths, as well as for selected interpretations, derived from SSURGO and STATSGO, for the entire U.S. The resulting maps would be a compromise between flexibility and ease of use. Alternative "gap-filled" products (as proposed by the Database Focus Team) could serve the role as a general purpose, vector/raster database.

## What
The product proposed here provides soil property and interpretation information for 800m grid raster files. Values for a selected set of soil properties at specified depths, as well as selected interpretation, are provided for each 800m pixel. Depending on the property, depth interval used, and interpretation, different methods are used to aggregate within the profile and across the map unit. An excel spreadsheet is available on a NCSS GitHub site or a Database Focus Team SharePoint page for examination of the different values and methods used. Some pixels will represent information across map unit boundaries contained in the original vector maps. For this project, the 800m pixel size was chosen to provide a product for LRU to MLRA to continental scale projects that are small enough for rapid analysis and display. Another reason for the 800m pixel size is to approximate the size of the 800m PRISM climate products that are commonly available and used as climate proxies in many regional to continental scale analyses.

## Staff
  * Dylan Beaudette - Digital Soil Mapping Specialist, NRCS Region 2
  * Jennifer Wood - Soil Data Quality Specialist, NRCS Region 
  * Tom D’Avello - Soil Scientist/GIS Specialist, NSSC-Geospatial Research Unit 
  * Whityn Owen - GIS Specialist, NRCS Oregon
  * Stephen Roecker - Soil Data Quality Specialist/GIS Specialist, NRCS Region 11
  * Jason Nemecek - State Soil Scientist, Wisconsin


## Related Products
   * [CONUS-SOIL](http://www.soilinfo.psu.edu/index.cgi?soil_data&conus&data_cov&texture&image)
   * [Soils Database for Wind Erosion/Windblown Dust](http://www.lar.wsu.edu/nw-airquest/soils_database.html) [publication](http://www.jswconline.org/content/64/6/363.refs)
