#!/usr/bin/env bash
# pad-image.sh — Extend an image's canvas with whitespace padding.
# Usage: ./pad-image.sh <image-or-url> [percent] [color]
#   image-or-url — local path or URL (e.g. http://host:port/images/foo.png)
#                  URLs are mapped to local paths by stripping the origin.
#   percent      — whitespace on each side as % of original (default: 10)
#   color        — background color (default: white)

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <image-or-url> [percent] [color]" >&2
  exit 1
fi

input="$1"
percent="${2:-10}"
color="${3:-white}"

# If input looks like a URL, extract the path portion as the local file
if [[ "$input" =~ ^https?:// ]]; then
  # Strip scheme + host (everything up to the first / after ://)
  image="${input#*://}"   # remove scheme
  image="${image#*/}"     # remove host:port, leaving the path without leading /
  echo "URL detected → resolved to local path: $image"
else
  image="$input"
fi

if [[ ! -f "$image" ]]; then
  echo "Error: file not found: $image" >&2
  exit 1
fi

dims=$(identify -format '%w %h' "$image")
w=$(echo "$dims" | awk '{print $1}')
h=$(echo "$dims" | awk '{print $2}')

scale=$(awk "BEGIN {printf \"%.6f\", 1 + 2 * $percent / 100}")
new_w=$(awk "BEGIN {printf \"%d\", $w * $scale + 0.5}")
new_h=$(awk "BEGIN {printf \"%d\", $h * $scale + 0.5}")

convert "$image" -gravity center -background "$color" -extent "${new_w}x${new_h}" "$image"

echo "$image: ${w}x${h} → ${new_w}x${new_h} (${percent}% padding, ${color})"
