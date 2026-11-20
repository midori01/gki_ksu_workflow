#!/usr/bin/env bash
set -euo pipefail
module_dir=$(cd "$(dirname "$0")/../modules/tcp_congestion" && pwd)
mkdir -p "${1:?Pass an output directory}"
output=$(cd "$1" && pwd)
version=$(sed -n 's/^version=//p' "$module_dir/module.prop")
[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
stage=$(mktemp -d "$output/.tcp_congestion.XXXXXX")
trap 'rm -rf "$stage"' EXIT
name="TCP_Congestion_Control-$version.zip"
(cd "$module_dir" && zip -q -X -r "$stage/$name" module.prop skip_mount customize.sh tcpcc live-install.sh service.sh uninstall.sh webroot)
mv -f "$stage/$name" "$output/$name"
printf '%s\n' "$output/$name"
