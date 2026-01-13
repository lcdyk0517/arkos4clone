#!/bin/bash

# Define the console data: "Brand - Device|Paths"
# These include the updated paths and copy commands from your test.sh
consoles=(
"YMC - YMC A10MINI| consoles/logo/480P/, consoles/kernel/common/, consoles/a10mini/"
"YMC - YMC A10MINI V2| consoles/logo/540P/, consoles/kernel/common/, consoles/a10mini V2/"
"AISLPC - GameConsole K36S| consoles/logo/480P/, consoles/kernel/common/, consoles/k36s/"
"AISLPC - GameConsole R36T| consoles/logo/480P/, consoles/kernel/common/, consoles/k36s/"
"AISLPC - GameConsole R36T MAX| consoles/logo/720P/, consoles/kernel/common/, consoles/r36tmax/"
"Batlexp - Batlexp G350| consoles/logo/480P/, consoles/kernel/common/, consoles/g350/"
"Kinhank - K36 Origin Panel| consoles/logo/480P/, consoles/kernel/common/, consoles/k36/"
"Powkiddy - Powkiddy RGB20S| consoles/logo/480P/, consoles/kernel/common/, consoles/rgb20s/"
"Clone R36s - Clone Type 1 With Amplifier| consoles/logo/480P/, consoles/kernel/common/, consoles/r36pro/"
"Clone R36s - Clone Type 1 Without Amplifier| consoles/logo/480P/, consoles/kernel/common/, consoles/hg36/"
"Clone R36s - Clone Type 1 Without Amplifier And Invert Right Joystick| consoles/logo/480P/, consoles/kernel/common/, consoles/k36/"
"Clone R36s - Clone Type 2 With Amplifier| consoles/logo/480P/, consoles/kernel/common/, consoles/clone type2 amp/"
"Clone R36s - Clone Type 2 Without Amplifier| consoles/logo/480P/, consoles/kernel/common/, consoles/clone type2/"
"Clone R36s - Clone Type 3| consoles/logo/480P/, consoles/kernel/common/, consoles/clone type3/"
"Clone R36s - Clone Type 4| consoles/logo/480P/, consoles/kernel/common/, consoles/clone type4/"
"Clone R36s - Clone Type 5| consoles/logo/480P/, consoles/kernel/common/, consoles/clone type5/"
"GameConsole - GameConsole R46H| consoles/logo/768P/, consoles/kernel/common/, consoles/r46h/"
"GameConsole - GameConsole R40XX| consoles/logo/768P/, consoles/kernel/common/, consoles/r40xx/"
"GameConsole - GameConsole R36sPlus| consoles/logo/720P/, consoles/kernel/common/, consoles/r36splus/"
"GameConsole - GameConsole R36s Panel 0| consoles/logo/480P/, consoles/kernel/common/, consoles/origin panel0/"
"GameConsole - GameConsole R36s Panel 1| consoles/logo/480P/, consoles/kernel/common/, consoles/origin panel1/"
"GameConsole - GameConsole R36s Panel 2| consoles/logo/480P/, consoles/kernel/common/, consoles/origin panel2/"
"GameConsole - GameConsole R36s Panel 3| consoles/logo/480P/, consoles/kernel/common/, consoles/origin panel3/"
"GameConsole - GameConsole R36s Panel 4| consoles/logo/480P/, consoles/kernel/common/, consoles/origin panel4/"
"GameConsole - GameConsole R36s Panel 4 V22| consoles/logo/480P/, consoles/kernel/common/, consoles/v22 panel4/"
"GameConsole - GameConsole R36XX| consoles/logo/480P/, consoles/kernel/common/, consoles/origin panel4/"
"GameConsole - GameConsole R36H| consoles/logo/480P/, consoles/kernel/common/, consoles/r36h/"
"GameConsole - GameConsole O30S| consoles/logo/480P/, consoles/kernel/common/, consoles/r36h/"
"GameConsole - GameConsole R50S| consoles/logo/854x480P/, consoles/kernel/common/, consoles/r50s/"
"SoySauce R36s - Soy Sauce V03| consoles/logo/480P/, consoles/kernel/common/, consoles/sauce v03/"
"SoySauce R36s - Soy Sauce V04| consoles/logo/480P/, consoles/kernel/common/, consoles/sauce v04/"
"Diium(SZDiiER) - Diium Dr28s| consoles/logo/480P-270/, consoles/kernel/common/, consoles/dr28s/"
"Diium(SZDiiER) - SZDiiER D007(Plus)| consoles/logo/480P/, consoles/kernel/common/, consoles/d007/"
"XiFan HandHelds - XiFan Mymini| consoles/logo/480P/, consoles/kernel/common/, consoles/mymini/"
"XiFan HandHelds - XiFan R36Max| consoles/logo/720P/, consoles/kernel/common/, consoles/r36max/"
"XiFan HandHelds - XiFan R36Pro| consoles/logo/480P/, consoles/kernel/common/, consoles/r36pro/"
"XiFan HandHelds - XiFan XF35H| consoles/logo/480P/, consoles/kernel/common/, consoles/xf35h/"
"XiFan HandHelds - XiFan XF40H| consoles/logo/720P/, consoles/kernel/common/, consoles/xf40h/"
"XiFan HandHelds - XiFan XF40V| consoles/logo/720P/, consoles/kernel/common/, consoles/dc40v/"
"XiFan HandHelds - XiFan DC35V| consoles/logo/480P/, consoles/kernel/common/, consoles/dc35v/"
"XiFan HandHelds - XiFan DC40V| consoles/logo/720P/, consoles/kernel/common/, consoles/dc40v/"
"Other - GameConsole HG36 （HG3506）| consoles/logo/480P/, consoles/kernel/common/, consoles/hg36/"
"Other - GameConsole R36Ultra| consoles/logo/720P/, consoles/kernel/common/, consoles/r36ultra/"
"Other - GameConsole RX6H| consoles/logo/480P/, consoles/kernel/common/, consoles/rx6h/"
"Other - GameConsole XGB36 (G26)| consoles/logo/480P/, consoles/kernel/common/, consoles/xgb36/"
"Other - GameConsole T16MAX| consoles/logo/720P/, consoles/kernel/common/, consoles/t16max/"
"Other - GameConsole U8| consoles/logo/480P5-3/, consoles/kernel/common/, consoles/u8/"
"Other - GameConsole U8 V2| consoles/logo/480P5-3/, consoles/kernel/common/, consoles/u8-v2/"
)

