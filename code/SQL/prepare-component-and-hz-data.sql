-- Prepare horizon and component data for SSURGO / STATSGO
-- 2017-07-31
-- D.E. Beaudette

-- Notes:
-- * this is relatively fast as we don't have to touch the grid tables
-- * final results saved as permanent tables

-- TODO:
-- * convert into script to share code between databases

SET search_path TO conus_800m_grid, public ;
SET work_mem to 800000 ;
\timing



--
-- STATSGO
--


-- 
-- get the top of the shallowest restrictive feature for all components
-- 
CREATE TEMP TABLE statsgo_restrictive_feature_depths AS
SELECT distinct ON (cokey) cokey, resdept_r as resdept
FROM statsgo.corestrictions
-- distinct is evaluated after the ordering, thus we use this to pick the top feature
order by cokey, resdept_r ASC;


--
-- make subset of horizon data: 
--
CREATE TEMP TABLE statsgo_hz_data AS
SELECT chkey, cokey, 
-- summed values: convert OM and CaCO3 to fractions
hzdept_r AS top, hzdepb_r AS bottom, (hzdepb_r - hzdept_r) as thick, awc_r as awc, om_r/100.0 as om, caco3_r/100.0 as caco3,
-- weighted variables
sandtotal_r as sand, CASE WHEN sandtotal_r is NULL THEN NULL ELSE (hzdepb_r - hzdept_r) END as sand_wt,
silttotal_r as silt, CASE WHEN silttotal_r is NULL THEN NULL ELSE (hzdepb_r - hzdept_r) END as silt_wt,
claytotal_r as clay, CASE WHEN claytotal_r is NULL THEN NULL ELSE (hzdepb_r - hzdept_r) END as clay_wt,
dbovendry_r as db, CASE WHEN dbovendry_r is NULL THEN NULL ELSE (hzdepb_r - hzdept_r) END as db_wt,
cec7_r as cec, CASE WHEN cec7_r is NULL THEN NULL ELSE (hzdepb_r - hzdept_r) END as cec_wt,
ph1to1h2o_r as ph, CASE WHEN ph1to1h2o_r is NULL THEN NULL ELSE (hzdepb_r - hzdept_r) END as ph_wt,
sar_r as sar, CASE WHEN sar_r IS NULL THEN NULL ELSE (hzdepb_r - hzdept_r) END as sar_wt,
ec_r as ec, CASE WHEN ec_r IS NULL THEN NULL ELSE (hzdepb_r - hzdept_r) END as ec_wt,
-- un-weighted values
ksat_r as ksat, kwfact::numeric as kw,
COALESCE(soil_fraction, 1) as soil_fraction
FROM statsgo.chorizon 
LEFT JOIN
	(
	-- total rock fragment percent
	SELECT chkey, (100.0 - sum(COALESCE(fragvol_r, 0))) / 100.0 as soil_fraction
	FROM statsgo.chfrags
	GROUP BY chkey
	) as frag_data
USING (chkey)
ORDER BY cokey, top ASC;




-- 
-- aggregate to component level: 
-- note that this table only contains components that HAVE at least soil depth data
-- 
CREATE TEMP TABLE statsgo_component_data_1 AS
SELECT cokey, 
-- component-level data: unity aggregates
max(mukey) as mukey, max(comppct_r::numeric/100.0) as comppct_r, max(wei) as wei, max(resdept) as resdept,
-- profile totals
sum(thick) as soil_depth,
sum(thick * awc) as profile_water_storage,
sum(thick * om * soil_fraction * db * 10) as om_kg_sq_m,
sum(thick * caco3 * soil_fraction * db * 10) as caco3_kg_sq_m,
-- hz thickness wt-mean values
sum(sand_wt * sand) / sum(sand_wt) as profile_wt_mean_sand,
sum(silt_wt * silt) / sum(silt_wt) as profile_wt_mean_silt,
sum(clay_wt * clay) / sum(clay_wt) as profile_wt_mean_clay,
sum(db_wt * db) / sum(db_wt) as profile_wt_mean_db,
sum(cec_wt * cec) / sum(cec_wt) as profile_wt_mean_cec,
sum(ph_wt * ph) / sum(ph_wt) as profile_wt_mean_ph,
-- profile max
max(sar) as sar,
max(ec) as ec,
max(om) as max_om,
-- ksat values
min(ksat) as min_ksat,
max(ksat) as max_ksat,
avg(ksat) as mean_ksat
FROM statsgo_hz_data
JOIN statsgo.component USING (cokey)
LEFT JOIN statsgo_restrictive_feature_depths USING (cokey)
GROUP BY cokey 
-- filter out those soils that have a NULL soil depth
HAVING sum(thick) IS NOT NULL AND sum(thick) > 0 
ORDER BY cokey ;


