/*
Ideas:
 * http://stackoverflow.com/questions/10705616/table-name-as-a-postgresql-function-parameter


*/



-- compute depth-weighted mean value of a property
-- filtering NULL values
CREATE OR REPLACE FUNCTION slab_mean(_tbl regclass, _prop text, _slice_top integer, _slice_bottom integer, _id text DEFAULT 'cokey', _top text DEFAULT 'hzdept_r', _bottom text DEFAULT 'hzdepb_r')
RETURNS TABLE(id text, prop numeric) AS
$func$

BEGIN

RETURN QUERY 
EXECUTE 'SELECT ' || _id || '::text, (SUM((bottom - top) * prop) / SUM((bottom - top)))::numeric AS p
FROM
	(
	SELECT ' || _id || ', CASE WHEN ' || _top || '> ' || _slice_top || ' THEN ' || _top || ' ELSE ' || _slice_top || ' END AS top, CASE WHEN ' || _bottom || ' < ' || _slice_bottom || ' THEN ' || _bottom || ' ELSE ' || _slice_bottom || ' END AS bottom, ' || _prop || ' as prop
	FROM ' || _tbl || '
	WHERE ' || _top || ' <= ' || _slice_bottom || '
	AND ' || _bottom || ' >= ' || _slice_top || '
	AND ' || _prop || ' IS NOT NULL
	AND ' || _bottom || ' IS NOT NULL
	ORDER BY ' || _id || ', ' || _top || ' ASC
	) as sliced
WHERE (bottom - top) > 0
GROUP BY ' || _id || ';' ;

END
$func$ LANGUAGE 'plpgsql' ;
  


-- compute the sum of a property over user-defined depths, weighted by depth
-- filtering NULL values
CREATE OR REPLACE FUNCTION slab_sum(_tbl regclass, _prop text, _slice_top integer, _slice_bottom integer, _id text DEFAULT 'cokey', _top text DEFAULT 'hzdept_r', _bottom text DEFAULT 'hzdepb_r')
RETURNS TABLE(id text, prop numeric) AS
$func$

BEGIN

RETURN QUERY 
EXECUTE 'SELECT ' || _id || '::text, SUM((bottom - top) * prop)::numeric AS p
FROM
	(
	SELECT ' || _id || ', CASE WHEN ' || _top || '> ' || _slice_top || ' THEN ' || _top || ' ELSE ' || _slice_top || ' END AS top, CASE WHEN ' || _bottom || ' < ' || _slice_bottom || ' THEN ' || _bottom || ' ELSE ' || _slice_bottom || ' END AS bottom, ' || _prop || ' as prop
	FROM ' || _tbl || '
	WHERE ' || _top || ' <= ' || _slice_bottom || '
	AND ' || _bottom || ' >= ' || _slice_top || '
	AND ' || _prop || ' IS NOT NULL
	AND ' || _bottom || ' IS NOT NULL
	ORDER BY ' || _id || ', ' || _top || ' ASC
	) as sliced
WHERE (bottom - top) > 0
GROUP BY ' || _id || ';' ;

END
$func$ LANGUAGE 'plpgsql' ;





-- assumes geometry columns are named:
-- grid: geom
-- mapunit_poly: wkb_geometry
DROP FUNCTION ST_IntersectCell(text, regclass, regclass);

CREATE OR REPLACE FUNCTION ST_IntersectCell(
        cell text, grid_table regclass, mu_table regclass,
        OUT res record set)
$func$		
BEGIN
EXECUTE FORMAT("SELECT %s || '.' || gid as grid_gid, %s || '.' || ogc_fid as mu_gid, mukey,
CASE
	WHEN ST_Within(ST_Transform(%s || '.geom', 4326), %s || '.wkb_geometry') THEN ST_Area(%s || '.geom')
	ELSE ST_Area(ST_Intersection(ST_Transform($2 || '.geom', 4326), %s || '.wkb_geometry')::geography) 
END AS area_wt
FROM
%s
JOIN
%s ON ST_Intersects(ST_Transform(%s || '.geom', 4326), %s || 'wkb_geometry')
WHERE %s || '.gid' = '%s' ;
", grid_table, mu_table, grid_table, mu_table, grid_table, grid_table, mu_table, grid_table, mu_table, grid_table, mu_table, grid_table, cell) INTO res;
END
$func$ LANGUAGE sql IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION ST_IntersectChunk(
        chunk text, grid_table regclass, mu_table regclass,
        OUT grid_gid integer, OUT mu_gid integer, OUT mukey integer, OUT area_wt numeric
        )
    RETURNS SETOF record AS
$$
EXECUTE FORMAT("SELECT %s || '.' || gid as grid_gid, %s || '.' || ogc_fid as mu_gid, mukey,
CASE
	WHEN ST_Within(ST_Transform(%s || '.geom', 4326), %s || '.wkb_geometry') THEN ST_Area(%s || '.geom')
	ELSE ST_Area(ST_Intersection(ST_Transform($2 || '.geom', 4326), %s || '.wkb_geometry')::geography) 
END AS area_wt
FROM
%s
JOIN
%s ON ST_Intersects(ST_Transform(%s || '.geom', 4326), %s || 'wkb_geometry')
WHERE %s || '.chunk' = '%s' ;
", grid_table, mu_table, grid_table, mu_table, grid_table, grid_table, mu_table, grid_table, mu_table, grid_table, mu_table, grid_table, chunk)
$$ LANGUAGE sql IMMUTABLE STRICT;