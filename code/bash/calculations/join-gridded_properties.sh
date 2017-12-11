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

DROP TABLE IF EXISTS ${db}_gridded_properties ;
CREATE TABLE ${db}_gridded_properties AS
-- aggregated to grid id
SELECT grid_gid,
count(cokey) as number_components,
-- these have been corrected for missing weights
-- NULLIF: used to detect 0 and replace with NULL
sum(wei * wei_wt) / NULLIF(sum(wei_wt), 0) as wei,
sum(resdept * resdept_wt) / NULLIF(sum(resdept_wt), 0) as resdept,
sum(soil_depth * soil_depth_wt) / NULLIF(sum(soil_depth_wt), 0) as soil_depth,
sum(profile_water_storage * profile_water_storage_wt) / NULLIF(sum(profile_water_storage_wt), 0) as water_storage,
sum(om_kg_sq_m * om_kg_sq_m_wt) / NULLIF(sum(om_kg_sq_m_wt), 0) as om_kg_sq_m,
sum(caco3_kg_sq_m * caco3_kg_sq_m_wt) / NULLIF(sum(caco3_kg_sq_m_wt), 0) as caco3_kg_sq_m,
sum(profile_wt_mean_sand * sand_wt) / NULLIF(sum(sand_wt), 0) as sand,
sum(profile_wt_mean_silt * silt_wt) / NULLIF(sum(silt_wt), 0) as silt,
sum(profile_wt_mean_clay * clay_wt) / NULLIF(sum(clay_wt), 0) as clay,
sum(profile_wt_mean_db * db_wt) / NULLIF(sum(db_wt), 0) as db,
sum(sar * sar_wt) / NULLIF(sum(sar_wt), 0) as sar,
sum(ec * ec_wt) / NULLIF(sum(ec_wt), 0) as ec,
sum(profile_wt_mean_cec * cec_wt) / NULLIF(sum(cec_wt), 0) as cec,
sum(profile_wt_mean_ph * ph_wt) / NULLIF(sum(ph_wt), 0) as ph,
sum(max_om * max_om_wt) / NULLIF(sum(max_om_wt), 0) as max_om,
sum(min_ksat * min_ksat_wt) / NULLIF(sum(min_ksat_wt), 0) as min_ksat,
sum(max_ksat * max_ksat_wt) / NULLIF(sum(max_ksat_wt), 0) as max_ksat,
sum(mean_ksat * mean_ksat_wt) / NULLIF(sum(mean_ksat_wt), 0) as mean_ksat,
-- slab-wise aggregates
sum(clay_05 * clay_05_wt) / NULLIF(sum(clay_05_wt), 0) as clay_05, 
sum(clay_025 * clay_025_wt) / NULLIF(sum(clay_025_wt), 0) as clay_025, 
sum(clay_2550 * clay_2550_wt) / NULLIF(sum(clay_2550_wt), 0) as clay_2550, 

sum(ph_05 * ph_05_wt) / NULLIF(sum(ph_05_wt), 0) as ph_05, 
sum(ph_025 * ph_025_wt) / NULLIF(sum(ph_025_wt), 0) as ph_025, 
sum(ph_2550 * ph_2550_wt) / NULLIF(sum(ph_2550_wt), 0) as ph_2550, 

sum(ec_05 * ec_05_wt) / NULLIF(sum(ec_05_wt), 0) as ec_05, 
sum(ec_025 * ec_025_wt) / NULLIF(sum(ec_025_wt), 0) as ec_025, 

sum(cec_05 * cec_05_wt) / NULLIF(sum(cec_05_wt), 0) as cec_05, 
sum(cec_025 * cec_025_wt) / NULLIF(sum(cec_025_wt), 0) as cec_025, 
sum(cec_050 * cec_050_wt) / NULLIF(sum(cec_050_wt), 0) as cec_050, 

sum(ksat_05 * ksat_05_wt) / NULLIF(sum(ksat_05_wt), 0) as ksat_05, 

