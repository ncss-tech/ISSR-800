
-- 
-- 2010-12-01
-- I updated this code so that weights are computed based on the presense/absense of each soil property that we are including in the final product.
-- 

-- 
-- 2012-09-26
-- added depth to restrictive feature, taxpartsize, depth-sum CaCO3
-- 

-- 2013-02-26
-- fixed CaCO3 interpretion as percent: forgot to divide by 100

--
-- 2014-06-18
-- using a temp NASIS export of the recently updated CA Storie Index values
-- note that there are about 1% of the records missing data due to mis-matching component names (NASIS vs. SSURGO 2014-01-01)

--
-- 2014-06-19
-- fixed a nasty bug in the aggregation of component-level categorical data, should have been grouping categories by grid cell ID and summing their area extent instead of picking the most extensive single value
-- original data were off in about 10% of cases
--


--
-- 2014-07-23: new properties: 
-- get function from 4km statsgo project for doing depth-slices
--
-- PAW at:  0-25 cm; 0-50 [ OK ]
-- EC: surface and 0-25 [ OK ]
-- pH; surface and 0-25 [ OK ]
-- CEC: top layer; 0-25 and 0-50 [ OK ]
-- Ksat- surface [ OK ]
-- Soil temperature regime [ OK ]
-- depth to dominant component restrictive layer [ currently have weighted mean ]
-- Rock content 0-25; Depth sum of profile [ ??? ]
-- Erodibility factor (kw I think…I want whole soil) for surface horizon and the next horizon below it. [ ??? ]
-- Soil moisture regime [ we don't have this ]


--
-- 2015-01-07: new SSURGO data
-- new SSURGO data, correct CA Storie Index values are back in the cointerp table



--
-- tabulate component name fractions, keep top 10 / grid cell
--


--
-- get the most common soil color (r,g,b triplet) by grid cell, using the most likely component that has color data
--


--
-- 2016-08-01: CONUS AT 800m
--


SET search_path TO conus_800m_grid, public ;
SET work_mem to 800000 ;
\timing


-- 
-- use the pre-made soilweb normalized compname table
-- 
CREATE TABLE soil_series AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * pct) as area_extent, 
series as compname
FROM grid_mapunit 
JOIN soilweb.comp_data USING (mukey) 
GROUP BY grid_gid, compname
ORDER BY grid_gid, area_extent DESC ;

-- index
CREATE INDEX soil_series_idx ON soil_series (grid_gid);
VACUUM ANALYZE soil_series;


-- 
-- get the most extensive drainage class value by grid cell [tested]
-- 15 seconds
-- 
CREATE TABLE grid_drain_class AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, drainagecl
FROM grid_mapunit 
JOIN ssurgo.component USING (mukey) 
WHERE drainagecl IS NOT NULL
GROUP BY grid_gid, drainagecl
ORDER BY grid_gid, area_extent DESC ;

-- index
CREATE INDEX grid_drain_class_idx ON grid_drain_class (grid_gid);
VACUUM ANALYZE grid_drain_class;


-- 
-- get the most extensive nirrcapcl value by grid cell [tested]
-- 14 seconds
-- 
CREATE TABLE grid_nirr_class AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, nirrcapcl
FROM grid_mapunit 
JOIN ssurgo.component USING (mukey) 
WHERE nirrcapcl IS NOT NULL
GROUP BY grid_gid, nirrcapcl
ORDER BY grid_gid, area_extent DESC ;

-- index
CREATE INDEX grid_nirr_class_idx ON grid_nirr_class (grid_gid);
VACUUM ANALYZE grid_nirr_class;

-- 
-- get the most extensive irrcapcl value by grid cell [tested]
-- 14 seconds
-- 
CREATE TABLE grid_irr_class AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, irrcapcl
FROM grid_mapunit 
JOIN ssurgo.component USING (mukey)
WHERE irrcapcl IS NOT NULL
GROUP BY grid_gid, irrcapcl
ORDER BY grid_gid, area_extent DESC ;

