#!/bin/bash

# Find dominant colors in an image from the collection.
#
# usage: color.sh <collection> <asset id>
#
# example: color.sh DNT 237

# set the width of the image used to perform the color analysis
width=600

# bail on errors
set -e

# we need some arguments to get going
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: natmuscolor.sh <collection> <asset id>"
  exit 1
fi

# get collection id
collection=$1
if ! [[ $collection =~ ^[a-zA-Z]+$ ]]; then
  echo "Error: You must supply a collection id" >&2
  exit 3
fi

# get asset id
asset=$2
if ! [[ $asset =~ ^[0-9]+$ ]]; then
  echo "Error: You must supply a numeric asset id" >&2
  exit 4
fi

>&2 echo "Getting color information from asset #${asset} based on ${width}px image"

>&2 echo -n "Downloading image... "
curl -s -f "http://samlinger.natmus.dk/$collection/$asset/image/$width" > "/tmp/natmus-$asset.jpg"
>&2 echo "Done!"

while read -r color; do
  # remove the parentheses at the beginning and end of the color string
  clean=${color:1:$((${#color}-2))}

  # convert the color string to an array
  rgb=(${clean//,/ })

  # save the color unless it is black, white, or grey
  if ! ([ "${rgb[0]}" -eq "${rgb[1]}" ] && [ "${rgb[0]}" -eq "${rgb[2]}" ] && [ "${rgb[1]}" -eq "${rgb[2]}" ]); then
    echo "$collection|$asset|${rgb[0]},${rgb[1]},${rgb[2]}"
  fi
done <<< "$(convert "/tmp/natmus-$asset.jpg" -auto-level -blur 0x2 -colors 8 txt: | grep -v "^#" | cut -d" " -f2 | sort | uniq)"

rm "/tmp/natmus-$asset.jpg"
