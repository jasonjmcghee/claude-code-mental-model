#!/bin/bash
# Just read MentalModel.toml if it exists

# Find MentalModel.toml in current or parent directories
dir="$PWD"
for i in {1..5}; do
    if [ -f "$dir/MentalModel.toml" ]; then
        echo "# MentalModel.toml from $dir"
        echo
        cat "$dir/MentalModel.toml"
        exit 0
    fi
    dir="$(dirname "$dir")"
    [ "$dir" = "/" ] && break
done

exit 0