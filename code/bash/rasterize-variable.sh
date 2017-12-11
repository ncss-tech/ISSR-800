## 2017-04-11
## D.E. Beaudette
## rasterize a all chunks for a single property, run via parallel
## 

# enable error trapping 
set -e

# variable name
variable=$1

# creation options
create_opts=$2

# notdata value
nodata=$3

# output type
output_type=$4

# optional join for LUT
# note that we have to add single quotes to contain spaces
join_sql=$5
join_sql="'"$join_sql"'"

# init dir if missing and clean
mkdir -p rasters/${variable}
rm -f rasters/${variable}/*.tif

# chunk IDs required
cat chunks-with-data.txt | parallel --no-notice --eta --progress ./rasterize-chunk.sh {} $variable $create_opts $nodata $output_type $join_sql

# create VRT
gdalbuildvrt -srcnodata $nodata -vrtnodata $nodata rasters/${variable}.vrt rasters/${variable}/*.tif

# convert to single GeoTiff
gdal_translate -q -a_nodata $nodata -co "$create_opts" rasters/${variable}.vrt rasters/${variable}.tif

# clean-up
rm -rf rasters/${variable}/


