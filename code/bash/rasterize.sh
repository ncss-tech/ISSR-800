## 2017-04-11
## D.E. Beaudette
## rasterize 800m SSURGO|STATSGO gridded data
##

## get chunks associated with real data: 2 minutes
# echo "select DISTINCT chunk FROM conus_800m_grid.grid JOIN conus_800m_grid.merged_data USING (gid)" | psql -U postgres ssurgo_combined -t -A > chunks-with-data.txt

## export / rasterize / composite: in chunks
# about 2 minutes per property = 105 minutes 

## arguments
# column name in merged_data
# creation options
# NODATA value
# datatype
# join for categorical data

## output dir and associated files created using variable name


## QC data
./rasterize-variable.sh "ssurgo_pct" "COMPRESS=LZW" "0" "Float32" "JOIN conus_800m_grid.survey_data_available ON survey_data_available.grid_gid = grid.gid"
./rasterize-variable.sh "statsgo_pct" "COMPRESS=LZW" "0" "Float32" "JOIN conus_800m_grid.survey_data_available ON survey_data_available.grid_gid = grid.gid"
./rasterize-variable.sh "number_components" "COMPRESS=LZW" "255" "Byte"

##
## NODATA: NULL vs. 0 
# there are cases were 0 makes sense, but isn't used consistently (SAR, EC)
# there are cases where 0 should be interpreted as NULL (wei)
# there are cases where 0 is questionable (sand)
#
# --> NODATA = 0 makes sense for categorical variables
# --> NODATA = -9999 is a useful compromise for cases above
# 
# TODO --> 0-values in all other cases should be inspected and possibly set to NULL
 


# according to the SSURGO metadata, WEI is stored as a VARCHAR
# it is converted to an integer in the current queries
./rasterize-variable.sh "wei" "COMPRESS=LZW" "-9999" "Float32"

./rasterize-variable.sh "resdept" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "soil_depth" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "water_storage" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "om_kg_sq_m" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "caco3_kg_sq_m" "COMPRESS=LZW" "-9999" "Float32"

./rasterize-variable.sh "sand" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "silt" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "clay" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "db" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "sar" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "ec" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "cec" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "ph" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "max_om" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "min_ksat" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "max_ksat" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "mean_ksat" "COMPRESS=LZW" "-9999" "Float32"

./rasterize-variable.sh "clay_05" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "clay_025" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "clay_2550" "COMPRESS=LZW" "-9999" "Float32"

./rasterize-variable.sh "ph_05" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "ph_025" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "ph_2550" "COMPRESS=LZW" "-9999" "Float32"

./rasterize-variable.sh "ec_05" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "ec_025" "COMPRESS=LZW" "-9999" "Float32"

./rasterize-variable.sh "cec_05" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "cec_025" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "cec_050" "COMPRESS=LZW" "-9999" "Float32"

./rasterize-variable.sh "ksat_05" "COMPRESS=LZW" "-9999" "Float32"

./rasterize-variable.sh "paws_025" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "paws_050" "COMPRESS=LZW" "-9999" "Float32"

./rasterize-variable.sh "rf_025" "COMPRESS=LZW" "-9999" "Float32"
./rasterize-variable.sh "kw_025" "COMPRESS=LZW" "-9999" "Float32"

./rasterize-variable.sh "i_class" "COMPRESS=LZW" "0" "Byte"
./rasterize-variable.sh "n_class" "COMPRESS=LZW" "0" "Byte"


## categorical variables, requires 5th arg with join condition
./rasterize-variable.sh "series_name_int" "COMPRESS=LZW" "0" "UInt16" "JOIN conus_800m_grid.series_name_lut USING (series_name)"
./rasterize-variable.sh "survey_type_int" "COMPRESS=LZW" "0" "Byte" "JOIN conus_800m_grid.survey_type_lut USING (survey_type)"
./rasterize-variable.sh "hydgrp_int" "COMPRESS=LZW" "0" "Byte" "JOIN conus_800m_grid.hydgrp_lut USING (hydgrp)"

./rasterize-variable.sh "str_int" "COMPRESS=LZW" "0" "Byte" "JOIN conus_800m_grid.str_lut USING (str)"
./rasterize-variable.sh "drainage_class_int" "COMPRESS=LZW" "0" "Byte" "JOIN conus_800m_grid.drainage_class_lut USING (drainage_class)"
./rasterize-variable.sh "soilorder_int" "COMPRESS=LZW" "0" "Byte" "JOIN conus_800m_grid.soilorder_lut USING (soilorder)"
./rasterize-variable.sh "suborder_int" "COMPRESS=LZW" "0" "Byte" "JOIN conus_800m_grid.suborder_lut USING (suborder)"
./rasterize-variable.sh "greatgroup_int" "COMPRESS=LZW" "0" "Byte" "JOIN conus_800m_grid.greatgroup_lut USING (greatgroup)"
./rasterize-variable.sh "taxpartsize_int" "COMPRESS=LZW" "0" "Byte" "JOIN conus_800m_grid.taxpartsize_lut USING (taxpartsize)"
./rasterize-variable.sh "weg_int" "COMPRESS=LZW" "0" "Byte" "JOIN conus_800m_grid.weg_lut USING (weg)"




