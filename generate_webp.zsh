#!/usr/bin/env zsh
# Generates trimmed WebP images from SVGs in svg/.
# First argument is the size, default is to use the SVG size.

setopt LOCAL_OPTIONS ERR_RETURN NO_UNSET PIPE_FAIL

if ! type convert &> /dev/null; then
    print -u2 "'convert' from imagemagick not found"
    return 1
fi

local size=-1
[[ ${ARGC} > 0 ]] && size=${1}

print "generating WebP images in ${PWD}/webp …"
mkdir -p webp
for svg in svg/*.svg; do
    local webp=${svg##*/}
    webp=webp/${webp%.*}.webp
    convert ${svg} -trim -resize ${size} -quality 100 -verbose ${webp}
done
