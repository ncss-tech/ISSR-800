-- 2016-07-20
-- Start CONUS 800m grid project
-- entire operation takes about 30 minutes

-- new schema
CREATE SCHEMA conus_800m_grid;

-- setup environment
SET search_path TO conus_800m_grid, public ;
SET work_mem to 800000 ;
\timing


-- add custom SRID: CONUS AEA (from ~/grass/conus_color/PERMANENT)
insert into spatial_ref_sys values ('9002','UCD','9002','PROJCS["Albers Equal Area",GEOGCS["grs80",DATUM["North_American_Datum_1983",SPHEROID["Geodetic_Reference_System_1980",6378137,298.257222101]],PRIMEM["Greenwich",0],UNIT["degree",0.0174532925199433]],PROJECTION["Albers_Conic_Equal_Area"],PARAMETER["standard_parallel_1",29.5],PARAMETER["standard_parallel_2",45.5],PARAMETER["latitude_of_center",23],PARAMETER["longitude_of_center",-96],PARAMETER["false_easting",0],PARAMETER["false_northing",0],UNIT["Meter",1]]', '+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23 +lon_0=-96 +x_0=0 +y_0=0 +no_defs +a=6378137 +rf=298.257222101 +towgs84=0.000,0.000,0.000 +to_meter=1') ;


-- custom function for generating a grid
-- http://gis.stackexchange.com/questions/16374/how-to-create-a-regular-polygon-grid-in-postgis
CREATE OR REPLACE FUNCTION ST_CreateFishnet(
        nrow integer, ncol integer,
        xsize float8, ysize float8,
        x0 float8 DEFAULT 0, y0 float8 DEFAULT 0,
        OUT "row" integer, OUT col integer,
        OUT geom geometry)
    RETURNS SETOF record AS
$$
SELECT i + 1 AS row, j + 1 AS col, ST_Translate(cell, j * $3 + $5, i * $4 + $6) AS geom
FROM generate_series(0, $1 - 1) AS i,
     generate_series(0, $2 - 1) AS j,
(
SELECT ('POLYGON((0 0, 0 '||$4||', '||$3||' '||$4||', '||$3||' 0,0 0))')::geometry AS cell
) AS foo;
$$ LANGUAGE sql IMMUTABLE STRICT;

--
-- grid information
--
-- projection:         99 (Albers Equal Area)
-- zone:               0
-- datum:              nad83
-- ellipsoid:          grs80
-- north:              3212000
-- south:              229600
-- west:               -2415200
-- east:               2285600
-- nsres:              800
-- ewres:              800
-- rows:               3728
-- cols:               5876
-- cells:              21905728

-- make the CONUS grid
-- (rows, cols, cell size x, cell size y, lower-left x, lower-left y)
CREATE TABLE grid AS
SELECT * FROM ST_CreateFishnet(3728, 5876, 800, 800, -2415200, 229600) AS cells;

-- fix SRID
-- 315 seconds
UPDATE grid SET geom = ST_SetSRID(geom, 9002);

-- make gID
ALTER TABLE grid ADD COLUMN gid serial;
ALTER TABLE grid ALTER COLUMN gid DROP DEFAULT;
DROP SEQUENCE grid_gid_seq;

-- TODO: establish reasonable chunk size
-- 200x200: 570 possible chunks
--  STATSGO intersection: 2 minutes / chunk
--  SSURGO intersection: 22.5 minutes / chunk
-- 100x100: 2242 possible chunks
--  STATSGO intersection: 0.5 minutes / chunk
--  SSURGO intersection: 5 minutes / chunk
--
-- make chunk IDs: integer division
-- 10-20 minutes
ALTER TABLE grid ADD COLUMN chunk text;
UPDATE grid SET chunk = (grid.row / 100::integer) || '-' || (grid.col / 100::integer);


-- TODO: consider spatial indexing grid on transformed coordinates (4326)
-- index
CREATE UNIQUE INDEX grid_pkey ON grid (gid);
CREATE INDEX chunk_idx ON grid (chunk);
CREATE INDEX grid_geom_idx ON grid USING gist(geom);
VACUUM ANALYZE grid;