sum(paws_025 * paws_025_wt) / NULLIF(sum(paws_025_wt), 0) as paws_025, 
sum(paws_050 * paws_050_wt) / NULLIF(sum(paws_050_wt), 0) as paws_050, 
sum(rf_025 * rf_025_wt) / NULLIF(sum(rf_025_wt), 0) as rf_025, 
sum(kw_025 * kw_025_wt) / NULLIF(sum(kw_025_wt), 0) as kw_025,

-- categorical variables that are the most extensive (by area) for each cell
-- this is a 1:1 join so the MAX function does nothing
max(${db}_soil_series.compname) as series_name,
max(${db}_grid_str_class.str) AS str,
max(${db}_grid_drain_class.drainagecl) as drainage_class,
max(${db}_grid_nirr_class.nirrcapcl)::integer as n_class,
max(${db}_grid_irr_class.irrcapcl)::integer as i_class,
max(${db}_grid_hydgrp_class.hydgrp) as hydgrp,
max(${db}_grid_order_class.taxorder) as soilorder,
max(${db}_grid_suborder_class.taxsuborder) as suborder,
max(${db}_grid_greatgroup_class.taxgrtgroup) as greatgroup,
max(${db}_grid_taxpartsize_class.taxpartsize) as taxpartsize,
max(${db}_grid_weg_class.weg) as weg,

-- now the fraction of grid cell area for categorical variables
max(${db}_grid_str_class.area_extent) / NULLIF(sum(area_wt), 0) as str_extent,
max(${db}_soil_series.area_extent) / NULLIF(sum(area_wt), 0) as series_name_extent,
max(${db}_grid_drain_class.area_extent) / NULLIF(sum(area_wt), 0) as drainage_class_extent,
max(${db}_grid_nirr_class.area_extent) / NULLIF(sum(area_wt), 0) as n_class_extent,
max(${db}_grid_irr_class.area_extent) / NULLIF(sum(area_wt), 0) as i_class_extent,
max(${db}_grid_hydgrp_class.area_extent) / NULLIF(sum(area_wt), 0) as hydgrp_extent,
max(${db}_grid_order_class.area_extent) / NULLIF(sum(area_wt), 0) as order_extent,
max(${db}_grid_suborder_class.area_extent) / NULLIF(sum(area_wt), 0) as suborder_extent,
max(${db}_grid_greatgroup_class.area_extent) / NULLIF(sum(area_wt), 0) as greatgroup_extent,
max(${db}_grid_taxpartsize_class.area_extent) / NULLIF(sum(area_wt), 0) as taxpartsize_extent,
max(${db}_grid_weg_class.area_extent) / NULLIF(sum(area_wt), 0) as weg_extent
-- 
FROM
${db}_grid_mapunit
-- get component weights
LEFT JOIN ${db}_component_weights USING (gid)
LEFT JOIN ${db}_component_data USING (cokey)
-- join with STR data
LEFT JOIN ${db}_grid_str_class USING (grid_gid)
-- join with soil series data
LEFT JOIN ${db}_soil_series USING (grid_gid)
-- join with drainage class table
LEFT JOIN ${db}_grid_drain_class USING (grid_gid)
-- join with land classification tables
LEFT JOIN ${db}_grid_nirr_class USING (grid_gid)
LEFT JOIN ${db}_grid_irr_class USING (grid_gid)
-- join with hydrologic group table
LEFT JOIN ${db}_grid_hydgrp_class USING (grid_gid)
-- join with taxonomy tables
LEFT JOIN ${db}_grid_order_class USING (grid_gid)
LEFT JOIN ${db}_grid_suborder_class USING (grid_gid)
LEFT JOIN ${db}_grid_greatgroup_class USING (grid_gid)
LEFT JOIN ${db}_grid_taxpartsize_class USING (grid_gid)
LEFT JOIN ${db}_grid_weg_class USING (grid_gid)
-- aggregate
GROUP BY grid_gid;

-- add some helper columns and create indexes:
CREATE INDEX ${db}_gridded_properties_id_idx on conus_800m_grid.${db}_gridded_properties (grid_gid);
VACUUM ANALYZE conus_800m_grid.${db}_gridded_properties ;

