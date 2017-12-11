#!/bin/bash

## 2017-12-04
## D.E. Beaudette
##
##
## usage: bash xxx "ssurgo"



# database name: ssurgo | statsgo
db=$1


# compile the pieces of the query into one massive string variable
# schema selected by interpolation of ${db} variable
sql=$(cat <<EOF

SET search_path TO conus_800m_grid, public ;
SET work_mem to 800000 ;

DROP TABLE IF EXISTS ${db}_component_weights;

CREATE TABLE ${db}_component_weights as
SELECT ${db}_grid_mapunit.gid, cokey, 
CASE WHEN wei IS NULL THEN NULL ELSE area_wt * comppct_r END as wei_wt,
CASE WHEN resdept IS NULL THEN NULL ELSE area_wt * comppct_r END as resdept_wt,
CASE WHEN soil_depth IS NULL THEN NULL ELSE area_wt * comppct_r END as soil_depth_wt,
CASE WHEN profile_water_storage IS NULL THEN NULL ELSE area_wt * comppct_r END as profile_water_storage_wt,
CASE WHEN om_kg_sq_m IS NULL THEN NULL ELSE area_wt * comppct_r END as om_kg_sq_m_wt,
CASE WHEN caco3_kg_sq_m IS NULL THEN NULL ELSE area_wt * comppct_r END as caco3_kg_sq_m_wt,
CASE WHEN sar IS NULL THEN NULL ELSE area_wt * comppct_r END as sar_wt,
CASE WHEN ec IS NULL THEN NULL ELSE area_wt * comppct_r END as ec_wt,
CASE WHEN max_om IS NULL THEN NULL ELSE area_wt * comppct_r END as max_om_wt,
CASE WHEN min_ksat IS NULL THEN NULL ELSE area_wt * comppct_r END as min_ksat_wt,
CASE WHEN max_ksat IS NULL THEN NULL ELSE area_wt * comppct_r END as max_ksat_wt,
CASE WHEN mean_ksat IS NULL THEN NULL ELSE area_wt * comppct_r END as mean_ksat_wt,
CASE WHEN profile_wt_mean_sand IS NULL THEN NULL ELSE area_wt * comppct_r END as sand_wt,
CASE WHEN profile_wt_mean_silt IS NULL THEN NULL ELSE area_wt * comppct_r END as silt_wt,
CASE WHEN profile_wt_mean_clay IS NULL THEN NULL ELSE area_wt * comppct_r END as clay_wt,
CASE WHEN profile_wt_mean_db IS NULL THEN NULL ELSE area_wt * comppct_r END as db_wt,
CASE WHEN profile_wt_mean_cec IS NULL THEN NULL ELSE area_wt * comppct_r END as cec_wt,
CASE WHEN profile_wt_mean_ph IS NULL THEN NULL ELSE area_wt * comppct_r END as ph_wt,

CASE WHEN clay_05 IS NULL THEN NULL ELSE area_wt * comppct_r END as clay_05_wt, 
CASE WHEN clay_025 IS NULL THEN NULL ELSE area_wt * comppct_r END as clay_025_wt, 
CASE WHEN clay_2550 IS NULL THEN NULL ELSE area_wt * comppct_r END as clay_2550_wt,

CASE WHEN ph_05 IS NULL THEN NULL ELSE area_wt * comppct_r END as ph_05_wt, 
CASE WHEN ph_025 IS NULL THEN NULL ELSE area_wt * comppct_r END as ph_025_wt, 
CASE WHEN ph_2550 IS NULL THEN NULL ELSE area_wt * comppct_r END as ph_2550_wt,

CASE WHEN ec_05 IS NULL THEN NULL ELSE area_wt * comppct_r END as ec_05_wt, 
CASE WHEN ec_025 IS NULL THEN NULL ELSE area_wt * comppct_r END as ec_025_wt, 

CASE WHEN cec_05 IS NULL THEN NULL ELSE area_wt * comppct_r END as cec_05_wt, 
CASE WHEN cec_025 IS NULL THEN NULL ELSE area_wt * comppct_r END as cec_025_wt, 
CASE WHEN cec_050 IS NULL THEN NULL ELSE area_wt * comppct_r END as cec_050_wt, 

CASE WHEN ksat_05 IS NULL THEN NULL ELSE area_wt * comppct_r END as ksat_05_wt, 

CASE WHEN paws_025 IS NULL THEN NULL ELSE area_wt * comppct_r END as paws_025_wt, 
CASE WHEN paws_050 IS NULL THEN NULL ELSE area_wt * comppct_r END as paws_050_wt, 

CASE WHEN rf_025 IS NULL THEN NULL ELSE area_wt * comppct_r END as rf_025_wt, 

CASE WHEN kw_025 IS NULL THEN NULL ELSE area_wt * comppct_r END as kw_025_wt
FROM
conus_800m_grid.${db}_grid_mapunit
-- debug
-- JOIN grid ON grid.gid = ${db}_grid_mapunit.grid_gid AND chunk = '11-40'
-- debug
JOIN ${db}_component_data USING (mukey);

-- index
CREATE UNIQUE INDEX ${db}_component_weights_idx ON conus_800m_grid.${db}_component_weights (gid,cokey);
CREATE INDEX ${db}_component_weights_idx2 ON ${db}_component_weights (gid);
VACUUM ANALYZE conus_800m_grid.${db}_component_weights;

EOF
)

