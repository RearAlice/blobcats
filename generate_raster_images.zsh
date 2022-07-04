#!/usr/bin/env zsh
# Generates trimmed raster images from SVGs in svg/.
# Argument 1 is the file extension, default is webp.
# Argument 2 is the size, default is to use the SVG size.

setopt LOCAL_OPTIONS ERR_RETURN NO_UNSET PIPE_FAIL

if ! type magick &> /dev/null; then
    print -Pu2 "%F{1}'magick' from imagemagick not found%f"
    return 1
fi

local ext=webp
[[ ${ARGC} > 0 ]] && ext=${1}
local size=-1
[[ ${ARGC} > 1 ]] && size=${2}

function gri_convert() {
    local svg=${1}
    local target=${svg##*/}
    target=${ext}/${target%.*}.${ext}

    magick -verbose -background none -quality 100 \
           ${svg} -trim -resize ${size} ${target}

    if [[ ${ext} == "png" ]] && type pngcrush &> /dev/null; then
        pngcrush -ow ${target}
    fi
}

print -P "%F{12}generating ${ext} images in ${PWD}/${ext} …%f"
mkdir -p ${ext}
for svg in svg/*.svg; do
    gri_convert ${svg}
done

if ([[ ${ext} == "webp" ]] && type webpmux &> /dev/null) \
       || ([[ ${ext} == "png" ]] && type apngasm &> /dev/null); then
    print -P "%F{12}generating animated emoji …%f"
    for cfg in svg/animated/*cfg; do
        local emojiname=${cfg##*/}
        emojiname=${emojiname%.*}

        local -a webpmux_args=()
        local -a apngasm_args=()
        while read line; do
            local -a framecfg=(${(@s: :)line})

            [[ ${framecfg[1][1]} == "#" ]] && continue
            if [[ ${framecfg[1]} == "loop" ]]; then
                webpmux_args+=(-loop ${framecfg[2]})
                apngasm_args+=(--loops ${framecfg[2]})
                break
            fi
            webpmux_args+=(-frame ${ext}/${framecfg[1]}.${ext}
                           +${framecfg[2]}+0+0+0-b)
            apngasm_args+=(${ext}/${framecfg[1]}.${ext} ${framecfg[2]})

            gri_convert svg/animated/${framecfg[1]}.svg
        done < ${cfg}

        if [[ ${ext} == "webp" ]]; then
            webpmux -o ${ext}/a${emojiname}.${ext} ${webpmux_args}
        elif [[ ${ext} == "png" ]]; then
            apngasm --force --output ${ext}/a${emojiname}.${ext} ${apngasm_args}
        fi
        rm -v ${ext}/${emojiname}_*.${ext}
    done
else
    print -P "%F{1}Not generating animated emoji." \
          "Animated emojis are only generated for webp (with webpmux)" \
          "and png (with apngasm)%f"
fi
