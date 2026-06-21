#!/bin/bash
set -eu

KSU_VERSION="${KSU_VERSION:-0}"

echo "[+] Setting up manager and version..."
echo "[+] Dynamic KSU_VERSION (based on MidoriSU): ${KSU_VERSION}"

if [ -f "KernelSU/kernel/manager/apk_sign.c" ]; then
  if grep -q 'com.midori.supermanager' KernelSU/kernel/manager/apk_sign.c; then
    echo "[+] Manager already patched, skipping."
  else
    if grep -q 'u8 \*signature_index' KernelSU/kernel/manager/apk_sign.c; then
      HAS_SIG=1
    else
      HAS_SIG=0
    fi

    sed -i 's/unsigned char buffer\[0x11\] = { 0 };/return true;\n\tunsigned char buffer[0x11] = { 0 };/g' KernelSU/kernel/manager/apk_sign.c
    sed -i '/^bool is_manager_apk/,/^}$/d' KernelSU/kernel/manager/apk_sign.c

    if [ "$HAS_SIG" = "1" ]; then
      cat >> KernelSU/kernel/manager/apk_sign.c << 'EOF'
bool is_manager_apk(char *path, u8 *signature_index)
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
    else
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
  fi
fi

sed -i '/^ccflags-y.*KSU_KERNEL_DIR/c\ccflags-y += -I$(srctree)/$(src) -I$(srctree)/$(src)/include -I$(src) -I$(src)/include' KernelSU/kernel/Kbuild 2>/dev/null || true
sed -i "s|^ccflags-y += -DKSU_VERSION=.*|ccflags-y += -DKSU_VERSION=${KSU_VERSION}|" KernelSU/kernel/Kbuild 2>/dev/null || true
sed -i "s|^CFLAGS_ksu\.o += -DKSU_VERSION=.*|CFLAGS_ksu.o += -DKSU_VERSION=${KSU_VERSION}|" KernelSU/kernel/Makefile 2>/dev/null || true
sed -i "s|^REPO_NAME := .*|REPO_NAME := MidoriRE|" KernelSU/kernel/Kbuild 2>/dev/null || true
sed -i 's|^\(\s*default "%TAG_NAME%\).*|\1-midori-build@%REPO_NAME%"|' KernelSU/kernel/Kconfig 2>/dev/null || true

echo "[+] KernelSU setup complete."
