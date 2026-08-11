#!/bin/bash
# Convert all SVGs in this directory to PNGs using headless Chrome
# This prevents Japanese font corruption (tofu) and maintains browser-like rendering.

cd "$(dirname "$0")" || exit

for file in *.svg; do
  width=$(grep -oP '<svg.*?width="\K[0-9]+' "$file")
  height=$(grep -oP '<svg.*?height="\K[0-9]+' "$file")
  png_file="${file%.svg}.png"
  echo "Converting $file ($width x $height) to $png_file"
  google-chrome --headless --disable-gpu --screenshot="$png_file" --window-size="$width,$height" "$file"
done
