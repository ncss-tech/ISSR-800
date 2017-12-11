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

DROP TABLE IF EXISTS ${db}_grid_nirr_class ;
CREATE TABLE ${db}_grid_nirr_class AS
SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, nirrcapcl
FROM conus_800m_grid.${db}_grid_mapunit
-- debug
-- JOIN grid ON grid.gid = ${db}_grid_mapunit.grid_gid AND chunk = '11-40'
-- debug
JOIN ${db}.component USING (mukey) 
WHERE nirrcapcl IS NOT NULL
GROUP BY grid_gid, nirrcapcl
ORDER BY grid_gid, area_extent DESC ;

-- index
CREATE INDEX ${db}_grid_nirr_class_idx ON ${db}_grid_nirr_class (grid_gid);
VACUUM ANALYZE ${db}_grid_nirr_class;


EOF
)

## debugging
# note the use of double quotes: need this to preserve newlines
# echo "$sql" > test.sql

## run in DB
# note the use of double quotes: need this to preserve newlines
echo "$sql" | psql -U postgres ssurgo_combined


# -- -- -- SSURGO -- -- -- 
# -- 
# -- get the most extensive nirrcapcl value by grid cell [tested]
# -- 
# CREATE TABLE grid_nirr_class AS
# SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, nirrcapcl
# FROM grid_mapunit 
# JOIN ssurgo.component USING (mukey) 
# WHERE nirrcapcl IS NOT NULL
# GROUP BY grid_gid, nirrcapcl
# ORDER BY grid_gid, area_extent DESC ;

# -- index
# CREATE INDEX grid_nirr_class_idx ON grid_nirr_class (grid_gid);
# VACUUM ANALYZE grid_nirr_class;

# -- -- -- SSURGO -- -- -- 


# -- -- -- STATSGO -- -- --
# -- 
# -- get the most extensive nirrcapcl value by grid cell [tested]
# -- 
# CREATE TEMP TABLE statsgo_grid_nirr_class AS
# SELECT DISTINCT ON (grid_gid) grid_gid, SUM(area_wt * (comppct_r::numeric/100.0)) as area_extent, nirrcapcl
# FROM conus_800m_grid.statsgo_grid_mapunit
# -- debug
# -- JOIN grid ON grid.gid = statsgo_grid_mapunit.grid_gid AND chunk = '11-40'
# -- debug
# JOIN statsgo.component USING (mukey) 
# WHERE nirrcapcl IS NOT NULL
# GROUP BY grid_gid, nirrcapcl
# ORDER BY grid_gid, area_extent DESC ;

# -- index
# CREATE INDEX statsgo_grid_nirr_class_idx ON statsgo_grid_nirr_class (grid_gid);
# VACUUM ANALYZE statsgo_grid_drain_class;

# -- -- -- STATSGO -- -- --

