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

*用于编译和分发 GKI 内核的自动化 GitHub Actions CI/CD 工作流*

</div>

---

## 🚀 概述

本仓库实现了一个统一的、配置驱动的构建编排系统，可通过单次工作流触发，跨多个内核版本编译多种 **KernelSU** 变体。每个变体封装在各自独立的 Job 中，最大化了可维护性，简化了故障隔离，并为未来的变体和内核版本实现了无缝水平扩展。

---

## ⚙️ 配置

所有内核版本相关的设置都集中存放在 [`.github/config/kernel_versions.json`](.github/config/kernel_versions.json) 中。只需在工作流触发时提供 `kernel_version` 这一个输入参数，即可驱动整个构建矩阵——包括内核版本、子版本、编译器、Rust 可用性以及 AnyKernel3 分支选择。

> [!NOTE]
> **内核 6.12.23 移除说明：** 提交 [`650419b`](https://github.com/midori01/gki_ksu_workflow/commit/650419be4e0f4d976aa5f57bbfc9982d8bf130ed) 默认从构建矩阵中移除了已经[废弃](https://android.googlesource.com/kernel/common/+/refs/heads/deprecated/android16-6.12-2025-06)的 `android16-6.12-2025-06` 版本。如果仍有编译该版本需求，只需 revert 该提交（`git revert 650419b`）；如有其他内核版本需求，也可自行编辑 [`.github/config/kernel_versions.json`](.github/config/kernel_versions.json) 文件进行定制。

---

## 📦 构建变体

| 变体 | SUSFS | Droidspaces | Hook 类型 |
| :--- | :---: | :---: | :--- |
| [MidoriSU-KX](https://github.com/KOWX712/KernelSU) | ❌ | ❌ | `Kprobes` |
| [MidoriSU-KX-DS](https://github.com/KOWX712/KernelSU) | ❌ | ✅ | `Kprobes` |
| [MidoriSU-KX-SUSFS](https://github.com/KOWX712/KernelSU) | ✅ | ❌ | `De-inlined` |
| [MidoriSU-KX-SUSFS-DS](https://github.com/KOWX712/KernelSU) | ✅ | ✅ | `De-inlined` |
| [MidoriSU-NX](https://github.com/KernelSU-Next/KernelSU-Next) | ❌ | ❌ | `Tracepoint` |
| [MidoriSU-NX-DS](https://github.com/KernelSU-Next/KernelSU-Next) | ❌ | ✅ | `Tracepoint` |
| [MidoriSU-NX-SUSFS](https://github.com/KernelSU-Next/KernelSU-Next) | ✅ | ❌ | `De-inlined` |
| [MidoriSU-NX-SUSFS-DS](https://github.com/KernelSU-Next/KernelSU-Next) | ✅ | ✅ | `De-inlined` |
| [MidoriSU-OX](https://github.com/tiann/KernelSU) | ❌ | ❌ | `Kprobes` |
| [MidoriSU-OX-DS](https://github.com/tiann/KernelSU) | ❌ | ✅ | `Kprobes` |
| [MidoriSU-OX-SUSFS](https://github.com/tiann/KernelSU) | ✅ | ❌ | `De-inlined` |
| [MidoriSU-OX-SUSFS-DS](https://github.com/tiann/KernelSU) | ✅ | ✅ | `De-inlined` |
| [MidoriSU-RX](https://github.com/ReSukiSU/ReSukiSU) | ❌ | ❌ | `Manual` |
| [MidoriSU-RX-DS](https://github.com/ReSukiSU/ReSukiSU) | ❌ | ✅ | `Manual` |
| [MidoriSU-RX-SUSFS](https://github.com/ReSukiSU/ReSukiSU) | ✅ | ❌ | `De-inlined` |
| [MidoriSU-RX-SUSFS-DS](https://github.com/ReSukiSU/ReSukiSU) | ✅ | ✅ | `De-inlined` |
| [MidoriSU-XX](https://github.com/backslashxx/KernelSU) | ❌ | ❌ | `Branch Link` |
| [MidoriSU-XX-DS](https://github.com/backslashxx/KernelSU) | ❌ | ✅ | `Branch Link` |
| [MidoriSU-XX-SUSFS](https://github.com/backslashxx/KernelSU) | ✅ | ❌ | `De-inlined` |
| [MidoriSU-XX-SUSFS-DS](https://github.com/backslashxx/KernelSU) | ✅ | ✅ | `De-inlined` |

> \* **MidoriSU-RX 和 MidoriSU-XX 的 Hook 类型：** 可分别通过 `midorisu_rx_hook_mode` 与 `midorisu_xx_hook_mode` 运行时配置。
> - `midorisu_rx_hook_mode` — `manual`（默认）/ `tracepoint`
> - `midorisu_xx_hook_mode`：
>   - `branch link hijacking` — MidoriSU-XX 的默认值；通过 `CONFIG_KSU_HACK_ARM64_BRANCH_LINK` 扫描内核 text 段并直接覆写调用处跳转指令（`b`/`bl`）重定向到 Hook，无 trampoline 开销且兼容 ARM64 CFI
>   - `syscall table tampering` — 通过 `CONFIG_KSU_TAMPER_SYSCALL_TABLE` 直接修改 `sys_call_table` 系统调用表指针，避免间接跳转（`blr`）开销并兼容 Clang CFI
>   - `manual` — 通过 `scope-min-manual-hooks-v2.3.patch` 打入的手动 hook

> [!TIP]
> **矩阵构建编排：** 矩阵始终为每个变体产出恰好 **1 个构件** — 启用的功能（Droidspaces 和/或 SUSFS）会应用到该单一构件上。选择全部 5 个变体时，每个内核版本的 **每个子版本产生 5 次构建**。从 `kernel_version` 下拉菜单中选择 `all` 将并行编译 6.1、6.6 和 6.12 的所有子版本，在默认配置下共 **40 个并发 Job**。

---

## 📱 MidoriSU 管理器

[**MidoriSU**](https://github.com/midori01/KernelSU) 是面向所有 MidoriSU 内核变体的官方配套应用。基于 [**KowSU**](https://github.com/KOWX712/KernelSU) 进行了深度定制与功能扩展，无缝兼容整个 MidoriSU 系列 — **KX、NX、OX、RX、XX** — 包括所有 SUSFS 与 Droidspaces 组合。

| 功能 | 描述 |
| :--- | :--- |
| **首页概览** | 现代化仪表盘状态卡片：动态显示 KSU 驱动名称（原生驱动名与 LKM 动态识别）、Hook 类型、SUSFS 版本、Droidspaces 版本、Re:Kernel(-X) 版本、内核构建时间与 OEM 解锁状态。 |
| **双主题与外观定制** | 深度支持 Material 3 Expressive 与 Miuix 两套 UI 风格及实时主题预览；内置切换器，可在 **MidoriSU**、**KowSU** 与 **官方 KernelSU** 之间即时切换应用名称、图标及开屏主题。 |
| **镜像与内核刷写** | 支持在应用内直接备份与刷写 `boot.img` 分区，支持直接刷写 AnyKernel3 ZIP 刷机包并选择目标槽位（Slot A/B）。 |
| **授权列表备份与恢复** | 支持 Superuser 授权列表与应用配置文件的完整备份与恢复，跨机迁移与重装无忧。 |
| **模块导出为 ZIP** | 支持将已安装的任意活动/非活动模块一键打包并导出为标准可刷写的 ZIP 模块包。 |
| **内核模块 (LKM) 管理** | 浏览已加载的内核模块，支持动态加载与卸载操作。 |
| **内核诊断工具** | 应用内浏览、搜索与分享 `/proc/kallsyms` 内核符号、实时 dmesg 内核日志与 `CONFIG_*` 内核编译配置。 |
| **快捷开关与功能集成** | 支持即时切换 SELinux 运行模式（Enforcing / Permissive）、内置 SUSFS WebUI 快捷跳转入口与驱动更新检查开关。 |

---

## 🔧 Hook 类型参考

| 类型 | 机制与特性 |
| :--- | :--- |
| `Kprobes` | 运行时通过 kprobe 断点动态插桩内核函数。内核占用极小，兼容性广泛。 |
| `Tracepoint` | 接入内核的静态系统调用 tracepoint 基础设施（`sys_enter`/`sys_exit`），无需修改内核源码。 |
| `Inline` | 编译时通过直接嵌入内核子系统源码的 `#ifdef CONFIG_KSU_SUSFS` 代码块注入。使用 `static_key` 分支实现运行时切换。不依赖 kprobes 或 LSM 钩子。硬编码于 VFS（`exec`、`open`、`stat`、`readdir`、`statfs`）、SELinux（`avc`、`hooks`、`services`）、input、mounts 和 procfs。 |
| `De-inlined` | 通过内核源码打补丁而非内联 `#ifdef CONFIG_KSU_SUSFS` 代码块来应用 SUSFS 钩子。SUSFS 逻辑与核心内核子系统分离更清晰。 |
| `Manual` | 静态内核源码打补丁。编译时将自定义钩子注入核心内核子系统。 |
| `Branch Link Hijacking` | 扫描内核 text 段并直接改写调用处的跳转指令（`b`/`bl`）重定向到 Hook，避免 trampoline 开销并兼容 Clang CFI。通过 `CONFIG_KSU_HACK_ARM64_BRANCH_LINK` 启用。 |
| `Syscall Table Tampering` | 高性能系统调用表劫持方案，直接替换 `sys_call_table` 中特定系统调用指针（如 `sys_reboot`、`sys_execve` 等），避免间接跳转（`blr`）开销并兼容 Clang CFI。通过 `CONFIG_KSU_TAMPER_SYSCALL_TABLE` 启用。 |

---

## 🧩 附加功能

| 功能 | 描述 |
| :--- | :--- |
| **内核版本** | 选择 `6.1`、`6.6`、`6.12` 或 `all` 来编译一个或全部内核版本。子版本、修订号、编译器和 Rust 设置从集中配置中自动解析。 |
| **源码镜像** | 在 Google 官方 AOSP 镜像或自托管镜像之间选择，用于内核源码和工具链下载。 |
| **SUSFS 模块** | 当启用 SUSFS 时，自动获取最新的 [susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module) 并将其附加到发布中。单个 `susfs_commit` 输入控制所有变体的 SUSFS 版本。 |
| **KSU 工具箱** | 自动从 nightly.link 获取最新的 [ksu_toolkit](https://github.com/backslashxx/ksu_toolkit) 模块并将其附加到发布中。 |
| **Droidspaces** | 通过 [Droidspaces-OSS](https://github.com/ravindu644/Droidspaces-OSS) 提供容器支持 — SYSVIPC、IPC_NS、PID_NS、DEVTMPFS、NTSync 和网络。通过 `use_droidspaces` 开关按变体启用。 |
| **Re:Kernel(-X)** | 集成的 [Re:Kernel](https://github.com/Sakion-Team/Re-Kernel) 和 [Re:Kernel-X](https://github.com/myflavor/ReKernel-X) 模块直接编译进内核。提供 tombstone 冻结恢复、网络触发解冻和 binder 异步清理。通过 `use_rekernel` 开关控制。 |
| **VPNHide Next** | 通过 In-tree kpatch (`CONFIG_VPNHIDE=y`) 集成 [VPNHide Next](https://github.com/soranerai/vpnhide_next_backend)，在内核层隐藏 VPN 网络接口、路由规则和套接字描述符，无需依赖动态 LKM。自动将配套的 `vpnhide-bridge.zip` 模块附加到发布中。通过 `use_vpnhide` 开关控制。 |
| **Unicode 绕过修复** | 始终启用。修补内核 Unicode 规范化，以防止通过非标准 Unicode 编码进行文件系统绕过攻击。 |
| **ADIOS I/O 调度器** | 可选集成 [ADIOS](https://github.com/firelzrd/adios)，并作为内核的内置默认多队列 I/O 调度器。通过 `use_adios` 开关启用。 |
| **LZ4/ZSTD ZRAM 后端** | 可选将内核中的 LZ4 和 ZSTD 实现更新为官方 LZ4 1.10.0 与 Zstandard 1.5.7 版本，并为 kernel 6.12 (仅在6.12.23测试通过) 启用 ZRAM 后端。通过 `use_lz4_zstd` 开关控制；6.1 和 6.6 构建保持不变。 |
| **Ccache** | 编译器缓存集成，带有 60 秒等待守卫以确保依赖安装，保证跨工作流运行的健壮加速增量重建。 |
| **伪装构建元数据** | 可为编译镜像自定义 `kernel name`、`build timestamp`、`user` 和 `host` 字符串。 |

---

## ✅ 已测试设备

以下设备已确认可使用本工作流构建的内核：

| 品牌 | 型号 |
| :--- | :--- |
| Google | Pixel 7/8/9/10 系列 (Tensor) |
| Xiaomi | Xiaomi 17 系列 (Snapdragon) |
| Xiaomi | REDMI K90 Pro Max (Snapdragon) |
| Tecno | Tecno Camon 40 Pro 4G (Helio) |

> [!NOTE]
> **兼容性说明：**
> - 以上设备均运行 Android 16+，搭载 GKI 内核（6.1/6.6/6.12）
> - SUSFS 与 Droidspaces 功能已在所有设备系列上完成测试
> - 原厂系统用户建议通过 MidoriSU 管理器或 Kernel Flasher 刷入内核

> [!TIP]
> **你的设备不在列表中？**  
> 如果你已在其他设备上成功测试内核，欢迎提交 Issue 或 Pull Request 将其加入列表！

---