-- index
CREATE INDEX grid_irr_class_idx ON grid_irr_class (grid_gid);
VACUUM ANALYZE grid_irr_class;


-- 
-- get the most extensive hydgrp value by grid cell [tested]
-- 
CREATE TABLE grid_hydgrp_class AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, hydgrp
FROM grid_mapunit 
JOIN ssurgo.component USING (mukey)
WHERE hydgrp IS NOT NULL
GROUP BY grid_gid, hydgrp
ORDER BY grid_gid, area_extent DESC ;

CREATE INDEX grid_hydgrp_class_idx ON grid_hydgrp_class (grid_gid);
VACUUM ANALYZE grid_hydgrp_class;


-- 
-- get the most extensive greatgroup taxonomy 
-- 
CREATE TABLE grid_greatgroup_class AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, taxgrtgroup
FROM grid_mapunit 
JOIN ssurgo.component USING (mukey)
WHERE taxgrtgroup IS NOT NULL
GROUP BY grid_gid, taxgrtgroup
ORDER BY grid_gid, area_extent DESC ;

CREATE INDEX grid_greatgroup_class_idx ON grid_greatgroup_class (grid_gid);
VACUUM ANALYZE grid_greatgroup_class;


-- 
-- get most extensive STR
-- 
CREATE TABLE grid_str_class AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, taxtempregime as str
FROM grid_mapunit 
JOIN ssurgo.component USING (mukey) 
WHERE taxtempregime IS NOT NULL
GROUP BY grid_gid, taxtempregime
ORDER BY grid_gid, area_extent DESC ;

CREATE INDEX grid_str_class_idx ON grid_str_class (grid_gid);
VACUUM ANALYZE grid_str_class;



-- 
-- get most extensive soil order
-- 
CREATE TABLE grid_order_class AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, taxorder
FROM grid_mapunit 
JOIN ssurgo.component USING (mukey) 
WHERE taxorder IS NOT NULL
GROUP BY grid_gid, taxorder
ORDER BY grid_gid, area_extent DESC ;

CREATE INDEX grid_order_class_idx ON grid_order_class (grid_gid);
VACUUM ANALYZE grid_order_class;


-- 
-- get most extensive suborder
-- 
CREATE TABLE grid_suborder_class AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, taxsuborder
FROM grid_mapunit 
JOIN ssurgo.component USING (mukey) 
WHERE taxsuborder IS NOT NULL
GROUP BY grid_gid, taxsuborder
ORDER BY grid_gid, area_extent DESC ;

CREATE INDEX grid_suborder_class_idx ON grid_suborder_class (grid_gid);
VACUUM ANALYZE grid_suborder_class;


-- 
-- get most extensive particle size class
-- 
CREATE TABLE grid_taxpartsize_class AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, taxpartsize
FROM grid_mapunit 
JOIN ssurgo.component USING (mukey) 
WHERE taxpartsize IS NOT NULL
GROUP BY grid_gid, taxpartsize
ORDER BY grid_gid, area_extent DESC ;

CREATE INDEX grid_taxpartsize_class_idx ON grid_taxpartsize_class (grid_gid);
VACUUM ANALYZE grid_taxpartsize_class;


-- 
-- get most extensive WEG
-- 
CREATE TABLE grid_weg_class AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, weg
FROM grid_mapunit 
JOIN ssurgo.component USING (mukey) 
WHERE weg IS NOT NULL
GROUP BY grid_gid, weg
ORDER BY grid_gid, area_extent DESC ;


CREATE INDEX grid_weg_class_idx ON grid_weg_class (grid_gid);
VACUUM ANALYZE grid_weg_class;



-- -- -- hz / component data prep used to be here -- -- --




-- 
-- create a table of component weights: takes a while to run (1 minutes)
-- with NULL weights when specific values are missing
-- 
DROP TABLE conus_800m_grid.component_weights;
CREATE TABLE conus_800m_grid.component_weights as
SELECT gid, cokey, 
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
component_data
JOIN grid_mapunit USING (mukey);

