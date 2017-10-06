
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


-- 2014-06-18
-- NOTE: we don't have good CA Storie Index Values in STATSGO... use NULL for now
-- 

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
-- 2016-07-29: adapting to CONUS 800m grid
--
-- TODO: add indexing!


SET search_path TO conus_800m_grid, public ;
SET work_mem to 800000 ;
\timing


-- 
-- most extensive soil series
-- slow... ideas? 
-- https://stackoverflow.com/questions/3800551/select-first-row-in-each-group-by-group/7630564#7630564
--
CREATE TEMP TABLE statsgo_compname_normalized AS
SELECT
mukey, 
UPPER(REPLACE(REPLACE(REPLACE(compname, ' family', ''), ' variant', ''), ' taxadjunct', '')) as compname,
SUM(comppct_r::numeric/100.0) AS pct
FROM statsgo.component
GROUP BY mukey, UPPER(REPLACE(REPLACE(REPLACE(compname, ' family', ''), ' variant', ''), ' taxadjunct', ''))
ORDER BY mukey, pct DESC;

-- remove non-recognized soil series 
DELETE FROM statsgo_compname_normalized WHERE compname NOT IN (SELECT UPPER(seriesname) FROM osd.taxa);

CREATE INDEX statsgo_compname_normalized_mukey_idx ON statsgo_compname_normalized (mukey);
CREATE INDEX statsgo_compname_normalized_compname_idx ON statsgo_compname_normalized (compname);
VACUUM ANALYZE statsgo_compname_normalized;

-- finish table
CREATE TEMP TABLE statsgo_soil_series AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * pct) as area_extent, compname
FROM 
statsgo_grid_mapunit 
JOIN statsgo_compname_normalized USING (mukey)
-- debug
-- JOIN grid ON grid.gid = statsgo_grid_mapunit.grid_gid AND chunk = '11-40'
-- debug
GROUP BY grid_gid, compname
ORDER BY grid_gid, area_extent DESC ;

-- index
CREATE INDEX statsgo_soil_series_idx ON statsgo_soil_series (grid_gid);
VACUUM ANALYZE statsgo_soil_series;


-- 
-- get the most extensive drainage class value by grid cell [tested]
-- 79 seconds
-- 
CREATE TEMP TABLE statsgo_grid_drain_class AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, drainagecl
FROM conus_800m_grid.statsgo_grid_mapunit 
-- debug
-- JOIN grid ON grid.gid = statsgo_grid_mapunit.grid_gid AND chunk = '11-40'
-- debug
JOIN statsgo.component USING (mukey) 
WHERE drainagecl IS NOT NULL
GROUP BY grid_gid, drainagecl
ORDER BY grid_gid, area_extent DESC ;

-- index
CREATE INDEX statsgo_grid_drain_class_idx ON statsgo_grid_drain_class (grid_gid);
VACUUM ANALYZE statsgo_grid_drain_class;


-- 
-- get the most extensive nirrcapcl value by grid cell [tested]
-- 
CREATE TEMP TABLE statsgo_grid_nirr_class AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, nirrcapcl
FROM conus_800m_grid.statsgo_grid_mapunit
-- debug
-- JOIN grid ON grid.gid = statsgo_grid_mapunit.grid_gid AND chunk = '11-40'
-- debug
JOIN statsgo.component USING (mukey) 
WHERE nirrcapcl IS NOT NULL
GROUP BY grid_gid, nirrcapcl
ORDER BY grid_gid, area_extent DESC ;

-- index
CREATE INDEX statsgo_grid_nirr_class_idx ON statsgo_grid_nirr_class (grid_gid);
VACUUM ANALYZE statsgo_grid_drain_class;


-- 
-- get the most extensive irrcapcl value by grid cell [tested]
-- 
CREATE TEMP TABLE statsgo_grid_irr_class AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, irrcapcl
FROM conus_800m_grid.statsgo_grid_mapunit
-- debug
-- JOIN grid ON grid.gid = statsgo_grid_mapunit.grid_gid AND chunk = '11-40'
-- debug
JOIN statsgo.component USING (mukey) 
WHERE irrcapcl IS NOT NULL
GROUP BY grid_gid, irrcapcl
ORDER BY grid_gid, area_extent DESC ;

-- index
CREATE INDEX statsgo_grid_irr_class_idx ON statsgo_grid_irr_class (grid_gid);
VACUUM ANALYZE statsgo_grid_irr_class;


