#!/usr/bin/env bash
#
# generate-image-index.sh
# Parses all MDX files, extracts metadata and image references,
# copies images and generates an HTML index page for visual review.
#

set -euo pipefail

DOCS_ROOT="/home/ubuntu/dev/mintlify-docs"
DEST_ROOT="/var/www/bigbluebutton-default/assets/mintlify"
DEST_IMAGES="$DEST_ROOT/images"
HTML_FILE="$DEST_ROOT/index.html"

# ── Prepare destination ───────────────────────────────────────────────
sudo mkdir -p "$DEST_IMAGES"
sudo chown -R "$USER:$USER" "$DEST_ROOT"

# ── Copy all images (preserving subdirectory structure) ───────────────
rsync -a --delete "$DOCS_ROOT/images/" "$DEST_IMAGES/"

# ── Collect MDX files sorted alphabetically ───────────────────────────
mapfile -t MDX_FILES < <(find "$DOCS_ROOT" -name '*.mdx' -not -path '*/snippets/*' -not -path '*/node_modules/*' | sort)

# ── Parse each MDX file ──────────────────────────────────────────────
declare -a FILE_PATHS=()
declare -a FILE_TITLES=()
declare -a FILE_DESCS=()
declare -a FILE_IMAGES=()   # pipe-separated image paths per file

total_files_with_images=0
total_image_refs=0

for mdx in "${MDX_FILES[@]}"; do
    rel_path="${mdx#$DOCS_ROOT/}"

    # Extract image references (both /images/... and images/... without leading /)
    img_refs=$(grep -oP '!\[[^\]]*\]\(\K(/images/[^)]+|images/[^)]+)' "$mdx" 2>/dev/null || true)

    # Skip files with no images
    [[ -z "$img_refs" ]] && continue

    # Extract frontmatter (between first --- and second ---)
    frontmatter=$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$mdx")

    title=$(echo "$frontmatter" | grep -m1 '^title:' | sed 's/^title:[[:space:]]*//' | sed 's/^["'"'"']\(.*\)["'"'"']$/\1/')
    description=$(echo "$frontmatter" | grep -m1 '^description:' | sed 's/^description:[[:space:]]*//' | sed 's/^["'"'"']\(.*\)["'"'"']$/\1/')

    # Normalize image paths: strip leading / so they're relative
    normalized_imgs=""
    count=0
    while IFS= read -r img; do
        [[ -z "$img" ]] && continue
        img="${img#/}"  # strip leading slash
        if [[ -n "$normalized_imgs" ]]; then
            normalized_imgs="$normalized_imgs|$img"
        else
            normalized_imgs="$img"
        fi
        (( count++ )) || true
    done <<< "$img_refs"

    FILE_PATHS+=("$rel_path")
    FILE_TITLES+=("$title")
    FILE_DESCS+=("$description")
    FILE_IMAGES+=("$normalized_imgs")

    (( total_files_with_images++ )) || true
    (( total_image_refs += count )) || true
done

echo "Found $total_files_with_images MDX files with images ($total_image_refs total image references)"

