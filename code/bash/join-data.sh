## run calculations in parallel: SSURGO | STATSGO data don't depend on eachother
## time spent on each overlaps

# greatgroup
# ~ 17 minutes STATSGO, ~ 27 minutes SSURGO
echo "greatgroup"
time bash calculations/join-greatgroup.sh statsgo & 
time bash calculations/join-greatgroup.sh ssurgo


# drainage class
# ~ 15 minutes STATSGO, ~ 22 minutes SSURGO
echo "drainage class"
time bash calculations/join-drainage_class.sh statsgo & 
time bash calculations/join-drainage_class.sh ssurgo


# hydrologic group
# ~ 13 minutes STATSGO, ~ 21 minutes SSURGO
echo "hydrologic group"
time bash calculations/join-hydgrp.sh statsgo & 
time bash calculations/join-hydgrp.sh ssurgo


# irrcapcl
# ~ 3 minutes STATSGO, ~ 8 minutes SSURGO
echo "irrcapcl"
time bash calculations/join-irrcapcl.sh statsgo & 
time bash calculations/join-irrcapcl.sh ssurgo


# nirrcapcl
# ~ 15 minutes STATSGO, ~ 25 minutes SSURGO
echo "nirrcapcl"
time bash calculations/join-nirrcapcl.sh statsgo & 
time bash calculations/join-nirrcapcl.sh ssurgo


# soil series
# ~ 15 minutes STATSGO, ~ 50 minutes SSURGO
echo "soil series"
time bash calculations/join-soil_series.sh statsgo & 
time bash calculations/join-soil_series.sh ssurgo


# soil order
# ~ 15 minutes STATSGO, ~ 25 minutes SSURGO
echo "soil series"
time bash calculations/join-soil_order.sh statsgo & 
time bash calculations/join-soil_order.sh ssurgo


# taxsuborder
# ~ 15 minutes STATSGO, ~ 25 minutes SSURGO
echo "tax suborder"
time bash calculations/join-suborder.sh statsgo & 
time bash calculations/join-suborder.sh ssurgo


# PSCS
# ~ 15 minutes STATSGO, ~ 26 minutes SSURGO
echo "PSCS"
time bash calculations/join-taxpartsize.sh statsgo & 
time bash calculations/join-taxpartsize.sh ssurgo


# WEG
# ~ 12 minutes STATSGO, ~ 20 minutes SSURGO
echo "WEG"
time bash calculations/join-weg.sh statsgo & 
time bash calculations/join-weg.sh ssurgo

# STR
# ~ 12 minutes STATSGO, ~ 16 minutes SSURGO
echo "STR"
time bash calculations/join-str.sh statsgo & 
time bash calculations/join-str.sh ssurgo


# component weights
# ~ 2.7 hours STATSGO, ~ 4.8 hours SSURGO
time bash calculations/join-component_weights.sh statsgo & 
time bash calculations/join-component_weights.sh ssurgo


# aggregate to grid level
# ~ 5.3 hours STATSGO, ~ 8.5 hours SSURGO
time bash calculations/join-gridded_properties.sh statsgo & 
time bash calculations/join-gridded_properties.sh ssurgo