-- 
-- component-level slab summaries
-- 
CREATE TEMP TABLE statsgo_component_data_2 AS
SELECT statsgo_component_data_1.cokey,
clay_05, clay_025, clay_2550, 
ph_05, ph_025, ph_2550, 
ec_05, ec_025, 
cec_05, cec_025, cec_050, 
ksat_05, 
paws_025, paws_050, 
rf_025, 
kw_025
FROM
statsgo_component_data_1 
--- thickness weighted by depth interval
LEFT JOIN (SELECT id AS cokey, prop as clay_05 FROM slab_mean('statsgo_hz_data', 'clay', 0, 5, 'cokey', 'top', 'bottom')) as a1 USING (cokey)
LEFT JOIN (SELECT id AS cokey, prop as clay_025 FROM slab_mean('statsgo_hz_data', 'clay', 0, 25, 'cokey', 'top', 'bottom')) as a2 USING (cokey)
LEFT JOIN (SELECT id AS cokey, prop as clay_2550 FROM slab_mean('statsgo_hz_data', 'clay', 25, 50, 'cokey', 'top', 'bottom')) as a3 USING (cokey)

LEFT JOIN (SELECT id AS cokey, prop as ph_05 FROM slab_mean('statsgo_hz_data', 'ph', 0, 5, 'cokey', 'top', 'bottom')) as b1 USING (cokey)
LEFT JOIN (SELECT id AS cokey, prop as ph_025 FROM slab_mean('statsgo_hz_data', 'ph', 0, 25, 'cokey', 'top', 'bottom')) as b2 USING (cokey)
LEFT JOIN (SELECT id AS cokey, prop as ph_2550 FROM slab_mean('statsgo_hz_data', 'ph', 25, 50, 'cokey', 'top', 'bottom')) as b3 USING (cokey)

LEFT JOIN (SELECT id AS cokey, prop as ec_05 FROM slab_mean('statsgo_hz_data', 'ec', 0, 5, 'cokey', 'top', 'bottom')) as c1 USING (cokey)
LEFT JOIN (SELECT id AS cokey, prop as ec_025 FROM slab_mean('statsgo_hz_data', 'ec', 0, 25, 'cokey', 'top', 'bottom')) as c2 USING (cokey)

LEFT JOIN (SELECT id AS cokey, prop as cec_05 FROM slab_mean('statsgo_hz_data', 'cec', 0, 5, 'cokey', 'top', 'bottom')) as d1 USING (cokey)
LEFT JOIN (SELECT id AS cokey, prop as cec_025 FROM slab_mean('statsgo_hz_data', 'cec', 0, 25, 'cokey', 'top', 'bottom')) as d2 USING (cokey)
LEFT JOIN (SELECT id AS cokey, prop as cec_050 FROM slab_mean('statsgo_hz_data', 'cec', 0, 50, 'cokey', 'top', 'bottom')) as d3 USING (cokey)

LEFT JOIN (SELECT id AS cokey, prop as ksat_05 FROM slab_mean('statsgo_hz_data', 'ksat', 0, 5, 'cokey', 'top', 'bottom')) as e USING (cokey)

-- available water storage 0-25 and 0-50 cm
-- this works because we are summing 1-cm slices within our interval
LEFT JOIN (SELECT id AS cokey, prop as paws_025 FROM slab_sum('statsgo_hz_data', 'awc', 0, 25, 'cokey', 'top', 'bottom')) as f1 USING (cokey)
LEFT JOIN (SELECT id AS cokey, prop as paws_050 FROM slab_sum('statsgo_hz_data', 'awc', 0, 50, 'cokey', 'top', 'bottom')) as f2 USING (cokey)

-- not sure about these
LEFT JOIN (SELECT id AS cokey, (1 - prop) as rf_025 FROM slab_mean('statsgo_hz_data', 'soil_fraction', 0, 25, 'cokey', 'top', 'bottom')) as g USING (cokey)
LEFT JOIN (SELECT id AS cokey, prop as kw_025 FROM slab_mean('statsgo_hz_data', 'kw', 0, 25, 'cokey', 'top', 'bottom')) as h USING (cokey)
ORDER BY cokey;


--
-- combine component data
--
CREATE TABLE statsgo_component_data AS 
SELECT statsgo_component_data_1.*,
clay_05, clay_025, clay_2550, 
ph_05, ph_025, ph_2550, 
ec_05, ec_025, 
cec_05, cec_025, cec_050, 
ksat_05, 
paws_025, paws_050, 
rf_025, 
kw_025
FROM statsgo_component_data_1 LEFT JOIN statsgo_component_data_2 USING (cokey);

