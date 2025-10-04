#!/bin/bash
set -euo pipefail

# Check if correct number of arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source> <destination>"
    echo "Moves a Haskell module from <source> to <destination> and updates all references."
    echo "Accepts file paths or module names separated by dots."
    exit 1
fi

if [[ "$1" == *.hs ]]; then
    source_file="$1"
    destination_file="$2"
    if ! [ -f "$source_file" ]; then
        echo "Source file not found: $source_file"
        exit 1
    fi
    if [ -f "$destination_file" ] || [ -d "$destination_file" ]; then
        echo "Destination already exists: $destination_file"
        exit 1
    fi
    source_candidate=""
else
    source_candidate="$(echo "$1" | sed 's/\./\//g').hs"
    destination_candidate="$(echo "$2" | sed 's/\./\//g').hs"
    if [ -f "$source_candidate" ]; then
        source_file="$source_candidate"
        destination_file="$destination_candidate"
    else
        source_file="src/$source_candidate"
        destination_file="src/$destination_candidate"
        if ! [ -f "$source_file" ]; then
            echo "Could not find module at $source_candidate or $source_file"
            exit 1
        fi
    fi
fi

# Extract module names
old_module=$(grep -E "^module" "$source_file" | awk '{print $2}')
new_module=$(echo "$destination_file" | sed 's/\.hs$//' | sed 's|^src/||' | sed 's|/|.|g')

# if $source_candidate is set args 1/2 should match old_module/new_module
if [ -n "$source_candidate" ]; then
    if ! [ "$old_module" = "$1" ] || ! [ "$new_module" = "$2" ]; then
        echo "Unexpected mismatch between module names and file paths"
        echo "This is probably a bug in the script"
        exit 1
    fi
fi

# Move the file
mkdir -p "$(dirname "$destination_file")"
mv "$source_file" "$destination_file"

# Update module declaration in the moved file
sed -E -i '' "s/^module $old_module/module $new_module/" "$destination_file"

# Update references in all Haskell files
find . -name "*.hs" | while read -r file; do
    # Update import statements for the exact module
    sed -E -i '' "s/^import( qualified)? $old_module([^.]|$)/import\\1 $new_module\\2/g" "$file"

    # Update qualified imports for the exact module
    # skip this because it's hard to guess what `as` alias is used, and it generally won't be the fully qualified name
    # sed -i "s/\([^.]\)$old_module\.\([A-Za-z]\)/\1$new_module.\2/g" "$file"

    # Update export lists for the exact module
    sed -E -i '' "s/^(.+)module $old_module([^.]|$)/\\1module $new_module\\2/g" "$file"
done

echo "moved $old_module to $new_module"