# Function to extract unique categories (Brands) from the data
get_brands() {
    local brands_list=()
    for entry in "${consoles[@]}"; do
        # Extract everything before " - "
        local brand="${entry%% - *}"
        brands_list+=("$brand")
    done
    # Print sorted unique brands
    printf "%s\n" "${brands_list[@]}" | sort -u
}

# Load the brands into an array
mapfile -t brand_options < <(get_brands)

echo "--- Device Configuration Setup ---"

while true; do
    echo -e "\nStep 1: Select a Category (Brand)"
    PS3="Select a number (or 'q' to quit): "

    select selected_brand in "${brand_options[@]}"; do
        if [[ "$REPLY" == "q" ]]; then
            echo "Exiting script."
            exit 0
        fi

        if [[ -n "$selected_brand" ]]; then
            echo -e "\nCategory Selected: $selected_brand"
            
            # Filter devices that belong to the selected brand
            device_list=()
            for entry in "${consoles[@]}"; do
                if [[ "$entry" == "$selected_brand - "* ]]; then
                    device_list+=("$entry")
                fi
            done

            echo "Step 2: Select a Device"
            PS3="Select a number (or 'b' to go back): "

            select device_entry in "${device_list[@]}"; do
                if [[ "$REPLY" == "b" ]]; then
                    break # Go back to Step 1
                fi

                if [[ -n "$device_entry" ]]; then
                    # Split the entry into readable name and paths
                    IFS='|' read -r full_display paths_str <<< "$device_entry"
                    # Remove the brand prefix for cleaner output
                    clean_device_name="${full_display#* - }"

                    echo -e "\nApplying configuration for: $clean_device_name"

                    # Process paths and copy files
                    IFS=',' read -ra paths <<< "$paths_str"
                    for path in "${paths[@]}"; do
                        path=$(echo "$path" | xargs) # Trim whitespace
                        if [ -d "$path" ]; then
                            echo "Copying contents of '$path' to current directory..."
                            cp -v "$path"* . 2>/dev/null
                        else
                            echo "Notice: Source directory '$path' not found. Skipping."
                        fi
                    done

                    echo -e "\nSetup for '$clean_device_name' complete."
                    exit 0
                else
                    echo "Invalid selection. Please try again."
                fi
            done
            break # Exit inner select to re-display Step 1 menu properly
        else
            echo "Invalid selection. Please try again."
        fi
    done
done
