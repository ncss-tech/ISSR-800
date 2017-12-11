ls -lah  *.tif | awk 'BEGIN{OFS=","}{print $9,$5}' | sort -g