-- 
-- get the most extensive hydgrp value by grid cell [tested]
-- 
CREATE TEMP TABLE statsgo_grid_hydgrp_class AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, hydgrp
FROM conus_800m_grid.statsgo_grid_mapunit
-- debug
-- JOIN grid ON grid.gid = statsgo_grid_mapunit.grid_gid AND chunk = '11-40'
-- debug
JOIN statsgo.component USING (mukey) 
WHERE hydgrp IS NOT NULL
GROUP BY grid_gid, hydgrp
ORDER BY grid_gid, area_extent DESC ;

-- index
CREATE INDEX statsgo_grid_hydgrp_class_idx ON statsgo_grid_hydgrp_class (grid_gid);
VACUUM ANALYZE statsgo_grid_hydgrp_class;



-- 
-- get the most extensive greatgroup taxonomy 
-- 
-- 
CREATE TEMP TABLE statsgo_grid_greatgroup_class AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, taxgrtgroup
FROM conus_800m_grid.statsgo_grid_mapunit
-- debug
-- JOIN grid ON grid.gid = statsgo_grid_mapunit.grid_gid AND chunk = '11-40'
-- debug
JOIN statsgo.component USING (mukey) 
WHERE taxgrtgroup IS NOT NULL
GROUP BY grid_gid, taxgrtgroup
ORDER BY grid_gid, area_extent DESC ;

-- index
CREATE INDEX statsgo_grid_greatgroup_class_idx ON statsgo_grid_greatgroup_class (grid_gid);
VACUUM ANALYZE statsgo_grid_greatgroup_class;



-- 
-- get most extensive STR
-- 
CREATE TEMP TABLE statsgo_grid_str_class AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, taxtempregime as str
FROM conus_800m_grid.statsgo_grid_mapunit
-- debug
-- JOIN grid ON grid.gid = statsgo_grid_mapunit.grid_gid AND chunk = '11-40'
-- debug
JOIN statsgo.component 
USING (mukey) 
WHERE taxtempregime IS NOT NULL
GROUP BY grid_gid, taxtempregime
ORDER BY grid_gid, area_extent DESC ;

-- index
CREATE INDEX statsgo_grid_str_class_idx ON statsgo_grid_str_class (grid_gid);
VACUUM ANALYZE statsgo_grid_str_class;



-- 
-- get most extensive soil order
-- 
CREATE TEMP TABLE statsgo_grid_order_class AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, taxorder
FROM conus_800m_grid.statsgo_grid_mapunit 
-- debug
-- JOIN grid ON grid.gid = statsgo_grid_mapunit.grid_gid AND chunk = '11-40'
-- debug
JOIN statsgo.component USING (mukey) 
WHERE taxorder IS NOT NULL
GROUP BY grid_gid, taxorder
ORDER BY grid_gid, area_extent DESC ;


-- index
CREATE INDEX statsgo_grid_order_class_idx ON statsgo_grid_order_class (grid_gid);
VACUUM ANALYZE statsgo_grid_order_class;




-- 
-- get most extensive suborder
-- 
CREATE TEMP TABLE statsgo_grid_suborder_class AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, taxsuborder
FROM conus_800m_grid.statsgo_grid_mapunit 
-- debug
-- JOIN grid ON grid.gid = statsgo_grid_mapunit.grid_gid AND chunk = '11-40'
-- debug
JOIN statsgo.component USING (mukey) 
WHERE taxsuborder IS NOT NULL
GROUP BY grid_gid, taxsuborder
ORDER BY grid_gid, area_extent DESC ;

-- index
CREATE INDEX statsgo_grid_suborder_class_idx ON statsgo_grid_suborder_class (grid_gid);
VACUUM ANALYZE statsgo_grid_suborder_class;




-- 
-- get most extensive particle size class
-- 
CREATE TEMP TABLE statsgo_grid_taxpartsize_class AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, taxpartsize
FROM conus_800m_grid.statsgo_grid_mapunit
-- debug
-- JOIN grid ON grid.gid = statsgo_grid_mapunit.grid_gid AND chunk = '11-40'
-- debug
JOIN statsgo.component USING (mukey) 
WHERE taxpartsize IS NOT NULL
GROUP BY grid_gid, taxpartsize
ORDER BY grid_gid, area_extent DESC ;

-- index
CREATE INDEX statsgo_grid_taxpartsize_class_idx ON statsgo_grid_taxpartsize_class (grid_gid);
VACUUM ANALYZE statsgo_grid_taxpartsize_class;



