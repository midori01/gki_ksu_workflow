#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE=".github/config/kernel_versions.json"
TMP_DIR="/tmp/kernel-check"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

REPO="${GITHUB_REPOSITORY:-midori01/gki_ksu_workflow}"

TAG_DATES_612=$(jq -r '.["6.12"].revisions | to_entries[] | select(.value.asb_date != "lts") | .value.asb_date' "$CONFIG_FILE")
TAG_DATES_66=$(jq -r '.["6.6"].revisions | to_entries[] | select(.value.asb_date != "lts") | .value.asb_date' "$CONFIG_FILE")
TAG_DATES_61=$(jq -r '.["6.1"].revisions | to_entries[] | select(.value.asb_date != "lts") | .value.asb_date' "$CONFIG_FILE")

SUB_612_LTS=$(jq -r '[.["6.12"].revisions | to_entries[] | select(.value.asb_date == "lts") | .key | tonumber] | max' "$CONFIG_FILE")
SUB_66_LTS=$(jq -r '[.["6.6"].revisions | to_entries[] | select(.value.asb_date == "lts") | .key | tonumber] | max' "$CONFIG_FILE")
SUB_61_LTS=$(jq -r '[.["6.1"].revisions | to_entries[] | select(.value.asb_date == "lts") | .key | tonumber] | max' "$CONFIG_FILE")

NEEDS_COMMIT=false

echo "=== Fetching refs from AOSP common kernel ==="
git ls-remote https://android.googlesource.com/kernel/common.git 2>/dev/null > "$TMP_DIR/all_refs.txt"
grep 'refs/tags/' "$TMP_DIR/all_refs.txt" | awk '{print $2}' | sed 's|refs/tags/||; s|\^{}||' | sort -Vu > "$TMP_DIR/all_tags.txt"

get_ref_commit() {
  local ref="$1"
  grep -F "$ref" "$TMP_DIR/all_refs.txt" 2>/dev/null | awk '{print $1}' | head -n 1 || echo ""
}

get_commit_date() {
  local commit="$1"
  local tmpd="/tmp/kernel-date-$$"
  rm -rf "$tmpd"
  git clone --depth 1 --no-checkout --filter=blob:none https://android.googlesource.com/kernel/common "$tmpd" 2>/dev/null
  if [ -d "$tmpd" ]; then
    git -C "$tmpd" fetch --depth 1 origin "$commit" 2>/dev/null
    local date
    date=$(git -C "$tmpd" log -1 --format='%ci' "$commit" 2>/dev/null || echo "")
    rm -rf "$tmpd"
    echo "$date"
  else
    rm -rf "$tmpd"
    echo ""
  fi
}

get_sublevel_from_head() {
  local branch_name="$1"
  local url="https://android.googlesource.com/kernel/common/+/refs/heads/${branch_name}/Makefile?format=TEXT"
  local content
  content=$(curl -s "$url" 2>/dev/null | base64 -d 2>/dev/null || echo "")
  if [[ -z "$content" ]]; then
    echo ""
    return
  fi
  local sublevel
  sublevel=$(echo "$content" | grep -oP '^SUBLEVEL\s*=\s*\K\d+' | head -n 1)
  echo "${sublevel:-}"
}

check_file_in_release() {
  local release_tag="$1" file_name="$2"
  gh release view "$release_tag" --repo "$REPO" --json assets -q ".assets[].name" 2>/dev/null | grep -qFx "$file_name"
}

