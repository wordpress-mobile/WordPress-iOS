#!/bin/sh
convertPath=`which convert`
echo ${convertPath}
if [[ ! -f ${convertPath} || -z ${convertPath} ]]; then
echo "warning: Skipping Icon versioning, you need to install ImageMagick and ghostscript (fonts) first, you can use brew to simplify process:
brew install imagemagick
brew install ghostscript"
exit 0;
fi

commit=`git rev-parse --short HEAD`
branch=`git rev-parse --abbrev-ref HEAD`
version=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${INFOPLIST_FILE}"`
build_num=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${INFOPLIST_FILE}"`

shopt -s extglob
shopt -u extglob
caption="${build_num}\n${commit}"
echo $caption

function abspath() { pushd . > /dev/null; if [ -d "$1" ]; then cd "$1"; dirs -l +0; else cd "`dirname \"$1\"`"; cur_dir=`dirs -l +0`; if [ "$cur_dir" == "/" ]; then echo "$cur_dir`basename \"$1\"`"; else echo "$cur_dir/`basename \"$1\"`"; fi; fi; popd > /dev/null; }

function processIcon() {
    base_file=$1
    file_name=$(basename "$base_file")
    base_path=$2
    base_destination_path=$3
    
    target_path="${base_path}/${file_name}"
    final_file_path="${base_destination_path}/${file_name}"
    
    base_tmp_normalizedFileName="${file_name%.*}-normalized.${file_name##*.}"
    base_tmp_normalizedFilePath="${base_path}/${base_tmp_normalizedFileName}"
    
    # Normalize
    echo "Reverting optimized PNG to normal"
    echo "xcrun -sdk iphoneos pngcrush -revert-iphone-optimizations -q '${base_file}' '${base_tmp_normalizedFilePath}'"
    xcrun -sdk iphoneos pngcrush -revert-iphone-optimizations -q "${base_file}" "${base_tmp_normalizedFilePath}"
    
    echo "identify -format %w \"${base_tmp_normalizedFilePath}\""
    width=`identify -format %w "${base_tmp_normalizedFilePath}"`

    echo "identify -format %h \"${base_tmp_normalizedFilePath}\""
    height=`identify -format %h "${base_tmp_normalizedFilePath}"`

    echo "($height * 33) / 100"
    band_height=$((($height * 33) / 100))
    band_position=$(($height - $band_height))
    text_position=$(($band_position - 3))
    point_size=$(((13 * $width) / 100))
    
    echo "Image dimensions ($width x $height) - band height $band_height @ $band_position - point size $point_size"
    
    #
    # blur band and text
    #
    convert "${base_tmp_normalizedFilePath}" -blur 10x8 /tmp/blurred.png
    convert /tmp/blurred.png -gamma 0 -fill white -draw "rectangle 0,$band_position,$width,$height" /tmp/mask.png
    convert -size ${width}x${band_height} xc:none -fill 'rgba(0,0,0,0.2)' -draw "rectangle 0,0,$width,$band_height" /tmp/labels-base.png
    convert -background none -size ${width}x${band_height} -pointsize $point_size -fill white -gravity center -gravity South caption:"$caption" /tmp/labels.png
    
    convert "${base_tmp_normalizedFilePath}" /tmp/blurred.png /tmp/mask.png -composite /tmp/temp.png
    
    rm /tmp/blurred.png
    rm /tmp/mask.png
    
    #
    # compose final image
    #
    filename=New"${base_file}"
    convert /tmp/temp.png /tmp/labels-base.png -geometry +0+$band_position -composite /tmp/labels.png -geometry +0+$text_position -geometry +${w}-${h} -composite -alpha remove "${target_path}"
    
    cp "${target_path}" "${final_file_path}"
    
    # clean up
    rm /tmp/temp.png
    rm /tmp/labels-base.png
    rm /tmp/labels.png
    rm "${base_tmp_normalizedFilePath}"
    
    echo "Overlayed ${final_file_path}"
}

# Process all app icons and create the corresponding internal icons
# icons_dir="${SRCROOT}/Images.xcassets/AppIcon.appiconset"
icons_dir="${TARGET_BUILD_DIR}/${CONTENTS_FOLDER_PATH}"
icons_tmp_dir="${TEMP_DIR}/ModifiedIcons"
icons_dest_dir="${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
mkdir "${icons_tmp_dir}"

for icon in "${icons_dir}"/AppIcon*.png;
do
    processIcon "${icon}" "${icons_tmp_dir}" "${icons_dest_dir}"
done
