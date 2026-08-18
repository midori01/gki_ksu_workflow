#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-.github/config/kernel_versions.json}"
TMP_DIR="${TMP_DIR:-/tmp/toolchain-bootstrap}"
REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
SOURCE_REPO="${TOOLCHAIN_SOURCE_REPO:-midori01/gki_ksu_workflow}"

command -v gh >/dev/null 2>&1 || { echo "::error::gh is required"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "::error::jq is required"; exit 1; }

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT

ensure_release() {
  local tag="$1"

  if gh release view "$tag" --repo "$REPO" >/dev/null 2>&1; then
    return 0
  fi

  echo "Creating missing release $REPO:$tag ..."
  if gh release create "$tag" \
    --repo "$REPO" \
    --title "$tag" \
    --prerelease \
    --notes "Managed kernel source and toolchain mirror"; then
    return 0
  fi

  # Another workflow may have created it between the view and create calls.
  gh release view "$tag" --repo "$REPO" >/dev/null 2>&1 || {
    echo "::error::Failed to create release $REPO:$tag"
    return 1
  }
}

sync_asset() {
  local tag="$1"
  local asset="$2"
  local destination="$TMP_DIR/$tag/$asset"

  if gh release view "$tag" --repo "$REPO" --json assets -q '.assets[].name' \
    | grep -Fxq "$asset"; then
    echo "  $asset already exists in $REPO:$tag"
    return 0
  fi

  if [[ "$SOURCE_REPO" == "$REPO" ]]; then
    echo "::error::$REPO:$tag is missing $asset, and TOOLCHAIN_SOURCE_REPO points to the same repository"
    return 1
  fi

  rm -rf "$TMP_DIR/$tag"
  mkdir -p "$TMP_DIR/$tag"
  echo "  Downloading $asset from $SOURCE_REPO:$tag ..."
  gh release download "$tag" \
    --repo "$SOURCE_REPO" \
    --pattern "$asset" \
    --dir "$TMP_DIR/$tag"

  [[ -s "$destination" ]] || {
    echo "::error::Downloaded asset is missing or empty: $destination"
    return 1
  }

  echo "  sha256 $(sha256sum "$destination" | cut -d' ' -f1)  $asset"
  gh release upload "$tag" "$destination" --repo "$REPO" --clobber
}

for kv in 6.1 6.6 6.12; do
  config=$(jq -c ".[\"$kv\"]" "$CONFIG_FILE")
  tag=$(echo "$config" | jq -r '.mirror_tag')
  clang=$(echo "$config" | jq -r '.default_clang')

  ensure_release "$tag"
  sync_asset "$tag" "clang-${clang}.tar.gz"
  sync_asset "$tag" "build-tools.tar.gz"

  if [[ "$(echo "$config" | jq -r '.rust')" == "true" ]]; then
    rust=$(echo "$config" | jq -r '.default_rust')
    sync_asset "$tag" "clang-tools.tar.gz"
    sync_asset "$tag" "rust-${rust}.tar.gz"
  fi
done

echo "Toolchain releases are ready."