download_and_upload_tag() {
  local release_tag="$1" tar_name="$2"
  local google_url="https://android.googlesource.com/kernel/common/+archive/refs/tags/${tar_name}"
  local local_file="$TMP_DIR/${tar_name}"
  local attempt=1 max_attempts=3 retry_delay=20

  if check_file_in_release "$release_tag" "$tar_name"; then
    echo "  File $tar_name already exists in release $release_tag, skipping."
    return 0
  fi

  while [[ $attempt -le $max_attempts ]]; do
    echo "  Downloading $tar_name (attempt $attempt/$max_attempts) ..."
    if curl -fsSL --connect-timeout 30 "$google_url" -o "$local_file"; then
      if [ -s "$local_file" ]; then
        echo "  Uploading to release $release_tag ..."
        if gh release upload "$release_tag" "$local_file" --repo "$REPO" --clobber; then
          echo "  Done: $tar_name"
          return 0
        else
          echo "  ERROR: Failed to upload $tar_name (attempt $attempt/$max_attempts)"
        fi
      else
        echo "  ERROR: Downloaded file is empty: $tar_name (attempt $attempt/$max_attempts)"
      fi
    else
      echo "  ERROR: Failed to download $tar_name (attempt $attempt/$max_attempts)"
    fi
    ((attempt < max_attempts)) && sleep "$retry_delay"
    ((attempt++))
  done
  return 1
}

download_head_archive() {
  local branch_name="$1" release_tag="$2" force="${3:-false}"
  local google_url="https://android.googlesource.com/kernel/common/+archive/refs/heads/${branch_name}.tar.gz"
  local tar_name="${branch_name}.tar.gz"
  local local_file="$TMP_DIR/${tar_name}"
  local attempt=1 max_attempts=3 retry_delay=20

  if [[ "$force" != "true" ]] && check_file_in_release "$release_tag" "$tar_name"; then
    echo "  File $tar_name already exists in release $release_tag."
    echo "$tar_name"
    return 0
  fi

  while [[ $attempt -le $max_attempts ]]; do
    echo "  Downloading $tar_name from heads (attempt $attempt/$max_attempts)..."
    if curl -fsSL --connect-timeout 30 "$google_url" -o "$local_file"; then
      if [ -s "$local_file" ]; then
        echo "  Uploading to release $release_tag ..."
        if gh release upload "$release_tag" "$local_file" --repo "$REPO" --clobber; then
          echo "  Done: $tar_name"
          echo "$tar_name"
          return 0
        fi
      else
        echo "  ERROR: Downloaded file is empty: $tar_name"
      fi
    else
      echo "  ERROR: Failed to download $tar_name"
    fi
    ((attempt < max_attempts)) && sleep "$retry_delay"
    ((attempt++))
  done
  return 1
}

extract_sublevel() {
  local tar_file="$1"
  local makefile_content
  makefile_content=$(tar -xzf "$tar_file" --to-stdout Makefile 2>/dev/null || echo "")
  if [[ -z "$makefile_content" ]]; then
    makefile_content=$(tar -xzf "$tar_file" --to-stdout */Makefile 2>/dev/null || echo "")
  fi
  if [[ -z "$makefile_content" ]]; then
    local subdir=$(tar -tzf "$tar_file" 2>/dev/null | grep -oP '^[^/]+/Makefile' | head -n 1 | cut -d/ -f1)
    if [[ -n "$subdir" ]]; then
      makefile_content=$(tar -xzf "$tar_file" --to-stdout "${subdir}/Makefile" 2>/dev/null || echo "")
    fi
  fi
  local sublevel
  sublevel=$(echo "$makefile_content" | grep -oP '^SUBLEVEL\s*=\s*\K\d+' | head -n 1)
  echo "${sublevel:-}"
}