-- 
-- get most extensive WEG
-- 
CREATE TEMP TABLE statsgo_grid_weg_class AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, weg
FROM conus_800m_grid.statsgo_grid_mapunit
-- debug
-- JOIN grid ON grid.gid = statsgo_grid_mapunit.grid_gid AND chunk = '11-40'
-- debug
JOIN statsgo.component USING (mukey) 
WHERE weg IS NOT NULL
GROUP BY grid_gid, weg
ORDER BY grid_gid, area_extent DESC ;

-- index
CREATE INDEX statsgo_grid_weg_class_idx ON statsgo_grid_weg_class (grid_gid);
VACUUM ANALYZE statsgo_grid_weg_class;


-- -- -- hz / component data prep used to be here -- -- --




-- 
-- create a table of component weights: takes a while to run (13 minutes)
-- with NULL weights when specific values are missing
-- 
DROP TABLE conus_800m_grid.statsgo_component_weights;
CREATE TABLE conus_800m_grid.statsgo_component_weights as
SELECT statsgo_grid_mapunit.gid, cokey, 
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
conus_800m_grid.statsgo_grid_mapunit
-- debug
-- JOIN grid ON grid.gid = statsgo_grid_mapunit.grid_gid AND chunk = '11-40'
-- debug
JOIN statsgo_component_data USING (mukey);

-- index
CREATE UNIQUE INDEX statsgo_component_weights_idx ON conus_800m_grid.statsgo_component_weights (gid,cokey);
VACUUM ANALYZE conus_800m_grid.statsgo_component_weights;





-- 
-- new methods
-- 
DROP TABLE conus_800m_grid.statsgo_gridded_properties;
CREATE TABLE conus_800m_grid.statsgo_gridded_properties AS
-- aggregated to grid id
SELECT grid_gid,
count(cokey) as number_components,
-- these have been corrected for missing weights
sum(wei::numeric * wei_wt) / sum(wei_wt) as wei,
sum(resdept * resdept_wt) / sum(resdept_wt) as resdept,
sum(soil_depth * soil_depth_wt) / sum(soil_depth_wt) as soil_depth,
sum(profile_water_storage * profile_water_storage_wt) / sum(profile_water_storage_wt) as water_storage,
sum(om_kg_sq_m * om_kg_sq_m_wt) / sum(om_kg_sq_m_wt) as om_kg_sq_m,
sum(caco3_kg_sq_m * caco3_kg_sq_m_wt) / sum(caco3_kg_sq_m_wt) as caco3_kg_sq_m,
sum(profile_wt_mean_sand * sand_wt) / sum(sand_wt) as sand,
sum(profile_wt_mean_silt * silt_wt) / sum(silt_wt) as silt,
sum(profile_wt_mean_clay * clay_wt) / sum(clay_wt) as clay,
sum(profile_wt_mean_db * db_wt) / sum(db_wt) as db,
sum(sar * sar_wt) / sum(sar_wt) as sar,
sum(ec * ec_wt) / sum(ec_wt) as ec,
sum(profile_wt_mean_cec * cec_wt) / sum(cec_wt) as cec,
sum(profile_wt_mean_ph * ph_wt) / sum(ph_wt) as ph,
sum(max_om * max_om_wt) / sum(max_om_wt) as max_om,
sum(min_ksat * min_ksat_wt) / sum(min_ksat_wt) as min_ksat,
sum(max_ksat * max_ksat_wt) / sum(max_ksat_wt) as max_ksat,
sum(mean_ksat * mean_ksat_wt) / sum(mean_ksat_wt) as mean_ksat,
-- slab-wise aggregates
sum(clay_05 * clay_05_wt) / sum(clay_05_wt) as clay_05, 
sum(clay_025 * clay_025_wt) / sum(clay_025_wt) as clay_025, 
sum(clay_2550 * clay_2550_wt) / sum(clay_2550_wt) as clay_2550, 

sum(ph_05 * ph_05_wt) / sum(ph_05_wt) as ph_05, 
sum(ph_025 * ph_025_wt) / sum(ph_025_wt) as ph_025, 
sum(ph_2550 * ph_2550_wt) / sum(ph_2550_wt) as ph_2550, 

sum(ec_05 * ec_05_wt) / sum(ec_05_wt) as ec_05, 
sum(ec_025 * ec_025_wt) / sum(ec_025_wt) as ec_025, 

sum(cec_05 * cec_05_wt) / sum(cec_05_wt) as cec_05, 
sum(cec_025 * cec_025_wt) / sum(cec_025_wt) as cec_025, 
sum(cec_050 * cec_050_wt) / sum(cec_050_wt) as cec_050, 

