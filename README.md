NatMus Tools
============

A collection of command line tools for working with the API provided by the National Museum of Denmark.

Tools
-----

- **bin/color.sh:** Extract dominant colors from pictures in the collection.
- **bin/gif.sh:** Create animated GIFs from any *rotationsbilleder* in the collection.
- **bin/scrape.pl:** Scrape asset metadata filtered by collection and license type.

You need to have a recent version of *ImageMagick* installed to use the `color.sh` and `gif.sh` scripts.

### color.sh

Usage:

    color.sh <collection> <asset id>

Analyze the colors of asset 237 from the DNT collection.

    color.sh DNT 237

This produces the following output:

    DNT|237|137,122,89
    DNT|237|159,168,155
    DNT|237|208,172,63
    DNT|237|251,229,94
    DNT|237|252,250,153
    DNT|237|51,43,49
    DNT|237|68,62,62
    DNT|237|86,86,85

### gif.sh

Usage:

    gif.sh <asset id> <width in pixels>

Create a 480 pixel wide animated GIF of the Trundholm sun chariot.

    gif.sh 11006 480

### scrape.pl

Usage:

    scrape.pl [-c <COLLECTION>] -l -o <OUTPUT_FILE> -n <NUMBER_OF_RESULTS> -t <THROTTLE> -v

Get all assets with an open license from the DNT collection and store the result in `natmus.json`. Be verbose.

    scrape.pl -c DNT -l -o ./natmus.json -v