check_tag() {
  local kv="$1" asb_date="$2" current_sub="$3" current_r="$4"

  echo ""
  echo "=== Checking $kv tag $asb_date (current: sub=$current_sub r=$current_r) ==="

  local android_ver=$(jq -r ".[\"$kv\"].android_version" "$CONFIG_FILE")
  local prefix="${android_ver}-${kv}-${asb_date}"

  if [[ "$current_r" == "none" ]]; then
    local head_commit=$(get_ref_commit "refs/heads/${prefix}")
    local old_commit=$(jq -r ".[\"$kv\"].revisions[\"${current_sub}\"].commit // \"\"" "$CONFIG_FILE")

    if [[ -z "$head_commit" ]]; then
      local latest_tag=$(grep -E "^${prefix}_r[0-9]+\$" "$TMP_DIR/all_tags.txt" | tail -n 1)
      if [[ -n "$latest_tag" ]]; then
        echo "  r=none but found r tag: $latest_tag, switching to tag download..."
        local new_r=$(echo "$latest_tag" | grep -oP '_r\d+' | head -n 1)
        new_r="${new_r#_}"
        local tar_name="${latest_tag}.tar.gz"

        if download_and_upload_tag "source-$kv" "$tar_name"; then
          local tag_commit=$(get_ref_commit "refs/tags/${latest_tag}")
          local commit_date=$(get_commit_date "$tag_commit")
          jq --arg kv "$kv" \
             --arg sub "$current_sub" \
             --arg asb "$asb_date" \
             --arg r "$new_r" \
             --arg commit "$tag_commit" \
             --arg commit_date "$commit_date" \
             '.[$kv].revisions[$sub] = {"asb_date": $asb, "default_r": $r, "supported_r": [$r, "none"], "commit": $commit, "commit_date": $commit_date}' \
             "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
          echo "  Updated JSON to r=$new_r."
          NEEDS_COMMIT=true
        fi
        return
      fi
      echo "  No head branch found for $prefix, skipping."
      return
    fi

    local tar_name="${prefix}.tar.gz"
    local force_download="false"
    if [[ "$head_commit" != "$old_commit" ]]; then
      force_download="true"
      echo "  Head commit changed: ${old_commit:0:7} -> ${head_commit:0:7}"
    fi

    if [[ "$force_download" == "false" ]]; then
      local existing_commit=$(jq -r ".[\"$kv\"].revisions[\"${current_sub}\"].commit // \"\"" "$CONFIG_FILE")
      local existing_date=$(jq -r ".[\"$kv\"].revisions[\"${current_sub}\"].commit_date // \"\"" "$CONFIG_FILE")
      if [[ -z "$existing_commit" || -z "$existing_date" ]]; then
        local commit_date=$(get_commit_date "$head_commit")
        jq --arg kv "$kv" \
           --arg sub "$current_sub" \
           --arg commit "$head_commit" \
           --arg commit_date "$commit_date" \
           '.[$kv].revisions[$sub].commit = $commit |
            .[$kv].revisions[$sub].commit_date = $commit_date' \
           "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        echo "  JSON missing commit or date, filled: ${head_commit:0:7}."
        NEEDS_COMMIT=true
      fi
      if check_file_in_release "source-$kv" "$tar_name"; then
        echo "  Head commit unchanged and file exists. Up to date."
        return
      else
        echo "  Head commit unchanged but file missing, re-downloading..."
        force_download="true"
      fi
    fi

    if downloaded=$(download_head_archive "$prefix" "source-$kv" "$force_download"); then
      local new_sub
      if [ -f "$TMP_DIR/${downloaded}" ]; then
        new_sub=$(extract_sublevel "$TMP_DIR/${downloaded}")
      else
        new_sub=$(get_sublevel_from_head "$prefix")
      fi
      if [[ -z "$new_sub" || ! "$new_sub" =~ ^[0-9]+$ ]]; then
        echo "  WARNING: Failed to extract SUBLEVEL, keeping current sub=$current_sub"
        new_sub="$current_sub"
      fi
      echo "  Extracted SUBLEVEL=$new_sub"

      local commit_date=$(get_commit_date "$head_commit")

      local new_default="$new_sub"
      local current_default=$(jq -r ".[\"$kv\"].default_sub_level" "$CONFIG_FILE")
      local use_lts=$(jq -r ".[\"$kv\"].use_lts // false" "$CONFIG_FILE")
      if [[ "$use_lts" == "true" ]]; then
        new_default="$current_default"
        echo "  use_lts=true, keeping default_sub_level=$current_default."
      elif [[ "$new_sub" -lt "$current_default" ]]; then
        new_default="$current_default"
        echo "  New sub ($new_sub) < current default ($current_default), keeping default."
      fi

      if [[ "$new_sub" != "$current_sub" ]]; then
        jq --arg kv "$kv" \
           --arg old_sub "$current_sub" \
           --arg sub "$new_sub" \
           --arg def "$new_default" \
           --arg asb "$asb_date" \
           --arg r "none" \
           --arg commit "$head_commit" \
           --arg commit_date "$commit_date" \
           '.[$kv].default_sub_level = $def |
            .[$kv].revisions |= del(.[$old_sub]) |
            .[$kv].revisions[$sub] = {"asb_date": $asb, "default_r": $r, "supported_r": [$r], "commit": $commit, "commit_date": $commit_date}' \
           "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
      else
        jq --arg kv "$kv" \
           --arg sub "$new_sub" \
           --arg def "$new_default" \
           --arg asb "$asb_date" \
           --arg r "none" \
           --arg commit "$head_commit" \
           --arg commit_date "$commit_date" \
           '.[$kv].default_sub_level = $def |
            .[$kv].revisions[$sub] = {"asb_date": $asb, "default_r": $r, "supported_r": [$r], "commit": $commit, "commit_date": $commit_date}' \
           "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
      fi
      echo "  Updated JSON sub=$new_sub commit=${head_commit:0:7}."
      NEEDS_COMMIT=true
    else
      echo "  Download failed after 3 attempts."
    fi
    return
  fi

  local latest_tag=$(grep -E "^${prefix}(_r[0-9]+)?\$" "$TMP_DIR/all_tags.txt" | tail -n 1)

  if [[ -z "$latest_tag" ]]; then
    echo "  No tags found for $prefix"
    return
  fi

  echo "  Latest tag: $latest_tag"

  local escaped_kv="${kv//./\\.}"
  local new_sub=$(echo "$latest_tag" | grep -oP "(?<=${escaped_kv}\.)[0-9]+" | head -n 1)
  [[ -z "$new_sub" ]] && new_sub="$current_sub"

  local new_r=$(echo "$latest_tag" | grep -oP '_r\d+' | head -n 1)
  new_r="${new_r#_}"
  [[ -z "$new_r" ]] && new_r="none"

  local r_suffix=""
  [[ "$new_r" != "none" ]] && r_suffix="_$new_r"
  local tar_name="${android_ver}-${kv}-${asb_date}${r_suffix}.tar.gz"

  if [[ "$new_r" == "$current_r" && "$new_sub" == "$current_sub" ]]; then
    local existing_commit=$(jq -r ".[\"$kv\"].revisions[\"${current_sub}\"].commit // \"\"" "$CONFIG_FILE")
    local existing_date=$(jq -r ".[\"$kv\"].revisions[\"${current_sub}\"].commit_date // \"\"" "$CONFIG_FILE")
    if [[ -z "$existing_commit" || -z "$existing_date" ]]; then
      local tag_commit=$(get_ref_commit "refs/tags/${latest_tag}")
      if [[ -n "$tag_commit" ]]; then
        local commit_date=$(get_commit_date "$tag_commit")
        echo "  JSON missing commit or date, filling: ${tag_commit:0:7}"
        jq --arg kv "$kv" \
           --arg sub "$current_sub" \
           --arg commit "$tag_commit" \
           --arg commit_date "$commit_date" \
           '.[$kv].revisions[$sub].commit = $commit |
            .[$kv].revisions[$sub].commit_date = $commit_date' \
           "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        NEEDS_COMMIT=true
      fi
    fi
    if check_file_in_release "source-$kv" "$tar_name"; then
      echo "  Up to date and file exists in release."
      return
    else
      echo "  JSON up to date, but file $tar_name missing in release. Will attempt download."
    fi
  else
    echo "  New: sub=$new_sub r=$new_r"
  fi

  local use_lts=$(jq -r ".[\"$kv\"].use_lts // false" "$CONFIG_FILE")
  local new_default="$new_sub"
  local current_default=$(jq -r ".[\"$kv\"].default_sub_level" "$CONFIG_FILE")

  if [[ "$use_lts" == "true" ]]; then
    new_default="$current_default"
    echo "  use_lts=true, keeping default_sub_level=$current_default."
  elif [[ "$new_sub" -lt "$current_default" ]]; then
    new_default="$current_default"
    echo "  Tag sub_level ($new_sub) < current default ($current_default), keeping default_sub_level."
  fi

  if download_and_upload_tag "source-$kv" "$tar_name"; then
    local tag_commit=$(get_ref_commit "refs/tags/${latest_tag}")
    local commit_date=$(get_commit_date "$tag_commit")
    if [[ "$new_r" != "$current_r" || "$new_sub" != "$current_sub" ]]; then
      if [[ "$new_sub" != "$current_sub" ]]; then
        jq --arg kv "$kv" \
           --arg old_sub "$current_sub" \
           --arg sub "$new_sub" \
           --arg def "$new_default" \
           --arg asb "$asb_date" \
           --arg r "$new_r" \
           --arg commit "$tag_commit" \
           --arg commit_date "$commit_date" \
           '.[$kv].default_sub_level = $def |
            .[$kv].revisions |= del(.[$old_sub]) |
            .[$kv].revisions[$sub] = {"asb_date": $asb, "default_r": $r, "supported_r": [$r, "none"], "commit": $commit, "commit_date": $commit_date}' \
           "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
      else
        jq --arg kv "$kv" \
           --arg sub "$new_sub" \
           --arg def "$new_default" \
           --arg asb "$asb_date" \
           --arg r "$new_r" \
           --arg commit "$tag_commit" \
           --arg commit_date "$commit_date" \
           '.[$kv].default_sub_level = $def |
            .[$kv].revisions[$sub] = {"asb_date": $asb, "default_r": $r, "supported_r": [$r, "none"], "commit": $commit, "commit_date": $commit_date}' \
           "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
      fi
      echo "  Updated JSON."
      NEEDS_COMMIT=true
    fi
  else
    echo "  Download/upload failed after 3 attempts, JSON NOT updated."
  fi
}

