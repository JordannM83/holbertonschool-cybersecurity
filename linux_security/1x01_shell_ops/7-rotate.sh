#!/bin/bash
DIRECTORY="$1"
if [ -d "$DIRECTORY" ]; then
    mkdir -p "$DIRECTORY"/backups
    for file in "$DIRECTORY"/*.log; do
        if [[ -f "$file" ]]; then
            size=$(stat -c%s "$file")
            if [ "$size" -gt 1024 ]; then
                gzip "$file"
                mv "$file.gz" "$DIRECTORY/backups/"
            else
                echo "Skipping small file: $(basename "$file")"
            fi
        fi
    done
else
    exit 1
fi
