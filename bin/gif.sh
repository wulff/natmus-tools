#!/bin/bash

# You can use this script to create animated GIFs from the "rotationsbilleder"
# provided by the National Museum of Denmark.
#
# usage: gif.sh <asset id> <width in pixels>
#
# example: gif.sh 11006 480
#
# This will create a 480px wide animated GIF from the pictures referenced on
# http://samlinger.natmus.dk/DO/11006.

# TODO: grab related assets from the new API instead of using cumulus

# bail on errors
set -e

# we need some arguments to get going
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: natmus2gif.sh <asset id> <width in pixels>"
  exit 1
fi

# regular expression to match integers
numeric='^[0-9]+$'

# get asset id
id=$1
if ! [[ $id =~ $numeric ]]; then
  echo "Error: You must supply a numeric asset id" >&2
  exit 3
fi

# get desired width in pixels
width=$2
if ! [[ $width =~ $numeric ]]; then
  echo "Error: You must supply a numeric width" >&2
  exit 4
fi

echo "Creating animated gif from asset #${id}, width=${width}px"

# show asset metadata to the user
while read -rd, line; do
  key=$(echo "$line" | sed 's/"//g' | cut -d":" -f1)
  value=$(echo "$line" | sed 's/[,"]//g' | cut -d":" -f2)

  case "$key" in
    collection)
      collection=$value
      label="N/A"

      case "$value" in
        AS)
        label="Antiksamlingen"
        ;;
        BA)
        label="Bevaringsafdelingen"
        ;;
        DMR)
        label="Danmarks Middelalder og Renæssance"
        ;;
        DNT)
        label="Danmark i Nyere Tid"
        ;;
        DO)
        label="Danmarks Oldtid"
        ;;
        KMM)
        label="Den Kongelige Mønt- og Medlajesamling"
        ;;
        ES)
        label="Etnografisk Samling"
        ;;
        FHM)
        label="Frihedsmuseet"
        ;;
        FLM)
        label="Frilandsmuseet"
        ;;
        MUM)
        label="Musikmuseet"
        ;;
      esac
      echo "Collection: $label"
      ;;
    creator)
      echo "Creator   : $value"
      ;;
    license)
      echo "License   : $value"
      ;;
  esac
done <<< "$(curl -s "http://testapi.natmus.dk/v1/Search/?query=(type:asset)+AND+(sourceId:$id)" | /usr/bin/grep -E -o '".*?":".*?",')"
echo

if [ "$collection" == "none" ]; then
  echo "Error: Unknown collection for asset" >&2
  exit 5
fi

# get a list of the images we need to create the animaton
assets=$(curl -s "http://cumulus.natmus.dk/CIP/metadata/getrelatedassets/$collection/$id/isalternatemaster" | /usr/bin/grep -E -o "\[.*?\]" | sed "s/[^0-9,]//g" | tr "," "\n")

# download all images in the desired resolution
for asset in $assets; do
  echo -n "Fetching $id... "
  curl -s "http://samlinger.natmus.dk/$collection/$asset/image/$width" > "./$asset.jpg"
  echo "Done!"
done
echo

# get the page and extract the frame IDs
echo -n "Creating argument list... "
images=$(curl -s "http://samlinger.natmus.dk/DO/$id" | \
  /usr/bin/grep -E -o " images:(.*?);" | \
  /usr/bin/grep -E -o "/DO.*?/1000")

# build a list of input files `convert`
frames=()
while read -r line; do
  frame_id=$(echo "$line" | cut -d"/" -f3)
  if [ "$frame_id" -ne "$id" ]; then
    frames=("${frames[@]}" "$frame_id.jpg")
  fi
done <<< "$images"
echo "Done!"

# use the imagemagick `convert` command to create a gif
echo -n "Creating GIF... "
collection_label=$(echo "$collection" | tr '[:upper:]' '[:lower:]')
convert -delay 60 "${frames[@]}" -layers OptimizeFrame +map -loop 0 -colors 256 \
  "natmus-$collection_label-$id.gif"
echo "Done!"

rm "${frames[@]}"