check_lts() {
  local kv="$1" current_sub="$2"

  echo ""
  echo "=== Checking $kv LTS (current sub=$current_sub) ==="

  if [[ ! "$current_sub" =~ ^[0-9]+$ ]]; then
    echo "  Invalid current_sub: $current_sub"
    return
  fi

  local use_lts=$(jq -r ".[\"$kv\"].use_lts // false" "$CONFIG_FILE")
  local android_ver=$(jq -r ".[\"$kv\"].android_version" "$CONFIG_FILE")
  local branch_name="${android_ver}-${kv}-lts"

  local head_commit=$(get_ref_commit "refs/heads/${branch_name}")
  local old_commit=$(jq -r ".[\"$kv\"].revisions[\"${current_sub}\"].commit // \"\"" "$CONFIG_FILE")

  if [[ -z "$head_commit" ]]; then
    echo "  No head branch found for $branch_name"
    return
  fi

  local tar_name="${branch_name}.tar.gz"
  local force_download="false"

  if [[ "$head_commit" == "$old_commit" ]]; then
    local existing_commit=$(jq -r ".[\"$kv\"].revisions[\"${current_sub}\"].commit // \"\"" "$CONFIG_FILE")
    local existing_date=$(jq -r ".[\"$kv\"].revisions[\"${current_sub}\"].commit_date // \"\"" "$CONFIG_FILE")
    if [[ -z "$existing_commit" || -z "$existing_date" ]]; then
      local commit_date=$(get_commit_date "$head_commit")
      jq --arg kv "$kv" \
         --arg sub "$current_sub" \
         --arg commit "$head_commit" \
         --arg commit_date "$commit_date" \
         '.[$kv].revisions[$sub].commit = $commit |
          .[$kv].revisions[$sub].commit_date = $commit_date' \
         "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
      echo "  JSON missing commit or date, filled: ${head_commit:0:7}."
      NEEDS_COMMIT=true
    fi
    if check_file_in_release "source-$kv" "$tar_name"; then
      echo "  LTS commit unchanged and file exists. Up to date."
      return
    else
      echo "  LTS commit unchanged but file missing, re-downloading..."
      force_download="true"
    fi
  else
    echo "  LTS commit changed: ${old_commit:0:7} -> ${head_commit:0:7}"
    force_download="true"
  fi

  if downloaded=$(download_head_archive "$branch_name" "source-$kv" "$force_download"); then
    local new_sub
    if [ -f "$TMP_DIR/${downloaded}" ]; then
      new_sub=$(extract_sublevel "$TMP_DIR/${downloaded}")
    else
      new_sub=$(get_sublevel_from_head "$branch_name")
    fi
    if [[ -z "$new_sub" || ! "$new_sub" =~ ^[0-9]+$ ]]; then
      echo "  WARNING: Failed to extract SUBLEVEL, keeping current sub=$current_sub"
      new_sub="$current_sub"
    fi
    echo "  Extracted SUBLEVEL=$new_sub"

    local commit_date=$(get_commit_date "$head_commit")

    if [[ "$use_lts" == "true" && "$new_sub" != "$current_sub" ]]; then
      jq --arg kv "$kv" \
         --arg sub "$new_sub" \
         --arg commit "$head_commit" \
         --arg commit_date "$commit_date" \
         '.[$kv].default_sub_level = $sub |
          .[$kv].revisions |= with_entries(select(.value.asb_date != "lts")) |
          .[$kv].revisions[$sub] = {"asb_date": "lts", "default_r": "r00", "supported_r": ["r00"], "commit": $commit, "commit_date": $commit_date}' \
         "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
      echo "  Updated JSON sub=$new_sub."
      NEEDS_COMMIT=true
    elif [[ "$head_commit" != "$old_commit" ]]; then
      if [[ "$new_sub" != "$current_sub" ]]; then
        jq --arg kv "$kv" \
           --arg old_sub "$current_sub" \
           --arg sub "$new_sub" \
           --arg commit "$head_commit" \
           --arg commit_date "$commit_date" \
           '.[$kv].revisions |= del(.[$old_sub]) |
            .[$kv].revisions[$sub] = {"asb_date": "lts", "default_r": "r00", "supported_r": ["r00"], "commit": $commit, "commit_date": $commit_date}' \
           "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
      else
        jq --arg kv "$kv" \
           --arg sub "$new_sub" \
           --arg commit "$head_commit" \
           --arg commit_date "$commit_date" \
           '.[$kv].revisions[$sub].commit = $commit |
            .[$kv].revisions[$sub].commit_date = $commit_date' \
           "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
      fi
      echo "  Updated JSON commit only."
      NEEDS_COMMIT=true
    fi
  else
    echo "  Download failed after 3 attempts."
  fi
}

