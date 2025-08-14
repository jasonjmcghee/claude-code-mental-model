#!/bin/sh
# PostToolUse hook - reminds Claude to update MentalModel.toml when files change

# Read JSON input from stdin
input=$(cat)

# Extract tool name
tool_name=$(echo "$input" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)

# Only process Write, Edit, and MultiEdit tools
case "$tool_name" in
    Write|Edit|MultiEdit) ;;
    *) exit 0 ;;
esac

# Check if MentalModel.toml exists in project
dir="$PWD"
for i in 1 2 3 4 5; do
    if [ -f "$dir/MentalModel.toml" ]; then
        # Tell Claude to consider updating it (Claude will decide and just Edit it if needed)
        echo "File structure changed. If MentalModel.toml needs updating, update it directly." >&2
        exit 2  # Exit 2 shows message to Claude
    fi
    dir="$(dirname "$dir")"
    [ "$dir" = "/" ] && break
done

exit 0