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

DROP TABLE IF EXISTS ${db} ;


EOF
)

## debugging
# note the use of double quotes: need this to preserve newlines
# echo "$sql" > test.sql

## run in DB
# note the use of double quotes: need this to preserve newlines
echo "$sql" | psql -U postgres ssurgo_combined

