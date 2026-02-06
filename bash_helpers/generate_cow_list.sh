#!/bin/bash

function generate_cow_list() {
    # 1. Inputs
    local max_height=${1:-100}
    local show_preview=${2:-true}
    local list=""

    echo "🔍 Scanning for animals under $max_height lines..."

    # Check for cowsay
    if ! command -v cowsay &> /dev/null; then
        echo "❌ Error: 'cowsay' is not installed."
        return 1
    fi

    # 2. Get list of cows
    local raw_cows
    raw_cows=$(cowsay -l | tail -n +2)

    for animal in $raw_cows; do

        # Generate art to measure height
        # We define variables separately to be "safe" bash practice
        local art
        art=$(cowsay -f "$animal" "." 2>/dev/null)

        # Skip empty results
        if [[ -z "$art" ]]; then continue; fi

        # Count lines
        local lines
        lines=$(echo "$art" | wc -l)

        # 3. Check Height
        if [[ "$lines" -le "$max_height" ]]; then
            # Append to our list string
            list="$list $animal"

            # 4. Handle Visuals
            if [[ "$show_preview" == "true" ]]; then
                echo "----------------------------------------"
                echo "🐭 $animal (Height: $lines)"
                # Check if lolcrab exists, otherwise just echo
                if command -v lolcrab &> /dev/null; then
                    echo "$art" | lolcrab
                else
                    echo "$art"
                fi
            else
                # Print dot for progress
                echo -n "."
            fi
        fi
    done

    # 5. Final Output
    echo "" # Newline after the dots
    echo "✅ COMPLETE! Copy the line below:"
    echo "----------------------------------------"
    echo "local small_animals=( $list )"
    echo "----------------------------------------"
}

# Run the function with script arguments
generate_cow_list "$@"
