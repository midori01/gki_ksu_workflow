<div align="center">

🌐 [English](README.md) &nbsp;|&nbsp; [简体中文](README_CN.md) &nbsp;|&nbsp; [日本語](README_JP.md) &nbsp;|&nbsp; [한국어](README_KO.md)

</div>

<div align="center">

# 🌀 GKI KSU Workflow

![License](https://img.shields.io/github/license/midori01/gki_ksu_workflow?style=flat-square&color=blue)
![Last Commit](https://img.shields.io/github/last-commit/midori01/gki_ksu_workflow?style=flat-square&color=green)
![Release](https://img.shields.io/github/v/release/midori01/gki_ksu_workflow?style=flat-square&color=orange)

![Android](https://img.shields.io/badge/Android-GKI-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Kernel](https://img.shields.io/badge/Kernel-6.1_~_6.12-2F363D?style=for-the-badge&logo=linux&logoColor=white)
![Architecture](https://img.shields.io/badge/Arch-arm64-blue?style=for-the-badge)
![CI](https://img.shields.io/badge/CI-GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)

*Automated GitHub Actions CI/CD pipeline for compiling and distributing GKI kernels.*

</div>

---

## 🚀 Overview

This repository implements a unified, config-driven build orchestration system that compiles multiple **KernelSU** variants across multiple kernel versions from a single workflow trigger. Each variant is encapsulated within its own isolated job, maximizing maintainability, simplifying fault isolation, and enabling seamless horizontal scaling for future variants and kernel versions.

---

## ⚙️ Configuration

All kernel version-specific settings are centralized in [`.github/config/kernel_versions.json`](.github/config/kernel_versions.json). A single `kernel_version` input at workflow dispatch drives the entire build matrix — including Kernel version, Sub-level, Compiler, Rust availability, and AnyKernel3 branch selection.

---

## 📦 Build Variants

| Variant | SUSFS | Droidspaces | Hook Type |
| :--- | :---: | :---: | :--- |
| [MidoriSU-KO](https://github.com/KOWX712/KernelSU) | ❌ | ❌ | `Kprobes` |
| [MidoriSU-KO-DS](https://github.com/KOWX712/KernelSU) | ❌ | ✅ | `Kprobes` |
| [MidoriSU-KO-SUSFS](https://github.com/KOWX712/KernelSU) | ✅ | ❌ | `Inline` |
| [MidoriSU-KO-SUSFS-DS](https://github.com/KOWX712/KernelSU) | ✅ | ✅ | `Inline` |
| [MidoriSU-NX](https://github.com/KernelSU-Next/KernelSU-Next) | ❌ | ❌ | `Tracepoint` |
| [MidoriSU-NX-DS](https://github.com/KernelSU-Next/KernelSU-Next) | ❌ | ✅ | `Tracepoint` |
| [MidoriSU-NX-SUSFS](https://github.com/KernelSU-Next/KernelSU-Next) | ✅ | ❌ | `Inline` |
| [MidoriSU-NX-SUSFS-DS](https://github.com/KernelSU-Next/KernelSU-Next) | ✅ | ✅ | `Inline` |
| [MidoriSU-OG](https://github.com/tiann/KernelSU) | ❌ | ❌ | `Kprobes` |
| [MidoriSU-OG-DS](https://github.com/tiann/KernelSU) | ❌ | ✅ | `Kprobes` |
| [MidoriSU-OG-SUSFS](https://github.com/tiann/KernelSU) | ✅ | ❌ | `Inline` |
| [MidoriSU-OG-SUSFS-DS](https://github.com/tiann/KernelSU) | ✅ | ✅ | `Inline` |
| [MidoriSU-RE](https://github.com/ReSukiSU/ReSukiSU) | ❌ | ❌ | `Manual` |
| [MidoriSU-RE-DS](https://github.com/ReSukiSU/ReSukiSU) | ❌ | ✅ | `Manual` |
| [MidoriSU-RE-SUSFS](https://github.com/ReSukiSU/ReSukiSU) | ✅ | ❌ | `Inline` |
| [MidoriSU-RE-SUSFS-DS](https://github.com/ReSukiSU/ReSukiSU) | ✅ | ✅ | `Inline` |
| [MidoriSU-XX](https://github.com/backslashxx/KernelSU) | ❌ | ❌ | `Hookless` |
| [MidoriSU-XX-DS](https://github.com/backslashxx/KernelSU) | ❌ | ✅ | `Hookless` |
| [MidoriSU-XX-SUSFS](https://github.com/backslashxx/KernelSU) | ✅ | ❌ | `De-inlined` |
| [MidoriSU-XX-SUSFS-DS](https://github.com/backslashxx/KernelSU) | ✅ | ✅ | `De-inlined` |

> \* **MidoriSU-XX & MidoriSU-RE Hook Type:** Runtime-configurable via `hook_mode`.
> - `hookless` — default for MidoriSU-XX; uses `CONFIG_KSU_HACK_ARM64_BRANCH_LINK` on all kernel versions
> - `manual` — default for MidoriSU-RE
> - `tracepoint` — MidoriSU-RE only

> [!TIP]
> **Matrix Build Orchestration:** The matrix always produces exactly **1 artifact per variant** — the enabled features (Droidspaces and/or SUSFS) are applied to that single artifact. With all 5 variants selected, this yields **5 builds per kernel version**. Choosing `all` from the `kernel_version` dropdown compiles 6.1, 6.6 and 6.12 in parallel for a total of **15 concurrent jobs**.

---

## 📱 MidoriSU Manager

[**MidoriSU**](https://github.com/midori01/KernelSU) is the official companion app for all MidoriSU kernel variants. Built on [**KowSU**](https://github.com/KOWX712/KernelSU) with custom modifications, it offers seamless compatibility across the entire MidoriSU family — **KO, NX, OG, RE, XX** — including all SUSFS and Droidspaces combinations.

| Feature | Description |
| :--- | :--- |
| **Homepage Overview** | Displays essential kernel info at a glance: KSU driver name, hook type, SUSFS version, Droidspaces version, Re:Kernel/ReKernel-X version, and kernel build timestamp. |
| **Kernel Symbols** | Browse, search, and share `/proc/kallsyms` directly within the app. |
| **Kernel Logs** | View, search, and share dmesg output for quick debugging. |
| **Kernel Config** | Inspect, search, and share kernel build options (`CONFIG_*`). |
| **Boot Image** | Backup and flash `boot.img` without leaving the app. |
| **SELinux Toggle** | Instantly switch between Enforcing and Permissive SELinux modes. |

---

## 🔧 Hook Type Reference

| Type | Mechanism & Characteristics |
| :--- | :--- |
| `Kprobes` | Dynamically instruments kernel functions at runtime via kprobe breakpoints. Minimal kernel footprint, broad compatibility. **Default for MidoriSU-KO and MidoriSU-OG** (non-SUSFS). |
| `Tracepoint` | Hooks into the kernel's static syscall tracepoint infrastructure (`sys_enter`/`sys_exit`) without modifying kernel source. **Default for MidoriSU-NX** (non-SUSFS). |
| `Inline` | Compile-time injection via `#ifdef CONFIG_KSU_SUSFS` blocks embedded directly into kernel subsystem source. Uses `static_key` branches for runtime toggling. No reliance on kprobes or LSM hooks. Hardwired into VFS (`exec`, `open`, `stat`, `readdir`, `statfs`), SELinux (`avc`, `hooks`, `services`), input, mounts, and procfs. **Used by MidoriSU-KO-SUSFS, MidoriSU-NX-SUSFS, MidoriSU-RE-SUSFS, MidoriSU-OG-SUSFS.** |
| `De-inlined` | SUSFS hooks applied via kernel source patching rather than inline `#ifdef CONFIG_KSU_SUSFS` blocks. Cleaner separation of SUSFS logic from core kernel subsystems. **Used by MidoriSU-XX-SUSFS.** |
| `Manual` | Static kernel source patching. Custom hooks injected at compile time into core kernel subsystems. **Default for MidoriSU-RE** (non-SUSFS). |
| `Hookless` | Pure KernelSU built-in mechanisms. Always enables `CONFIG_KSU_HACK_ARM64_BRANCH_LINK` regardless of kernel version. Zero kernel source modification. Relies entirely on KernelSU's internal hooking infrastructure. **Default for MidoriSU-XX** (non-SUSFS). |

---

## 🧩 Additional Features

| Feature | Description |
| :--- | :--- |
| **Kernel Version** | Select `6.1`, `6.6`, `6.12`, or `all` to compile one or all kernel versions. Sub-level, revision, compiler, and Rust settings are auto-resolved from the centralized config. |
| **Source Mirror** | Choose between Google's official AOSP mirror or a self-hosted mirror for kernel source and toolchain downloads. |
| **eBPF Scene Hider** | Optionally compiles and packages [Scene Port Hider by eBPF](https://github.com/Andrea-lyz/Scene-Port-Hider-by-eBPF) alongside kernel artifacts. Spins up as soon as the first kernel build completes, independent of the remaining matrix jobs. |
| **SUSFS Module** | When SUSFS is enabled, automatically fetches the latest [susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module) and attaches it to the release. A single `susfs_commit` input controls SUSFS versions across variants. |
| **KSU Toolkit** | Automatically fetches the latest [ksu_toolkit](https://github.com/backslashxx/ksu_toolkit) module from nightly.link and attaches it to the release. |
| **Droidspaces** | Container support via [Droidspaces-OSS](https://github.com/ravindu644/Droidspaces-OSS) — SYSVIPC, IPC_NS, PID_NS, DEVTMPFS, NTSync, and networking. Enabled per-variant through the `use_droidspaces` toggle. |
| **Re:Kernel(-X)** | Integrated [Re:Kernel](https://github.com/Sakion-Team/Re-Kernel) and [Re:Kernel-X](https://github.com/myflavor/ReKernel-X) modules compiled directly into the kernel. Provides tombstone freeze recovery, network-triggered unfreeze, and binder async cleanup. Toggled via `use_rekernel` switch. |
| **Unicode Bypass Fix** | Patches kernel unicode normalization to prevent filesystem bypass attacks via non-standard unicode encodings. Toggled via `unicode_bypass_fix` switch. |
| **Ccache** | Compiler cache integration with a 60-second wait guard for dependency installation, ensuring robust accelerated incremental rebuilds across workflow runs. |
| **Spoofed Build Metadata** | Customizable `kernel name`, `build timestamp`, `user`, and `host` strings for the compiled image. |
