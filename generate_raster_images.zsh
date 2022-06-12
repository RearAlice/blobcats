#!/usr/bin/env zsh
# Generates trimmed raster images images from SVGs in svg/.
# Argument 1 is the file extension, default is webp.
# Argument 2 is the size, default is to use the SVG size.

setopt LOCAL_OPTIONS ERR_RETURN NO_UNSET PIPE_FAIL

if ! type convert &> /dev/null; then
    print -u2 "'convert' from imagemagick not found"
    return 1
fi

local ext=webp
[[ ${ARGC} > 0 ]] && ext=${1}
local size=-1
[[ ${ARGC} > 1 ]] && size=${2}

print "generating ${ext} images in ${PWD}/${ext} …"
mkdir -p ${ext}
for svg in svg/*.svg; do
    local target=${svg##*/}
    target=${ext}/${target%.*}.${ext}
    convert ${svg} -trim -resize ${size} -quality 100 -verbose ${target}
done
