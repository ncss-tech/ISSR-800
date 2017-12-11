## 2017-04-11
## D.E. Beaudette
## rasterize a single chunk for a single property, run via parallel
## 

# enable error trapping 
set -e

# chunk ID:
chunk=$1

# variable name
variable=$2

# creation options
create_opts=$3

# notdata value
nodata=$4

# output type
output_type=$5

# optional join for LUT
join_sql=$6

# filename
fname="${variable}-${chunk}.tif"

# SQL
sql_code="SELECT geom AS geom, CASE WHEN $variable IS NULL THEN $nodata ELSE $variable END AS var_to_rasterize FROM conus_800m_grid.grid JOIN conus_800m_grid.merged_data USING (gid) $join_sql WHERE grid.gid IN (SELECT gid FROM conus_800m_grid.grid WHERE chunk = '$chunk')"

# rasterize
gdal_rasterize \
-q \
-ot $output_type \
-co "$create_opts" \
-a_srs '+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23 +lon_0=-96 +x_0=0 +y_0=0 +no_defs +a=6378137 +rf=298.257222101 +towgs84=0.000,0.000,0.000 +to_meter=1' \
-a_nodata $nodata \
-a var_to_rasterize \
-sql "$sql_code" \
PG:"dbname='ssurgo_combined' user='postgres'" \
-tr 800 800 \
rasters/${variable}/${fname}