-- index component data
CREATE INDEX statsgo_component_data_mukey_idx ON statsgo_component_data (mukey);
CREATE UNIQUE INDEX statsgo_component_data_cokey_idx ON statsgo_component_data (cokey);
VACUUM ANALYZE statsgo_component_data;


--
-- SSURGO
--


-- 
-- get the top of the shallowest restrictive feature for all components in CA
-- 
CREATE TEMP TABLE restrictive_feature_depths AS
SELECT distinct ON (cokey) cokey, resdept_r as resdept
FROM ssurgo.corestrictions
-- distinct is evaluated after the ordering, thus we use this to pick the top feature
order by cokey, resdept_r ASC;

CREATE INDEX restrictive_idx ON restrictive_feature_depths (cokey);
VACUUM ANALYZE restrictive_feature_depths;


--
-- make subset of horizon data: 77 seconds
--
CREATE TEMP TABLE hz_data AS
SELECT chkey, cokey, 
-- summed values: convert OM and CaCO3 to fractions
hzdept_r AS top, hzdepb_r AS bottom, (hzdepb_r - hzdept_r) as thick, awc_r as awc, om_r/100.0 as om, caco3_r/100.0 as caco3,
-- weighted variables
sandtotal_r as sand, CASE WHEN sandtotal_r is NULL THEN NULL ELSE (hzdepb_r - hzdept_r) END as sand_wt,
silttotal_r as silt, CASE WHEN silttotal_r is NULL THEN NULL ELSE (hzdepb_r - hzdept_r) END as silt_wt,
claytotal_r as clay, CASE WHEN claytotal_r is NULL THEN NULL ELSE (hzdepb_r - hzdept_r) END as clay_wt,
dbovendry_r as db, CASE WHEN dbovendry_r is NULL THEN NULL ELSE (hzdepb_r - hzdept_r) END as db_wt,
cec7_r as cec, CASE WHEN cec7_r is NULL THEN NULL ELSE (hzdepb_r - hzdept_r) END as cec_wt,
ph1to1h2o_r as ph, CASE WHEN ph1to1h2o_r is NULL THEN NULL ELSE (hzdepb_r - hzdept_r) END as ph_wt,
sar_r as sar, CASE WHEN sar_r IS NULL THEN NULL ELSE (hzdepb_r - hzdept_r) END as sar_wt,
ec_r as ec, CASE WHEN ec_r IS NULL THEN NULL ELSE (hzdepb_r - hzdept_r) END as ec_wt,
-- un-weighted values
ksat_r as ksat, kwfact::numeric as kw,
COALESCE(soil_fraction, 1) as soil_fraction
FROM ssurgo.chorizon 
LEFT JOIN
	(
	-- total rock fragment percent
	SELECT chkey, (100.0 - sum(COALESCE(fragvol_r, 0))) / 100.0 as soil_fraction
	FROM ssurgo.chfrags
	GROUP BY chkey
	) as frag_data
USING (chkey)
ORDER BY cokey, top ASC;



-- 
-- aggregate to component level: 5 seconds 
-- note that this table only contains components that HAVE at least soil depth data
-- 
CREATE TEMP TABLE component_data_1 AS
SELECT cokey, 
-- component-level data: unity aggregates
max(mukey) as mukey, max(comppct_r::numeric/100.0) as comppct_r, max(wei) as wei, max(resdept) as resdept,
-- profile totals
sum(thick) as soil_depth,
sum(thick * awc) as profile_water_storage,
sum(thick * om * soil_fraction * db * 10) as om_kg_sq_m,
sum(thick * caco3 * soil_fraction * db * 10) as caco3_kg_sq_m,
-- hz thickness wt-mean values
sum(sand_wt * sand) / sum(sand_wt) as profile_wt_mean_sand,
sum(silt_wt * silt) / sum(silt_wt) as profile_wt_mean_silt,
sum(clay_wt * clay) / sum(clay_wt) as profile_wt_mean_clay,
sum(db_wt * db) / sum(db_wt) as profile_wt_mean_db,
sum(cec_wt * cec) / sum(cec_wt) as profile_wt_mean_cec,
sum(ph_wt * ph) / sum(ph_wt) as profile_wt_mean_ph,
-- profile max
max(sar) as sar,
max(ec) as ec,
max(om) as max_om,
-- ksat values
min(ksat) as min_ksat,
max(ksat) as max_ksat,
avg(ksat) as mean_ksat
FROM hz_data
JOIN ssurgo.component USING (cokey)
LEFT JOIN restrictive_feature_depths USING (cokey)
GROUP BY cokey 
-- filter out those soils that have a NULL soil depth
HAVING sum(thick) IS NOT NULL AND sum(thick) > 0 
ORDER BY cokey ;


