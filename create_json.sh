#!/bin/bash
route_id=$(tail -10 www/routes.json | grep route_ | tr -dc '0-9')
route_id=$(echo $route_id + 1 | bc | awk '{printf $0}') # needs a padding zero for 1-9
id=$(tail -10 www/routes.json | grep -m1 id | tr -dc '0-9')
id=$(($id + 1))

echo -en "Name: "; read name
echo -en "RWGPS: "; read rwgps_id
echo -en "velo id: "; read velo_id
echo -en "segments: "; read segments

# get hoogtemeters: 
rwgps_html=$(wget -qO- https://ridewithgps.com/routes/"$rwgps_id")
distance=$(grep -m 1 -A 3 hide_unless_distance <<< $rwgps_html | tail -1 | sed 's/ km$//')
elevation=$(grep -m 1 txtAscent <<< $rwgps_html | tr -dc '0-9')

segments_json='"segments": {'
i="$id"; b=""
for s in $segments; do
  seg_html=$(wget -qO- https://veloviewer.com/segments/"$s")
  seg_length=$(grep -m1 '="distance"' <<< $seg_html | perl -wnE 'say /\d+\.\d+/g')
  seg_avggrade=$(grep -m1 '="grade"' <<< $seg_html | perl -wnE 'say /\d+\.\d+/g')
  b="\"$i\": { \"seg_id\": $s, \"Length\": $seg_length, \"avg_grade\": $seg_avggrade },"
  body+="$b"
  i=$((i + 1))
done
body=$(sed 's/,$//' <<< $body)
segments_json+="$body},"

json='  "route_'$route_id'": {
    "id": '$id',
    "name": "'$name'",
    "distance": '$distance',
    "elevation": '$elevation',
    '$segments_json'
    "link_velo": "https://veloviewer.com/routes/'$velo_id'",
    "link_rwgps": "https://ridewithgps.com/routes/'$rwgps_id'"
  },'

echo "$json" >> "$1"