-- index 
CREATE UNIQUE INDEX component_weights_idx ON component_weights (gid,cokey);
CREATE INDEX component_weights_idx2 ON component_weights (gid);
VACUUM ANALYZE component_weights;





--
-- make table of soil properties for each grid cell
--
DROP TABLE conus_800m_grid.gridded_properties;
CREATE TABLE conus_800m_grid.gridded_properties AS
-- aggregated to grid id
SELECT grid_gid,
count(cokey) as number_components,
-- these have been corrected for missing weights
-- NULLIF: used to detect 0 and replace with NULL
sum(wei::numeric * wei_wt) / NULLIF(sum(wei_wt), 0) as wei,
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
max(soil_series.compname) as series_name,
max(grid_str_class.str) AS str,
max(grid_drain_class.drainagecl) as drainage_class,
max(grid_nirr_class.nirrcapcl)::integer as n_class,
max(grid_irr_class.irrcapcl)::integer as i_class,
max(grid_hydgrp_class.hydgrp) as hydgrp,
max(grid_order_class.taxorder) as soilorder,
max(grid_suborder_class.taxsuborder) as suborder,
max(grid_greatgroup_class.taxgrtgroup) as greatgroup,
max(grid_taxpartsize_class.taxpartsize) as taxpartsize,
max(grid_weg_class.weg) as weg,
-- now the fraction of grid cell area for categorical variables
max(grid_str_class.area_extent) / NULLIF(sum(area_wt), 0) as str_extent,
max(soil_series.area_extent) / NULLIF(sum(area_wt), 0) as series_name_extent,
max(grid_drain_class.area_extent) / NULLIF(sum(area_wt), 0) as drainage_class_extent,
max(grid_nirr_class.area_extent) / NULLIF(sum(area_wt), 0) as n_class_extent,
max(grid_irr_class.area_extent) / NULLIF(sum(area_wt), 0) as i_class_extent,
max(grid_hydgrp_class.area_extent) / NULLIF(sum(area_wt), 0) as hydgrp_extent,
max(grid_order_class.area_extent) / NULLIF(sum(area_wt), 0) as order_extent,
max(grid_suborder_class.area_extent) / NULLIF(sum(area_wt), 0) as suborder_extent,
max(grid_greatgroup_class.area_extent) / NULLIF(sum(area_wt), 0) as greatgroup_extent,
max(grid_taxpartsize_class.area_extent) / NULLIF(sum(area_wt), 0) as taxpartsize_extent,
max(grid_weg_class.area_extent) / NULLIF(sum(area_wt), 0) as weg_extent
-- 
FROM
grid_mapunit
-- get component weights
LEFT JOIN component_weights USING (gid)
LEFT JOIN component_data USING (cokey)
-- join with STR data
LEFT JOIN grid_str_class USING (grid_gid)
-- join with soil series data
LEFT JOIN soil_series USING (grid_gid)
-- join with drainage class table
LEFT JOIN grid_drain_class USING (grid_gid)
-- join with land classification tables
LEFT JOIN grid_nirr_class USING (grid_gid)
LEFT JOIN grid_irr_class USING (grid_gid)
-- join with hydrologic group table
LEFT JOIN grid_hydgrp_class USING (grid_gid)
-- join with taxonomy tables
LEFT JOIN grid_order_class USING (grid_gid)
LEFT JOIN grid_suborder_class USING (grid_gid)
LEFT JOIN grid_greatgroup_class USING (grid_gid)
LEFT JOIN grid_taxpartsize_class USING (grid_gid)
LEFT JOIN grid_weg_class USING (grid_gid)
-- aggregate
GROUP BY grid_gid 
-- ordering 
ORDER BY grid_gid;


-- add some helper columns and create indexes:
CREATE INDEX gridded_properties_id_idx on conus_800m_grid.gridded_properties (grid_gid);
VACUUM ANALYZE conus_800m_grid.gridded_properties ;

-- -- permissions
-- GRANT SELECT on conus_800m_grid.grid_mapunit to soil ;
-- GRANT SELECT on conus_800m_grid.gridded_properties to soil ;


