SET search_path TO conus_800m_grid, public ;
SET work_mem to 800000 ;

--
-- Notes: 
--  these tables are best constructed after an index has been generated on the relevant columns
--  consider: index -> LUT -> cleanup 
--


--
-- survey type
--
DROP TABLE conus_800m_grid.survey_type_lut;
CREATE TABLE conus_800m_grid.survey_type_lut AS 
SELECT DISTINCT survey_type
FROM merged_data;

-- add codes
ALTER TABLE survey_type_lut ADD COLUMN survey_type_int serial;

CREATE INDEX survey_type_lut_idx ON survey_type_lut (survey_type);
VACUUM ANALYZE survey_type_lut;

-- save to CSV
\copy survey_type_lut TO 'RAT/survey_type.csv' CSV HEADER


--
-- series name
--
DROP TABLE conus_800m_grid.series_name_lut;
CREATE TABLE conus_800m_grid.series_name_lut AS 
SELECT DISTINCT series_name
FROM merged_data;

CREATE INDEX series_name_lut_idx ON series_name_lut (series_name);
VACUUM ANALYZE series_name_lut;

-- remove non-series names
DELETE FROM series_name_lut WHERE series_name NOT IN (SELECT seriesname FROM osd.taxa);

-- add codes
ALTER TABLE series_name_lut ADD COLUMN series_name_int serial;
VACUUM ANALYZE series_name_lut;

-- save to CSV
\copy series_name_lut TO 'RAT/series_name.csv' CSV HEADER



--
-- hydrologic group
--
DROP TABLE conus_800m_grid.hydgrp_lut;
CREATE TABLE conus_800m_grid.hydgrp_lut AS 
SELECT DISTINCT hydgrp
FROM merged_data;

CREATE INDEX hydgrp_lut_idx ON hydgrp_lut (hydgrp);
VACUUM ANALYZE hydgrp_lut;

-- add codes
ALTER TABLE hydgrp_lut ADD COLUMN hydgrp_int serial;
VACUUM ANALYZE hydgrp_lut;

-- save to CSV
\copy hydgrp_lut TO 'RAT/hydgrp.csv' CSV HEADER


--
-- STR
--
DROP TABLE conus_800m_grid.str_lut;
CREATE TABLE conus_800m_grid.str_lut AS 
SELECT DISTINCT str
FROM merged_data;

CREATE INDEX str_lut_idx ON str_lut (str);
VACUUM ANALYZE str_lut;

-- add codes
ALTER TABLE str_lut ADD COLUMN str_int serial;
VACUUM ANALYZE str_lut;

-- save to CSV
\copy str_lut TO 'RAT/str.csv' CSV HEADER


--
-- drainge_class
--
DROP TABLE conus_800m_grid.drainage_class_lut;
CREATE TABLE conus_800m_grid.drainage_class_lut AS 
SELECT DISTINCT drainage_class
FROM merged_data;

CREATE INDEX drainage_class_lut_idx ON drainage_class_lut (drainage_class);
VACUUM ANALYZE drainage_class_lut;

-- add codes
ALTER TABLE drainage_class_lut ADD COLUMN drainage_class_int serial;
VACUUM ANALYZE drainage_class_lut;

-- save to CSV
\copy drainage_class_lut TO 'RAT/drainage_class.csv' CSV HEADER



--
-- soilorder
--
DROP TABLE conus_800m_grid.soilorder_lut;
CREATE TABLE conus_800m_grid.soilorder_lut AS 
SELECT DISTINCT soilorder
FROM merged_data;

CREATE INDEX soilorder_lut_idx ON soilorder_lut (soilorder);
VACUUM ANALYZE soilorder_lut;

-- add codes
ALTER TABLE soilorder_lut ADD COLUMN soilorder_int serial;
VACUUM ANALYZE soilorder_lut;

-- save to CSV
\copy soilorder_lut TO 'RAT/soilorder.csv' CSV HEADER



--
-- suborder
--
DROP TABLE conus_800m_grid.suborder_lut;
CREATE TABLE conus_800m_grid.suborder_lut AS 
SELECT DISTINCT suborder
FROM merged_data;

CREATE INDEX suborder_lut_idx ON suborder_lut (suborder);
VACUUM ANALYZE suborder_lut;

-- add codes
ALTER TABLE suborder_lut ADD COLUMN suborder_int serial;
VACUUM ANALYZE suborder_lut;

-- save to CSV
\copy suborder_lut TO 'RAT/suborder.csv' CSV HEADER



--
-- greatgroup
--
DROP TABLE conus_800m_grid.greatgroup_lut;
CREATE TABLE conus_800m_grid.greatgroup_lut AS 
SELECT DISTINCT greatgroup
FROM merged_data;

CREATE INDEX greatgroup_lut_idx ON greatgroup_lut (greatgroup);
VACUUM ANALYZE greatgroup_lut;

-- add codes
ALTER TABLE greatgroup_lut ADD COLUMN greatgroup_int serial;
VACUUM ANALYZE greatgroup_lut;

-- save to CSV
\copy greatgroup_lut TO 'RAT/greatgroup.csv' CSV HEADER



--
-- taxpartsize
--
DROP TABLE conus_800m_grid.taxpartsize_lut;
CREATE TABLE conus_800m_grid.taxpartsize_lut AS 
SELECT DISTINCT taxpartsize
FROM merged_data;

CREATE INDEX taxpartsize_lut_idx ON taxpartsize_lut (taxpartsize);
VACUUM ANALYZE taxpartsize_lut;

-- add codes
ALTER TABLE taxpartsize_lut ADD COLUMN taxpartsize_int serial;
VACUUM ANALYZE taxpartsize_lut;

-- save to CSV
\copy taxpartsize_lut TO 'RAT/taxpartsize.csv' CSV HEADER



--
-- weg
--
DROP TABLE conus_800m_grid.weg_lut;
CREATE TABLE conus_800m_grid.weg_lut AS 
SELECT DISTINCT weg
FROM merged_data;

CREATE INDEX weg_lut_idx ON weg_lut (weg);
VACUUM ANALYZE weg_lut;

-- add codes
ALTER TABLE weg_lut ADD COLUMN weg_int serial;
VACUUM ANALYZE weg_lut;

-- save to CSV
\copy weg_lut TO 'RAT/weg.csv' CSV HEADER