EOF
)

## debugging
# note the use of double quotes: need this to preserve newlines
# echo "$sql" > test.sql

## run in DB
# note the use of double quotes: need this to preserve newlines
echo "$sql" | psql -U postgres ssurgo_combined

# 
# -- -- -- SSURGO -- -- -- 
# 
# --
# -- make table of soil properties for each grid cell
# --
# DROP TABLE conus_800m_grid.gridded_properties;
# CREATE TABLE conus_800m_grid.gridded_properties AS
# -- aggregated to grid id
# SELECT grid_gid,
# count(cokey) as number_components,
# -- these have been corrected for missing weights
# -- NULLIF: used to detect 0 and replace with NULL
# sum(wei::numeric * wei_wt) / NULLIF(sum(wei_wt), 0) as wei,
# sum(resdept * resdept_wt) / NULLIF(sum(resdept_wt), 0) as resdept,
# sum(soil_depth * soil_depth_wt) / NULLIF(sum(soil_depth_wt), 0) as soil_depth,
# sum(profile_water_storage * profile_water_storage_wt) / NULLIF(sum(profile_water_storage_wt), 0) as water_storage,
# sum(om_kg_sq_m * om_kg_sq_m_wt) / NULLIF(sum(om_kg_sq_m_wt), 0) as om_kg_sq_m,
# sum(caco3_kg_sq_m * caco3_kg_sq_m_wt) / NULLIF(sum(caco3_kg_sq_m_wt), 0) as caco3_kg_sq_m,
# sum(profile_wt_mean_sand * sand_wt) / NULLIF(sum(sand_wt), 0) as sand,
# sum(profile_wt_mean_silt * silt_wt) / NULLIF(sum(silt_wt), 0) as silt,
# sum(profile_wt_mean_clay * clay_wt) / NULLIF(sum(clay_wt), 0) as clay,
# sum(profile_wt_mean_db * db_wt) / NULLIF(sum(db_wt), 0) as db,
# sum(sar * sar_wt) / NULLIF(sum(sar_wt), 0) as sar,
# sum(ec * ec_wt) / NULLIF(sum(ec_wt), 0) as ec,
# sum(profile_wt_mean_cec * cec_wt) / NULLIF(sum(cec_wt), 0) as cec,
# sum(profile_wt_mean_ph * ph_wt) / NULLIF(sum(ph_wt), 0) as ph,
# sum(max_om * max_om_wt) / NULLIF(sum(max_om_wt), 0) as max_om,
# sum(min_ksat * min_ksat_wt) / NULLIF(sum(min_ksat_wt), 0) as min_ksat,
# sum(max_ksat * max_ksat_wt) / NULLIF(sum(max_ksat_wt), 0) as max_ksat,
# sum(mean_ksat * mean_ksat_wt) / NULLIF(sum(mean_ksat_wt), 0) as mean_ksat,
# -- slab-wise aggregates
# sum(clay_05 * clay_05_wt) / NULLIF(sum(clay_05_wt), 0) as clay_05, 
# sum(clay_025 * clay_025_wt) / NULLIF(sum(clay_025_wt), 0) as clay_025, 
# sum(clay_2550 * clay_2550_wt) / NULLIF(sum(clay_2550_wt), 0) as clay_2550, 
# 
# sum(ph_05 * ph_05_wt) / NULLIF(sum(ph_05_wt), 0) as ph_05, 
# sum(ph_025 * ph_025_wt) / NULLIF(sum(ph_025_wt), 0) as ph_025, 
# sum(ph_2550 * ph_2550_wt) / NULLIF(sum(ph_2550_wt), 0) as ph_2550, 
# 
# sum(ec_05 * ec_05_wt) / NULLIF(sum(ec_05_wt), 0) as ec_05, 
# sum(ec_025 * ec_025_wt) / NULLIF(sum(ec_025_wt), 0) as ec_025, 
# 
# sum(cec_05 * cec_05_wt) / NULLIF(sum(cec_05_wt), 0) as cec_05, 
# sum(cec_025 * cec_025_wt) / NULLIF(sum(cec_025_wt), 0) as cec_025, 
# sum(cec_050 * cec_050_wt) / NULLIF(sum(cec_050_wt), 0) as cec_050, 
# 
# sum(ksat_05 * ksat_05_wt) / NULLIF(sum(ksat_05_wt), 0) as ksat_05, 
# 
# sum(paws_025 * paws_025_wt) / NULLIF(sum(paws_025_wt), 0) as paws_025, 
# sum(paws_050 * paws_050_wt) / NULLIF(sum(paws_050_wt), 0) as paws_050, 
# sum(rf_025 * rf_025_wt) / NULLIF(sum(rf_025_wt), 0) as rf_025, 
# sum(kw_025 * kw_025_wt) / NULLIF(sum(kw_025_wt), 0) as kw_025,
# -- categorical variables that are the most extensive (by area) for each cell
# -- this is a 1:1 join so the MAX function does nothing
# max(soil_series.compname) as series_name,
# max(grid_str_class.str) AS str,
# max(grid_drain_class.drainagecl) as drainage_class,
# max(grid_nirr_class.nirrcapcl)::integer as n_class,
# max(grid_irr_class.irrcapcl)::integer as i_class,
# max(grid_hydgrp_class.hydgrp) as hydgrp,
# max(grid_order_class.taxorder) as soilorder,
# max(grid_suborder_class.taxsuborder) as suborder,
# max(grid_greatgroup_class.taxgrtgroup) as greatgroup,
# max(grid_taxpartsize_class.taxpartsize) as taxpartsize,
# max(grid_weg_class.weg) as weg,
# -- now the fraction of grid cell area for categorical variables
# max(grid_str_class.area_extent) / NULLIF(sum(area_wt), 0) as str_extent,
# max(soil_series.area_extent) / NULLIF(sum(area_wt), 0) as series_name_extent,
# max(grid_drain_class.area_extent) / NULLIF(sum(area_wt), 0) as drainage_class_extent,
# max(grid_nirr_class.area_extent) / NULLIF(sum(area_wt), 0) as n_class_extent,
# max(grid_irr_class.area_extent) / NULLIF(sum(area_wt), 0) as i_class_extent,
# max(grid_hydgrp_class.area_extent) / NULLIF(sum(area_wt), 0) as hydgrp_extent,
# max(grid_order_class.area_extent) / NULLIF(sum(area_wt), 0) as order_extent,
# max(grid_suborder_class.area_extent) / NULLIF(sum(area_wt), 0) as suborder_extent,
# max(grid_greatgroup_class.area_extent) / NULLIF(sum(area_wt), 0) as greatgroup_extent,
# max(grid_taxpartsize_class.area_extent) / NULLIF(sum(area_wt), 0) as taxpartsize_extent,
# max(grid_weg_class.area_extent) / NULLIF(sum(area_wt), 0) as weg_extent
# -- 
# FROM
# grid_mapunit
# -- get component weights
# LEFT JOIN component_weights USING (gid)
# LEFT JOIN component_data USING (cokey)
# -- join with STR data
# LEFT JOIN grid_str_class USING (grid_gid)
# -- join with soil series data
# LEFT JOIN soil_series USING (grid_gid)
# -- join with drainage class table
# LEFT JOIN grid_drain_class USING (grid_gid)
# -- join with land classification tables
# LEFT JOIN grid_nirr_class USING (grid_gid)
# LEFT JOIN grid_irr_class USING (grid_gid)
# -- join with hydrologic group table
# LEFT JOIN grid_hydgrp_class USING (grid_gid)
# -- join with taxonomy tables
# LEFT JOIN grid_order_class USING (grid_gid)
# LEFT JOIN grid_suborder_class USING (grid_gid)
# LEFT JOIN grid_greatgroup_class USING (grid_gid)
# LEFT JOIN grid_taxpartsize_class USING (grid_gid)
# LEFT JOIN grid_weg_class USING (grid_gid)
# -- aggregate
# GROUP BY grid_gid 
# -- ordering 
# ORDER BY grid_gid;
# 
# 
# -- add some helper columns and create indexes:
# CREATE INDEX gridded_properties_id_idx on conus_800m_grid.gridded_properties (grid_gid);
# VACUUM ANALYZE conus_800m_grid.gridded_properties ;
# -- -- -- SSURGO -- -- -- 
# 
# 
# -- -- -- STATSGO -- -- --
# 
# -- 
# -- new methods
# -- 
# DROP TABLE conus_800m_grid.statsgo_gridded_properties;
# CREATE TABLE conus_800m_grid.statsgo_gridded_properties AS
# -- aggregated to grid id
# SELECT grid_gid,
# count(cokey) as number_components,
# -- these have been corrected for missing weights
# sum(wei::numeric * wei_wt) / sum(wei_wt) as wei,
# sum(resdept * resdept_wt) / sum(resdept_wt) as resdept,
# sum(soil_depth * soil_depth_wt) / sum(soil_depth_wt) as soil_depth,
# sum(profile_water_storage * profile_water_storage_wt) / sum(profile_water_storage_wt) as water_storage,
# sum(om_kg_sq_m * om_kg_sq_m_wt) / sum(om_kg_sq_m_wt) as om_kg_sq_m,
# sum(caco3_kg_sq_m * caco3_kg_sq_m_wt) / sum(caco3_kg_sq_m_wt) as caco3_kg_sq_m,
# sum(profile_wt_mean_sand * sand_wt) / sum(sand_wt) as sand,
# sum(profile_wt_mean_silt * silt_wt) / sum(silt_wt) as silt,
# sum(profile_wt_mean_clay * clay_wt) / sum(clay_wt) as clay,
# sum(profile_wt_mean_db * db_wt) / sum(db_wt) as db,
# sum(sar * sar_wt) / sum(sar_wt) as sar,
# sum(ec * ec_wt) / sum(ec_wt) as ec,
# sum(profile_wt_mean_cec * cec_wt) / sum(cec_wt) as cec,
# sum(profile_wt_mean_ph * ph_wt) / sum(ph_wt) as ph,
# sum(max_om * max_om_wt) / sum(max_om_wt) as max_om,
# sum(min_ksat * min_ksat_wt) / sum(min_ksat_wt) as min_ksat,
# sum(max_ksat * max_ksat_wt) / sum(max_ksat_wt) as max_ksat,
# sum(mean_ksat * mean_ksat_wt) / sum(mean_ksat_wt) as mean_ksat,
# -- slab-wise aggregates
# sum(clay_05 * clay_05_wt) / sum(clay_05_wt) as clay_05, 
# sum(clay_025 * clay_025_wt) / sum(clay_025_wt) as clay_025, 
# sum(clay_2550 * clay_2550_wt) / sum(clay_2550_wt) as clay_2550, 
# 
# sum(ph_05 * ph_05_wt) / sum(ph_05_wt) as ph_05, 
# sum(ph_025 * ph_025_wt) / sum(ph_025_wt) as ph_025, 
# sum(ph_2550 * ph_2550_wt) / sum(ph_2550_wt) as ph_2550, 
# 
# sum(ec_05 * ec_05_wt) / sum(ec_05_wt) as ec_05, 
# sum(ec_025 * ec_025_wt) / sum(ec_025_wt) as ec_025, 
# 
# sum(cec_05 * cec_05_wt) / sum(cec_05_wt) as cec_05, 
# sum(cec_025 * cec_025_wt) / sum(cec_025_wt) as cec_025, 
# sum(cec_050 * cec_050_wt) / sum(cec_050_wt) as cec_050, 
# 
# sum(ksat_05 * ksat_05_wt) / sum(ksat_05_wt) as ksat_05, 
# 
# sum(paws_025 * paws_025_wt) / sum(paws_025_wt) as paws_025, 
# sum(paws_050 * paws_050_wt) / sum(paws_050_wt) as paws_050, 
# 
# sum(rf_025 * rf_025_wt) / sum(rf_025_wt) as rf_025, 
# sum(kw_025 * kw_025_wt) / sum(kw_025_wt) as kw_025,
# -- categorical variables that are the most extensive (by area) for each cell
# -- this is a 1:1 join so the MAX function does nothing
# max(statsgo_soil_series.compname) as series_name,
# max(statsgo_grid_str_class.str) AS str,
# max(statsgo_grid_drain_class.drainagecl) as drainage_class,
# max(statsgo_grid_nirr_class.nirrcapcl)::integer as n_class,
# max(statsgo_grid_irr_class.irrcapcl)::integer as i_class,
# max(statsgo_grid_hydgrp_class.hydgrp) as hydgrp,
# max(statsgo_grid_order_class.taxorder) as soilorder,
# max(statsgo_grid_suborder_class.taxsuborder) as suborder,
# max(statsgo_grid_greatgroup_class.taxgrtgroup) as greatgroup,
# max(statsgo_grid_taxpartsize_class.taxpartsize) as taxpartsize,
# max(statsgo_grid_weg_class.weg) as weg,
# -- fraction of each cell over which selected category is appropriate
# max(statsgo_grid_str_class.area_extent) / sum(area_wt) as str_extent,
# max(statsgo_soil_series.area_extent) / sum(area_wt) as series_name_extent,
# max(statsgo_grid_drain_class.area_extent) / sum(area_wt) as drainage_class_extent,
# max(statsgo_grid_nirr_class.area_extent) / sum(area_wt) as n_class_extent,
# max(statsgo_grid_irr_class.area_extent) / sum(area_wt) as i_class_extent,
# max(statsgo_grid_hydgrp_class.area_extent) / sum(area_wt) as hydgrp_extent,
# max(statsgo_grid_order_class.area_extent) / sum(area_wt) as order_extent,
# max(statsgo_grid_suborder_class.area_extent) / sum(area_wt) as suborder_extent,
# max(statsgo_grid_greatgroup_class.area_extent) / sum(area_wt) as greatgroup_extent,
# max(statsgo_grid_taxpartsize_class.area_extent) / sum(area_wt) as taxpartsize_extent,
# max(statsgo_grid_weg_class.area_extent) / sum(area_wt) as weg_extent
# -- 
# FROM
# conus_800m_grid.statsgo_grid_mapunit
# -- debug
# -- JOIN grid ON grid.gid = statsgo_grid_mapunit.grid_gid AND chunk = '11-40'
# -- debug
# LEFT JOIN statsgo_component_weights ON statsgo_grid_mapunit.gid = statsgo_component_weights.gid
# LEFT JOIN statsgo_component_data USING (cokey)
# -- join with STR data
# LEFT JOIN statsgo_grid_str_class USING (grid_gid)
# -- join soil series data
# LEFT JOIN statsgo_soil_series USING (grid_gid)
# -- join with drainage class table
# LEFT JOIN statsgo_grid_drain_class USING (grid_gid)
# -- join with land classification tables
# LEFT JOIN statsgo_grid_nirr_class USING (grid_gid)
# LEFT JOIN statsgo_grid_irr_class USING (grid_gid)
# -- join with hydrologic group table
# LEFT JOIN statsgo_grid_hydgrp_class USING (grid_gid)
# -- join with taxonomy tables
# LEFT JOIN statsgo_grid_order_class USING (grid_gid)
# LEFT JOIN statsgo_grid_suborder_class USING (grid_gid)
# LEFT JOIN statsgo_grid_greatgroup_class USING (grid_gid)
# LEFT JOIN statsgo_grid_taxpartsize_class USING (grid_gid)
# LEFT JOIN statsgo_grid_weg_class USING (grid_gid)
# -- aggregate
# GROUP BY grid_gid ;
# 
# 
# 
# -- add some helper columns and create indexes:
# CREATE INDEX statsgo_gridded_properties_id_idx on conus_800m_grid.statsgo_gridded_properties (grid_gid);
# VACUUM ANALYZE conus_800m_grid.statsgo_gridded_properties ;
# -- -- -- STATSGO -- -- --