-- 
-- component-level slab summaries
-- 
CREATE TEMP TABLE component_data_2 AS
SELECT component_data_1.cokey,
clay_05, clay_025, clay_2550, 
ph_05, ph_025, ph_2550, 
ec_05, ec_025, 
cec_05, cec_025, cec_050, 
ksat_05, 
paws_025, paws_050, 
rf_025, 
kw_025
FROM
component_data_1 
--- thickness weighted by depth interval
LEFT JOIN (SELECT id AS cokey, prop as clay_05 FROM slab_mean('hz_data', 'clay', 0, 5, 'cokey', 'top', 'bottom')) as a1 USING (cokey)
LEFT JOIN (SELECT id AS cokey, prop as clay_025 FROM slab_mean('hz_data', 'clay', 0, 25, 'cokey', 'top', 'bottom')) as a2 USING (cokey)
LEFT JOIN (SELECT id AS cokey, prop as clay_2550 FROM slab_mean('hz_data', 'clay', 25, 50, 'cokey', 'top', 'bottom')) as a3 USING (cokey)

LEFT JOIN (SELECT id AS cokey, prop as ph_05 FROM slab_mean('hz_data', 'ph', 0, 5, 'cokey', 'top', 'bottom')) as b1 USING (cokey)
LEFT JOIN (SELECT id AS cokey, prop as ph_025 FROM slab_mean('hz_data', 'ph', 0, 25, 'cokey', 'top', 'bottom')) as b2 USING (cokey)
LEFT JOIN (SELECT id AS cokey, prop as ph_2550 FROM slab_mean('hz_data', 'ph', 25, 50, 'cokey', 'top', 'bottom')) as b3 USING (cokey)

LEFT JOIN (SELECT id AS cokey, prop as ec_05 FROM slab_mean('hz_data', 'ec', 0, 5, 'cokey', 'top', 'bottom')) as c1 USING (cokey)
LEFT JOIN (SELECT id AS cokey, prop as ec_025 FROM slab_mean('hz_data', 'ec', 0, 25, 'cokey', 'top', 'bottom')) as c2 USING (cokey)

LEFT JOIN (SELECT id AS cokey, prop as cec_05 FROM slab_mean('hz_data', 'cec', 0, 5, 'cokey', 'top', 'bottom')) as d1 USING (cokey)
LEFT JOIN (SELECT id AS cokey, prop as cec_025 FROM slab_mean('hz_data', 'cec', 0, 25, 'cokey', 'top', 'bottom')) as d2 USING (cokey)
LEFT JOIN (SELECT id AS cokey, prop as cec_050 FROM slab_mean('hz_data', 'cec', 0, 50, 'cokey', 'top', 'bottom')) as d3 USING (cokey)

LEFT JOIN (SELECT id AS cokey, prop as ksat_05 FROM slab_mean('hz_data', 'ksat', 0, 5, 'cokey', 'top', 'bottom')) as e USING (cokey)

-- available water storage 0-25 and 0-50 cm
-- this works because we are summing 1-cm slices within our interval
LEFT JOIN (SELECT id AS cokey, prop as paws_025 FROM slab_sum('hz_data', 'awc', 0, 25, 'cokey', 'top', 'bottom')) as f1 USING (cokey)
LEFT JOIN (SELECT id AS cokey, prop as paws_050 FROM slab_sum('hz_data', 'awc', 0, 50, 'cokey', 'top', 'bottom')) as f2 USING (cokey)

-- not sure about these
LEFT JOIN (SELECT id AS cokey, (1 - prop) as rf_025 FROM slab_mean('hz_data', 'soil_fraction', 0, 25, 'cokey', 'top', 'bottom')) as g USING (cokey)
LEFT JOIN (SELECT id AS cokey, prop as kw_025 FROM slab_mean('hz_data', 'kw', 0, 25, 'cokey', 'top', 'bottom')) as h USING (cokey)
ORDER BY cokey;


--
-- combine component data
--
CREATE TABLE component_data AS 
SELECT component_data_1.*,
clay_05, clay_025, clay_2550, 
ph_05, ph_025, ph_2550, 
ec_05, ec_025, 
cec_05, cec_025, cec_050, 
ksat_05, 
paws_025, paws_050, 
rf_025, 
kw_025
FROM component_data_1 LEFT JOIN component_data_2 USING (cokey);

-- index component data
CREATE INDEX component_data_mukey_idx ON component_data (mukey);
CREATE UNIQUE INDEX component_data_cokey_idx ON component_data (cokey);
VACUUM ANALYZE component_data;


