-- 2017-12-06
-- D.E. Beaudette
-- perform some final cleaning of the data before export
--


--
-- these oddities are typically the result of errors in the source data or queries used to build the final tables
-- subsequent versions of the data may not have these issues
--

SET search_path TO conus_800m_grid, public ;
SET work_mem to 800000 ;

-- remove 0's from WEI
UPDATE merged_data SET wei = NULL WHERE wei = 0;

