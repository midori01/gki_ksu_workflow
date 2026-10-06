#!/bin/bash
set -eu

KSU_VERSION="${KSU_VERSION:-0}"

echo "[+] Setting up manager and version..."
echo "[+] Dynamic KSU_VERSION (based on MidoriSU): ${KSU_VERSION}"

sed -i 's/\(unsigned char buffer\[0x1[01]\] = { 0 };\)/return true;\n\t\1/g' KernelSU/kernel/manager/apk_sign.c 2>/dev/null || true
sed -i '1i KSU_MANAGER_PACKAGE := com.midori.supermanager' KernelSU/kernel/Kbuild 2>/dev/null || true
sed -E -i 's|^[[:space:]]*KSU_PACKAGE_NAME[[:space:]]*[:?]*=.*|KSU_PACKAGE_NAME := com.midori.supermanager|g' KernelSU/kernel/Kbuild KernelSU/kernel/Makefile 2>/dev/null || true
sed -i 's|#define test_extra_pkgs(tgt).*|#define test_extra_pkgs(tgt) 0|' KernelSU/kernel/manager/throne_tracker.c 2>/dev/null || true

sed -i '/^ccflags-y.*KSU_KERNEL_DIR/c\ccflags-y += -I$(srctree)/$(src) -I$(srctree)/$(src)/include -I$(src) -I$(src)/include' KernelSU/kernel/Kbuild 2>/dev/null || true
sed -i "s|^ccflags-y += -DKSU_VERSION=.*|ccflags-y += -DKSU_VERSION=${KSU_VERSION}|" KernelSU/kernel/Kbuild 2>/dev/null || true
sed -i "s|^CFLAGS_ksu\.o += -DKSU_VERSION=.*|CFLAGS_ksu.o += -DKSU_VERSION=${KSU_VERSION}|" KernelSU/kernel/Makefile 2>/dev/null || true
sed -i "s|^REPO_NAME := .*|REPO_NAME := MidoriSU|" KernelSU/kernel/Kbuild 2>/dev/null || true
sed -i 's|^\(\s*default "%TAG_NAME%\).*|\1-midori-build@%REPO_NAME%"|' KernelSU/kernel/Kconfig 2>/dev/null || true

echo "[+] KernelSU setup complete."
