
# clean-up previous testing
echo "TRUNCATE conus_800m_grid.statsgo_grid_mapunit;" | psql -U postgres ssurgo_combined

time cat chunk-IDs.txt | parallel --no-notice --joblog statsgo-intersection.log --eta --progress  "echo \"
SET work_mem to '1GB' ;
INSERT INTO conus_800m_grid.statsgo_grid_mapunit
SELECT grid.gid as grid_gid, mapunit_poly.ogc_fid as mu_gid, mukey,
CASE
	WHEN ST_Within(ST_Transform(conus_800m_grid.grid.geom, 4326), mapunit_poly.wkb_geometry) THEN ST_Area(conus_800m_grid.grid.geom)
	ELSE ST_Area(ST_Intersection(ST_Transform(conus_800m_grid.grid.geom, 4326), mapunit_poly.wkb_geometry)::geography) 
END AS area_wt
FROM
conus_800m_grid.grid
JOIN
statsgo.mapunit_poly ON ST_Intersects(ST_Transform(conus_800m_grid.grid.geom, 4326), mapunit_poly.wkb_geometry)
WHERE grid.chunk = '{}';
\" | psql --quiet -U postgres ssurgo_combined"