sum(ksat_05 * ksat_05_wt) / sum(ksat_05_wt) as ksat_05, 

sum(paws_025 * paws_025_wt) / sum(paws_025_wt) as paws_025, 
sum(paws_050 * paws_050_wt) / sum(paws_050_wt) as paws_050, 

sum(rf_025 * rf_025_wt) / sum(rf_025_wt) as rf_025, 
sum(kw_025 * kw_025_wt) / sum(kw_025_wt) as kw_025,
-- categorical variables that are the most extensive (by area) for each cell
-- this is a 1:1 join so the MAX function does nothing
max(statsgo_soil_series.compname) as series_name,
max(statsgo_grid_str_class.str) AS str,
max(statsgo_grid_drain_class.drainagecl) as drainage_class,
max(statsgo_grid_nirr_class.nirrcapcl)::integer as n_class,
max(statsgo_grid_irr_class.irrcapcl)::integer as i_class,
max(statsgo_grid_hydgrp_class.hydgrp) as hydgrp,
max(statsgo_grid_order_class.taxorder) as soilorder,
max(statsgo_grid_suborder_class.taxsuborder) as suborder,
max(statsgo_grid_greatgroup_class.taxgrtgroup) as greatgroup,
max(statsgo_grid_taxpartsize_class.taxpartsize) as taxpartsize,
max(statsgo_grid_weg_class.weg) as weg,
-- fraction of each cell over which selected category is appropriate
max(statsgo_grid_str_class.area_extent) / sum(area_wt) as str_extent,
max(statsgo_soil_series.area_extent) / sum(area_wt) as series_name_extent,
max(statsgo_grid_drain_class.area_extent) / sum(area_wt) as drainage_class_extent,
max(statsgo_grid_nirr_class.area_extent) / sum(area_wt) as n_class_extent,
max(statsgo_grid_irr_class.area_extent) / sum(area_wt) as i_class_extent,
max(statsgo_grid_hydgrp_class.area_extent) / sum(area_wt) as hydgrp_extent,
max(statsgo_grid_order_class.area_extent) / sum(area_wt) as order_extent,
max(statsgo_grid_suborder_class.area_extent) / sum(area_wt) as suborder_extent,
max(statsgo_grid_greatgroup_class.area_extent) / sum(area_wt) as greatgroup_extent,
max(statsgo_grid_taxpartsize_class.area_extent) / sum(area_wt) as taxpartsize_extent,
max(statsgo_grid_weg_class.area_extent) / sum(area_wt) as weg_extent
-- 
FROM
conus_800m_grid.statsgo_grid_mapunit
-- debug
-- JOIN grid ON grid.gid = statsgo_grid_mapunit.grid_gid AND chunk = '11-40'
-- debug
LEFT JOIN statsgo_component_weights ON statsgo_grid_mapunit.gid = statsgo_component_weights.gid
LEFT JOIN statsgo_component_data USING (cokey)
-- join with STR data
LEFT JOIN statsgo_grid_str_class USING (grid_gid)
-- join soil series data
LEFT JOIN statsgo_soil_series USING (grid_gid)
-- join with drainage class table
LEFT JOIN statsgo_grid_drain_class USING (grid_gid)
-- join with land classification tables
LEFT JOIN statsgo_grid_nirr_class USING (grid_gid)
LEFT JOIN statsgo_grid_irr_class USING (grid_gid)
-- join with hydrologic group table
LEFT JOIN statsgo_grid_hydgrp_class USING (grid_gid)
-- join with taxonomy tables
LEFT JOIN statsgo_grid_order_class USING (grid_gid)
LEFT JOIN statsgo_grid_suborder_class USING (grid_gid)
LEFT JOIN statsgo_grid_greatgroup_class USING (grid_gid)
LEFT JOIN statsgo_grid_taxpartsize_class USING (grid_gid)
LEFT JOIN statsgo_grid_weg_class USING (grid_gid)
-- aggregate
GROUP BY grid_gid ;



-- add some helper columns and create indexes:
CREATE INDEX statsgo_gridded_properties_id_idx on conus_800m_grid.statsgo_gridded_properties (grid_gid);
VACUUM ANALYZE conus_800m_grid.statsgo_gridded_properties ;

-- -- permissions
-- GRANT SELECT on conus_800m_grid.statsgo_gridded_properties to soil ;
-- GRANT SELECT on conus_800m_grid.statsgo_grid_mapunit to soil ;








