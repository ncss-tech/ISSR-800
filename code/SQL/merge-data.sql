
SET search_path TO conus_800m_grid, public ;
SET work_mem to 800000 ;

-- TODO: convert to integers
-- combine SSURGO and STATSGO fractions, based on soil depth wt
-- 1.54 hours
CREATE TABLE survey_data_available AS
SELECT ssurgo.grid_gid,
ssurgo.pct as ssurgo_pct, statsgo.pct as statsgo_pct
FROM
(
select grid_gid,
SUM(soil_depth_wt) / (800.0*800.0) as pct
from ssurgo_grid_mapunit
LEFT JOIN ssurgo_component_weights USING (gid)
-- where grid_gid IN (SELECT gid from grid where chunk = '21-3')
GROUP BY grid_gid
) as ssurgo
FULL JOIN
(
select grid_gid,
SUM(soil_depth_wt) / (800.0*800.0) as pct
from statsgo_grid_mapunit
LEFT JOIN statsgo_component_weights USING (gid)
-- where grid_gid IN (SELECT gid from grid where chunk = '21-3')
GROUP BY grid_gid
) as statsgo
ON ssurgo.grid_gid = statsgo.grid_gid;

-- add flag for survey selection
ALTER TABLE survey_data_available ADD COLUMN ssurgo_flag integer;
UPDATE survey_data_available SET ssurgo_flag = 0 ;
UPDATE survey_data_available SET ssurgo_flag = 1 WHERE ssurgo_pct IS NOT NULL ;

-- index
CREATE UNIQUE INDEX survey_data_available_idx ON survey_data_available (grid_gid);
CREATE INDEX survey_data_available_flag_idx ON survey_data_available (ssurgo_flag);
VACUUM ANALYZE survey_data_available;



--
-- merge the two data sets: 20 minutes based on rules above
--

-- now stack the SSURGO data with STATSGO data (subset by above table)
DROP TABLE conus_800m_grid.merged_data;
CREATE TABLE conus_800m_grid.merged_data as
SELECT gid, b.*
FROM
grid
JOIN (
	SELECT 'ssurgo'::text as survey_type, *
	FROM ssurgo_gridded_properties
	-- keep SSURGO only when there is NO SSURGO data in a cell
	WHERE grid_gid IN (SELECT grid_gid from survey_data_available WHERE ssurgo_flag = 1)
	UNION
	SELECT *
	FROM (
		SELECT 'statsgo'::text as survey_type, *
		FROM statsgo_gridded_properties
		-- keep STATSGO only when there is NO SSURGO data in a cell
		WHERE grid_gid IN (SELECT grid_gid from survey_data_available WHERE ssurgo_flag = 0)
		) as a
	) as b
ON grid.gid = b.grid_gid ;

--
-- indexes:
--

-- linking to geometry
CREATE INDEX merged_data_gid_idx ON merged_data (gid);

-- for categorical LUT
-- ~ 10 minutes extra
CREATE INDEX merged_data_series_idx ON merged_data (series_name);
CREATE INDEX merged_data_hydgrp_idx ON merged_data (hydgrp);
CREATE INDEX merged_data_str_idx ON merged_data (str);
CREATE INDEX merged_data_drainage_class_idx ON merged_data (drainage_class);
CREATE INDEX merged_data_soilorder_idx ON merged_data (soilorder);
CREATE INDEX merged_data_suborder_idx ON merged_data (suborder);
CREATE INDEX merged_data_greatgroup_idx ON merged_data (greatgroup);
CREATE INDEX merged_data_taxpartsize_idx ON merged_data (taxpartsize);
CREATE INDEX merged_data_weg_idx ON merged_data (weg);

-- better searches for series name, after normalization

-- cleanup
VACUUM ANALYZE merged_data;
