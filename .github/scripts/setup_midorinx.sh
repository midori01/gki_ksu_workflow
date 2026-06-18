#!/bin/bash
set -eu

echo "[+] Setting up MidoriNX (Change Manager and VersionCode)..."

if [ -f "KernelSU/kernel/manager/apk_sign.c" ]; then
  sed -i 's/unsigned char buffer\[0x11\] = { 0 };/return true;\n\tunsigned char buffer[0x11] = { 0 };/g' KernelSU/kernel/manager/apk_sign.c
  sed -i '/^bool is_manager_apk/,/^}$/d' KernelSU/kernel/manager/apk_sign.c
  cat >> KernelSU/kernel/manager/apk_sign.c << 'EOF'
bool is_manager_apk(char *path)
{
    char pkg[KSU_MAX_PACKAGE_NAME];
    if (get_pkg_from_apk_path(pkg, path) < 0) {
        pr_err("Failed to get package name from apk path: %s\n", path);
        return false;
    }
    return strcmp(pkg, "com.midori.supermanager") == 0 ||
           strcmp(pkg, "com.midori.su.manager") == 0;
}
EOF
fi

NEW_KSU_VERSION="${KSU_VERSION:-0}"

echo "[+] Dynamic KSU_VERSION (based on MidoriSU): $NEW_KSU_VERSION"

sed -i "s|^\$(eval KSU_VERSION=.*|KSU_VERSION := ${NEW_KSU_VERSION}|" KernelSU/kernel/Kbuild

echo "[+] MidoriNX setup complete."
