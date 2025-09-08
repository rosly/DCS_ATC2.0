#!/bin/bash

# Script to bundle audio files into a DCS .miz file
# Assumes audios in ./SpicyATC/audios (relative to where .sh is run)
# Tries zenity for file dialog; falls back to terminal prompt if not installed
# Outputs _bundled.miz in same dir as selected .miz

echo "Starting SpicyATC bundler..."

# Check audios dir
audio_dir="./audios"
if [ ! -d "$audio_dir" ]; then
    echo "Error: audios folder not found in SpicyATC."
    exit 1
fi

# Try zenity for file dialog
if command -v zenity >/dev/null 2>&1; then
    miz_path=$(zenity --file-selection --title="Select DCS .miz File" --file-filter="DCS Mission Files (*.miz) | *.miz")
    if [ -z "$miz_path" ]; then
        echo "No .miz selected. Exiting."
        exit 0
    fi
else
    # Fallback to terminal input
    read -p "Enter full path to your .miz file: " miz_path
    if [ ! -f "$miz_path" ]; then
        echo "Error: Invalid .miz path."
        exit 1
    fi
fi

# Generate output path
miz_dir=$(dirname "$miz_path")
miz_filename=$(basename "$miz_path")
output_path="$miz_dir/${miz_filename%.miz}_bundled.miz"

# Copy original to output
cp "$miz_path" "$output_path"

# Add audios to l10n/DEFAULT/
added=0
for file in "$audio_dir"/*.ogg "$audio_dir"/*.wav; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        arc_path="l10n/DEFAULT/$filename"
        zip -u "$output_path" -j "$file" -P "" --out temp.zip > /dev/null  # Temp to avoid direct update issues
        mv temp.zip "$output_path"
        echo "Added $filename to $arc_path"
        ((added++))
    fi
done

if [ $added -eq 0 ]; then
    echo "Warning: No .ogg or .wav files in audios folder."
fi

echo "Success! Bundled .miz saved to: $output_path"