## debugging
# note the use of double quotes: need this to preserve newlines
# echo "$sql" 

## run in DB
# note the use of double quotes: need this to preserve newlines
echo "$sql" | psql -U postgres ssurgo_combined



# -- -- -- SSURGO -- -- -- 
# -- 
# -- create a table of component weights: takes a while to run (1 minutes)
# -- with NULL weights when specific values are missing
# -- 
# DROP TABLE conus_800m_grid.component_weights;
# CREATE TABLE conus_800m_grid.component_weights as
# SELECT gid, cokey, 
# CASE WHEN wei IS NULL THEN NULL ELSE area_wt * comppct_r END as wei_wt,
# CASE WHEN resdept IS NULL THEN NULL ELSE area_wt * comppct_r END as resdept_wt,
# CASE WHEN soil_depth IS NULL THEN NULL ELSE area_wt * comppct_r END as soil_depth_wt,
# CASE WHEN profile_water_storage IS NULL THEN NULL ELSE area_wt * comppct_r END as profile_water_storage_wt,
# CASE WHEN om_kg_sq_m IS NULL THEN NULL ELSE area_wt * comppct_r END as om_kg_sq_m_wt,
# CASE WHEN caco3_kg_sq_m IS NULL THEN NULL ELSE area_wt * comppct_r END as caco3_kg_sq_m_wt,
# CASE WHEN sar IS NULL THEN NULL ELSE area_wt * comppct_r END as sar_wt,
# CASE WHEN ec IS NULL THEN NULL ELSE area_wt * comppct_r END as ec_wt,
# CASE WHEN max_om IS NULL THEN NULL ELSE area_wt * comppct_r END as max_om_wt,
# CASE WHEN min_ksat IS NULL THEN NULL ELSE area_wt * comppct_r END as min_ksat_wt,
# CASE WHEN max_ksat IS NULL THEN NULL ELSE area_wt * comppct_r END as max_ksat_wt,
# CASE WHEN mean_ksat IS NULL THEN NULL ELSE area_wt * comppct_r END as mean_ksat_wt,
# CASE WHEN profile_wt_mean_sand IS NULL THEN NULL ELSE area_wt * comppct_r END as sand_wt,
# CASE WHEN profile_wt_mean_silt IS NULL THEN NULL ELSE area_wt * comppct_r END as silt_wt,
# CASE WHEN profile_wt_mean_clay IS NULL THEN NULL ELSE area_wt * comppct_r END as clay_wt,
# CASE WHEN profile_wt_mean_db IS NULL THEN NULL ELSE area_wt * comppct_r END as db_wt,
# CASE WHEN profile_wt_mean_cec IS NULL THEN NULL ELSE area_wt * comppct_r END as cec_wt,
# CASE WHEN profile_wt_mean_ph IS NULL THEN NULL ELSE area_wt * comppct_r END as ph_wt,
# 
# CASE WHEN clay_05 IS NULL THEN NULL ELSE area_wt * comppct_r END as clay_05_wt, 
# CASE WHEN clay_025 IS NULL THEN NULL ELSE area_wt * comppct_r END as clay_025_wt, 
# CASE WHEN clay_2550 IS NULL THEN NULL ELSE area_wt * comppct_r END as clay_2550_wt,
# 
# CASE WHEN ph_05 IS NULL THEN NULL ELSE area_wt * comppct_r END as ph_05_wt, 
# CASE WHEN ph_025 IS NULL THEN NULL ELSE area_wt * comppct_r END as ph_025_wt, 
# CASE WHEN ph_2550 IS NULL THEN NULL ELSE area_wt * comppct_r END as ph_2550_wt,
# 
# CASE WHEN ec_05 IS NULL THEN NULL ELSE area_wt * comppct_r END as ec_05_wt, 
# CASE WHEN ec_025 IS NULL THEN NULL ELSE area_wt * comppct_r END as ec_025_wt, 
# 
# CASE WHEN cec_05 IS NULL THEN NULL ELSE area_wt * comppct_r END as cec_05_wt, 
# CASE WHEN cec_025 IS NULL THEN NULL ELSE area_wt * comppct_r END as cec_025_wt, 
# CASE WHEN cec_050 IS NULL THEN NULL ELSE area_wt * comppct_r END as cec_050_wt, 
# 
# CASE WHEN ksat_05 IS NULL THEN NULL ELSE area_wt * comppct_r END as ksat_05_wt, 
# 
# CASE WHEN paws_025 IS NULL THEN NULL ELSE area_wt * comppct_r END as paws_025_wt, 
# CASE WHEN paws_050 IS NULL THEN NULL ELSE area_wt * comppct_r END as paws_050_wt, 
# 
# CASE WHEN rf_025 IS NULL THEN NULL ELSE area_wt * comppct_r END as rf_025_wt, 
# 
# CASE WHEN kw_025 IS NULL THEN NULL ELSE area_wt * comppct_r END as kw_025_wt
# FROM
# component_data
# JOIN grid_mapunit USING (mukey);
# 
# -- index 
# CREATE UNIQUE INDEX component_weights_idx ON component_weights (gid,cokey);
# CREATE INDEX component_weights_idx2 ON component_weights (gid);
# VACUUM ANALYZE component_weights;
# -- -- -- SSURGO -- -- -- 
# 
# 
# -- -- -- STATSGO -- -- --
# 
# -- 
# -- create a table of component weights: takes a while to run (13 minutes)
# -- with NULL weights when specific values are missing
# -- 
# DROP TABLE conus_800m_grid.statsgo_component_weights;
# CREATE TABLE conus_800m_grid.statsgo_component_weights as
# SELECT statsgo_grid_mapunit.gid, cokey, 
# CASE WHEN wei IS NULL THEN NULL ELSE area_wt * comppct_r END as wei_wt,
# CASE WHEN resdept IS NULL THEN NULL ELSE area_wt * comppct_r END as resdept_wt,
# CASE WHEN soil_depth IS NULL THEN NULL ELSE area_wt * comppct_r END as soil_depth_wt,
# CASE WHEN profile_water_storage IS NULL THEN NULL ELSE area_wt * comppct_r END as profile_water_storage_wt,
# CASE WHEN om_kg_sq_m IS NULL THEN NULL ELSE area_wt * comppct_r END as om_kg_sq_m_wt,
# CASE WHEN caco3_kg_sq_m IS NULL THEN NULL ELSE area_wt * comppct_r END as caco3_kg_sq_m_wt,
# CASE WHEN sar IS NULL THEN NULL ELSE area_wt * comppct_r END as sar_wt,
# CASE WHEN ec IS NULL THEN NULL ELSE area_wt * comppct_r END as ec_wt,
# CASE WHEN max_om IS NULL THEN NULL ELSE area_wt * comppct_r END as max_om_wt,
# CASE WHEN min_ksat IS NULL THEN NULL ELSE area_wt * comppct_r END as min_ksat_wt,
# CASE WHEN max_ksat IS NULL THEN NULL ELSE area_wt * comppct_r END as max_ksat_wt,
# CASE WHEN mean_ksat IS NULL THEN NULL ELSE area_wt * comppct_r END as mean_ksat_wt,
# CASE WHEN profile_wt_mean_sand IS NULL THEN NULL ELSE area_wt * comppct_r END as sand_wt,
# CASE WHEN profile_wt_mean_silt IS NULL THEN NULL ELSE area_wt * comppct_r END as silt_wt,
# CASE WHEN profile_wt_mean_clay IS NULL THEN NULL ELSE area_wt * comppct_r END as clay_wt,
# CASE WHEN profile_wt_mean_db IS NULL THEN NULL ELSE area_wt * comppct_r END as db_wt,
# CASE WHEN profile_wt_mean_cec IS NULL THEN NULL ELSE area_wt * comppct_r END as cec_wt,
# CASE WHEN profile_wt_mean_ph IS NULL THEN NULL ELSE area_wt * comppct_r END as ph_wt,
# 
# CASE WHEN clay_05 IS NULL THEN NULL ELSE area_wt * comppct_r END as clay_05_wt, 
# CASE WHEN clay_025 IS NULL THEN NULL ELSE area_wt * comppct_r END as clay_025_wt, 
# CASE WHEN clay_2550 IS NULL THEN NULL ELSE area_wt * comppct_r END as clay_2550_wt,
# 
# CASE WHEN ph_05 IS NULL THEN NULL ELSE area_wt * comppct_r END as ph_05_wt, 
# CASE WHEN ph_025 IS NULL THEN NULL ELSE area_wt * comppct_r END as ph_025_wt, 
# CASE WHEN ph_2550 IS NULL THEN NULL ELSE area_wt * comppct_r END as ph_2550_wt,
# 
# CASE WHEN ec_05 IS NULL THEN NULL ELSE area_wt * comppct_r END as ec_05_wt, 
# CASE WHEN ec_025 IS NULL THEN NULL ELSE area_wt * comppct_r END as ec_025_wt, 
# 
# CASE WHEN cec_05 IS NULL THEN NULL ELSE area_wt * comppct_r END as cec_05_wt, 
# CASE WHEN cec_025 IS NULL THEN NULL ELSE area_wt * comppct_r END as cec_025_wt, 
# CASE WHEN cec_050 IS NULL THEN NULL ELSE area_wt * comppct_r END as cec_050_wt, 
# 
# CASE WHEN ksat_05 IS NULL THEN NULL ELSE area_wt * comppct_r END as ksat_05_wt, 
# 
# CASE WHEN paws_025 IS NULL THEN NULL ELSE area_wt * comppct_r END as paws_025_wt, 
# CASE WHEN paws_050 IS NULL THEN NULL ELSE area_wt * comppct_r END as paws_050_wt, 
# 
# CASE WHEN rf_025 IS NULL THEN NULL ELSE area_wt * comppct_r END as rf_025_wt, 
# 
# CASE WHEN kw_025 IS NULL THEN NULL ELSE area_wt * comppct_r END as kw_025_wt
# FROM
# conus_800m_grid.statsgo_grid_mapunit
# -- debug
# -- JOIN grid ON grid.gid = statsgo_grid_mapunit.grid_gid AND chunk = '11-40'
# -- debug
# JOIN statsgo_component_data USING (mukey);
# 
# -- index
# CREATE UNIQUE INDEX statsgo_component_weights_idx ON conus_800m_grid.statsgo_component_weights (gid,cokey);
# VACUUM ANALYZE conus_800m_grid.statsgo_component_weights;
# 
# -- -- -- STATSGO -- -- --

