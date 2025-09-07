#!/bin/bash
# Audio Toggle Script

# Get current numeric value
CURRENT=$(amixer cget name="Playback Path" | grep ": values=" | awk -F'=' '{print $2}' | xargs)

if [ "$CURRENT" -eq 1 ]; then
    # SPK → switch to HP
    NEW_INDEX=2
    NEW_NAME="HP"
    printf "Switching from Speakers to Headphones\n"

elif [ "$CURRENT" -eq 2 ]; then
    # HP → switch to SPK
    NEW_INDEX=1
    NEW_NAME="SPK"
    printf "Switching from Headphones to Speakers\n"

elif [ "$CURRENT" -eq 3 ]; then
    # SPK+HP → default to HP (change to SPK if you prefer)
    NEW_INDEX=2
    NEW_NAME="HP"
    printf "Switching from Both (SPK+HP) to Headphones\n"

else
    # OFF or unknown → default to SPK
    NEW_INDEX=1
    NEW_NAME="SPK"
    printf "Current value is '%s', defaulting to Speakers\n" "$CURRENT"
fi

# Apply new setting
amixer cset name="Playback Path" "$NEW_INDEX"
sudo alsactl store
printf "Audio path set to: %s\n" "$NEW_NAME"
