#!/bin/bash
# Find duplicate base file names in a folder hierarchy

# Root directory to search (default: current dir)
SEARCH_DIR="${1:-.}"

# Collect all file names (base names only), count them, and show duplicates
find "$SEARCH_DIR" -type f -printf "%f\n" \
  | sort \
  | uniq -d \
  | while read -r fname; do
      echo "Duplicate: $fname"
      # Show all full paths for this duplicate
      find "$SEARCH_DIR" -type f -name "$fname"
      echo
    done