for date in $TAG_DATES_612; do
  sub=$(jq -r ".[\"6.12\"].revisions | to_entries[] | select(.value.asb_date == \"$date\") | .key" "$CONFIG_FILE")
  r=$(jq -r ".[\"6.12\"].revisions[\"$sub\"].default_r" "$CONFIG_FILE")
  check_tag "6.12" "$date" "$sub" "$r"
done
check_lts "6.12" "$SUB_612_LTS"

for date in $TAG_DATES_66; do
  sub=$(jq -r ".[\"6.6\"].revisions | to_entries[] | select(.value.asb_date == \"$date\") | .key" "$CONFIG_FILE")
  r=$(jq -r ".[\"6.6\"].revisions[\"$sub\"].default_r" "$CONFIG_FILE")
  check_tag "6.6" "$date" "$sub" "$r"
done
check_lts "6.6" "$SUB_66_LTS"

for date in $TAG_DATES_61; do
  sub=$(jq -r ".[\"6.1\"].revisions | to_entries[] | select(.value.asb_date == \"$date\") | .key" "$CONFIG_FILE")
  r=$(jq -r ".[\"6.1\"].revisions[\"$sub\"].default_r" "$CONFIG_FILE")
  check_tag "6.1" "$date" "$sub" "$r"
done
check_lts "6.1" "$SUB_61_LTS"

if [ "$NEEDS_COMMIT" = true ]; then
  git config user.name "github-actions"
  git config user.email "actions@github.com"
  git add "$CONFIG_FILE"
  git diff --staged --quiet || git commit -m "auto: update kernel versions and upload sources"
  git push
fi
