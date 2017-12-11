#!/bin/bash

## 2017-12-04
## D.E. Beaudette
##
##
## usage: bash xxx "ssurgo"



# database name: ssurgo | statsgo
db=$1


## SSURGO version 
sql_ssurgo=$(cat <<EOF

SET search_path TO conus_800m_grid, public ;
SET work_mem to 800000 ;

DROP TABLE IF EXISTS conus_800m_grid.ssurgo_soil_series;
CREATE TABLE conus_800m_grid.ssurgo_soil_series AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * pct) as area_extent, 
series as compname
FROM conus_800m_grid.ssurgo_grid_mapunit 
JOIN soilweb.comp_data USING (mukey) 
GROUP BY grid_gid, compname
ORDER BY grid_gid, area_extent DESC ;

-- index
CREATE INDEX soil_series_idx ON ssurgo_soil_series (grid_gid);
VACUUM ANALYZE ssurgo_soil_series;

EOF
)


## STATSGO version is a little different
sql_statsgo=$(cat <<EOF

SET search_path TO conus_800m_grid, public ;
SET work_mem to 800000 ;

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
DROP TABLE IF EXISTS statsgo_soil_series;
CREATE TABLE statsgo_soil_series AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * pct) as area_extent, compname
FROM 
statsgo_grid_mapunit 
JOIN statsgo_compname_normalized USING (mukey)
GROUP BY grid_gid, compname
ORDER BY grid_gid, area_extent DESC ;

-- index
CREATE INDEX statsgo_soil_series_idx ON statsgo_soil_series (grid_gid);
VACUUM ANALYZE statsgo_soil_series;

EOF
)


## run in DB

# select survey
if [ "$db" == "ssurgo" ]; then 	
	# note the use of double quotes: need this to preserve newlines
	echo "$sql_ssurgo" | psql -U postgres ssurgo_combined
fi

if [ "$db" == "statsgo" ]; then 	
	# note the use of double quotes: need this to preserve newlines
	echo "$sql_statsgo" | psql -U postgres ssurgo_combined
fi








# -- -- -- SSURGO -- -- -- 
# -- use the pre-made soilweb normalized compname table
# DROP TABLE IF EXISTS conus_800m_grid.soil_series;
# CREATE TABLE conus_800m_grid.soil_series AS
# SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * pct) as area_extent, 
# series as compname
# FROM grid_mapunit 
# JOIN soilweb.comp_data USING (mukey) 
# GROUP BY grid_gid, compname
# ORDER BY grid_gid, area_extent DESC ;

# -- index
# CREATE INDEX soil_series_idx ON soil_series (grid_gid);
# VACUUM ANALYZE soil_series;
# -- -- -- SSURGO -- -- -- 


# -- -- -- STATSGO -- -- --
# -- most extensive soil series
# -- slow... ideas? 
# -- https://stackoverflow.com/questions/3800551/select-first-row-in-each-group-by-group/7630564#7630564
# --
# CREATE TEMP TABLE statsgo_compname_normalized AS
# SELECT
# mukey, 
# UPPER(REPLACE(REPLACE(REPLACE(compname, ' family', ''), ' variant', ''), ' taxadjunct', '')) as compname,
# SUM(comppct_r::numeric/100.0) AS pct
# FROM statsgo.component
# GROUP BY mukey, UPPER(REPLACE(REPLACE(REPLACE(compname, ' family', ''), ' variant', ''), ' taxadjunct', ''))
# ORDER BY mukey, pct DESC;

# -- remove non-recognized soil series 
# DELETE FROM statsgo_compname_normalized WHERE compname NOT IN (SELECT UPPER(seriesname) FROM osd.taxa);

# CREATE INDEX statsgo_compname_normalized_mukey_idx ON statsgo_compname_normalized (mukey);
# CREATE INDEX statsgo_compname_normalized_compname_idx ON statsgo_compname_normalized (compname);
# VACUUM ANALYZE statsgo_compname_normalized;

# -- finish table
# CREATE TEMP TABLE statsgo_soil_series AS
# SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * pct) as area_extent, compname
# FROM 
# statsgo_grid_mapunit 
# JOIN statsgo_compname_normalized USING (mukey)
# -- debug
# -- JOIN grid ON grid.gid = statsgo_grid_mapunit.grid_gid AND chunk = '11-40'
# -- debug
# GROUP BY grid_gid, compname
# ORDER BY grid_gid, area_extent DESC ;

# -- index
# CREATE INDEX statsgo_soil_series_idx ON statsgo_soil_series (grid_gid);
# VACUUM ANALYZE statsgo_soil_series;
# -- -- -- STATSGO -- -- --