# ── Generate HTML ─────────────────────────────────────────────────────
cat > "$HTML_FILE" << 'HTMLHEAD'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>BigBlueButton Docs - Image Index</title>
<style>
  :root {
    --bg: #f8f9fa;
    --card-bg: #ffffff;
    --border: #dee2e6;
    --text: #212529;
    --muted: #6c757d;
    --accent: #0d6efd;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background: var(--bg);
    color: var(--text);
    line-height: 1.6;
    padding: 2rem;
  }
  header {
    max-width: 1200px;
    margin: 0 auto 2rem;
  }
  header h1 { font-size: 1.75rem; margin-bottom: 0.5rem; }
  .stats {
    display: flex;
    gap: 2rem;
    color: var(--muted);
    font-size: 0.95rem;
    margin-bottom: 1rem;
  }
  .stats strong { color: var(--text); }
  .section {
    max-width: 1200px;
    margin: 0 auto 2rem;
    background: var(--card-bg);
    border: 1px solid var(--border);
    border-radius: 8px;
    overflow: hidden;
  }
  .section-header {
    padding: 1rem 1.25rem;
    border-bottom: 1px solid var(--border);
    background: #f1f3f5;
  }
  .section-header .filepath {
    font-family: 'SFMono-Regular', Consolas, monospace;
    font-size: 0.85rem;
    color: var(--accent);
    word-break: break-all;
  }
  .section-header .title {
    font-size: 1.1rem;
    font-weight: 600;
    margin-top: 0.25rem;
  }
  .section-header .desc {
    font-size: 0.9rem;
    color: var(--muted);
    margin-top: 0.15rem;
  }
  .image-grid {
    padding: 1.25rem;
    display: flex;
    flex-wrap: wrap;
    gap: 1rem;
  }
  .image-card {
    border: 1px solid var(--border);
    border-radius: 6px;
    overflow: hidden;
    max-width: 100%;
  }
  .image-card img {
    display: block;
    max-width: 100%;
    height: auto;
  }
  .image-card .img-label {
    padding: 0.35rem 0.6rem;
    font-size: 0.75rem;
    color: var(--muted);
    background: #f8f9fa;
    border-top: 1px solid var(--border);
    word-break: break-all;
    font-family: 'SFMono-Regular', Consolas, monospace;
  }
  footer {
    max-width: 1200px;
    margin: 2rem auto;
    text-align: center;
    color: var(--muted);
    font-size: 0.85rem;
  }
</style>
</head>
<body>
<header>
  <h1>BigBlueButton Docs &mdash; Image Index</h1>
HTMLHEAD

# Stats line
cat >> "$HTML_FILE" << EOF
  <div class="stats">
    <span><strong>$total_files_with_images</strong> pages with images</span>
    <span><strong>$total_image_refs</strong> total image references</span>
    <span>Generated $(date '+%Y-%m-%d %H:%M:%S')</span>
  </div>
</header>
EOF

# Emit each section
for i in "${!FILE_PATHS[@]}"; do
    rel="${FILE_PATHS[$i]}"
    title="${FILE_TITLES[$i]}"
    desc="${FILE_DESCS[$i]}"
    imgs="${FILE_IMAGES[$i]}"

    # HTML-escape basic characters
    esc_title=$(echo "$title" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
    esc_desc=$(echo "$desc" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')

    cat >> "$HTML_FILE" << EOF
<div class="section">
  <div class="section-header">
    <div class="filepath">$rel</div>
EOF

    [[ -n "$title" ]] && echo "    <div class=\"title\">$esc_title</div>" >> "$HTML_FILE"
    [[ -n "$desc" ]] && echo "    <div class=\"desc\">$esc_desc</div>" >> "$HTML_FILE"

    cat >> "$HTML_FILE" << 'EOF'
  </div>
  <div class="image-grid">
EOF

    IFS='|' read -ra img_arr <<< "$imgs"
    for img in "${img_arr[@]}"; do
        [[ -z "$img" ]] && continue
        # Image src is relative to the HTML file location
        basename_img="${img#images/}"  # strip images/ prefix for label
        cat >> "$HTML_FILE" << EOF
    <div class="image-card">
      <img src="images/$basename_img" alt="$basename_img" loading="lazy">
      <div class="img-label">$img</div>
    </div>
EOF
    done

    echo '  </div>' >> "$HTML_FILE"
    echo '</div>' >> "$HTML_FILE"
done

# Footer
cat >> "$HTML_FILE" << 'EOF'
<footer>BigBlueButton Documentation Image Index</footer>
</body>
</html>
EOF

echo "HTML index generated at: $HTML_FILE"
echo "Images copied to: $DEST_IMAGES"
echo "Image count: $(find "$DEST_IMAGES" -type f | wc -l) files"
