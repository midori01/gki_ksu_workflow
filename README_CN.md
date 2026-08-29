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

---

## 📦 构建变体

| 变体 | SUSFS | Droidspaces | Hook 类型 |
| :--- | :---: | :---: | :--- |
| [MidoriSU-KX](https://github.com/KOWX712/KernelSU) | ❌ | ❌ | `Kprobes` |
| [MidoriSU-KX-DS](https://github.com/KOWX712/KernelSU) | ❌ | ✅ | `Kprobes` |
| [MidoriSU-KX-SUSFS](https://github.com/KOWX712/KernelSU) | ✅ | ❌ | `Inline` |
| [MidoriSU-KX-SUSFS-DS](https://github.com/KOWX712/KernelSU) | ✅ | ✅ | `Inline` |
| [MidoriSU-NX](https://github.com/KernelSU-Next/KernelSU-Next) | ❌ | ❌ | `Tracepoint` |
| [MidoriSU-NX-DS](https://github.com/KernelSU-Next/KernelSU-Next) | ❌ | ✅ | `Tracepoint` |
| [MidoriSU-NX-SUSFS](https://github.com/KernelSU-Next/KernelSU-Next) | ✅ | ❌ | `Inline` |
| [MidoriSU-NX-SUSFS-DS](https://github.com/KernelSU-Next/KernelSU-Next) | ✅ | ✅ | `Inline` |
| [MidoriSU-OX](https://github.com/tiann/KernelSU) | ❌ | ❌ | `Kprobes` |
| [MidoriSU-OX-DS](https://github.com/tiann/KernelSU) | ❌ | ✅ | `Kprobes` |
| [MidoriSU-OX-SUSFS](https://github.com/tiann/KernelSU) | ✅ | ❌ | `Inline` |
| [MidoriSU-OX-SUSFS-DS](https://github.com/tiann/KernelSU) | ✅ | ✅ | `Inline` |
| [MidoriSU-RX](https://github.com/ReSukiSU/ReSukiSU) | ❌ | ❌ | `Manual` |
| [MidoriSU-RX-DS](https://github.com/ReSukiSU/ReSukiSU) | ❌ | ✅ | `Manual` |
| [MidoriSU-RX-SUSFS](https://github.com/ReSukiSU/ReSukiSU) | ✅ | ❌ | `Inline` |
| [MidoriSU-RX-SUSFS-DS](https://github.com/ReSukiSU/ReSukiSU) | ✅ | ✅ | `Inline` |
| [MidoriSU-XX](https://github.com/backslashxx/KernelSU) | ❌ | ❌ | `Hookless` |
| [MidoriSU-XX-DS](https://github.com/backslashxx/KernelSU) | ❌ | ✅ | `Hookless` |
| [MidoriSU-XX-SUSFS](https://github.com/backslashxx/KernelSU) | ✅ | ❌ | `De-inlined` |
| [MidoriSU-XX-SUSFS-DS](https://github.com/backslashxx/KernelSU) | ✅ | ✅ | `De-inlined` |

> \* **MidoriSU-XX 和 MidoriSU-RX 的 Hook 类型：** 可通过 `hook_mode` 运行时配置。
> - `hookless` — MidoriSU-XX 的默认值；所有内核版本均使用 `CONFIG_KSU_HACK_ARM64_BRANCH_LINK`
> - `manual` — MidoriSU-RX 的默认值
> - `tracepoint` — 仅限 MidoriSU-RX

> [!TIP]
> **矩阵构建编排：** 矩阵始终为每个变体产出恰好 **1 个构件** — 启用的功能（Droidspaces 和/或 SUSFS）会应用到该单一构件上。选择全部 5 个变体时，每个内核版本的 **每个子版本产生 5 次构建**。从 `kernel_version` 下拉菜单中选择 `all` 将并行编译 6.1、6.6 和 6.12 的所有子版本，在默认配置下共 **30 个并发 Job**。

---

## 📱 MidoriSU 管理器

[**MidoriSU**](https://github.com/midori01/KernelSU) 是面向所有 MidoriSU 内核变体的官方配套应用。基于 [**KowSU**](https://github.com/KOWX712/KernelSU) 并进行定制修改，无缝兼容整个 MidoriSU 系列 — **KX、NX、OX、RX、XX** — 包括所有 SUSFS 与 Droidspaces 组合。

| 功能 | 描述 |
| :--- | :--- |
| **首页概览** | 一目了然地显示关键内核信息：KSU 驱动名称、Hook 类型、SUSFS 版本、Droidspaces 版本、Re:Kernel/ReKernel-X 版本以及内核编译时间。 |
| **内核符号** | 在应用内直接浏览、搜索和分享 `/proc/kallsyms`。 |
| **内核日志** | 查看、搜索和分享 dmesg 输出，便于快速调试。 |
| **内核配置** | 查看、搜索和分享内核编译选项（`CONFIG_*`）。 |
| **Boot 镜像** | 无需离开应用即可备份和刷写 `boot.img`。 |
| **SELinux 切换** | 在 Enforcing 与 Permissive 模式之间即时切换。 |

---

## 🔧 Hook 类型参考

| 类型 | 机制与特性 |
| :--- | :--- |
| `Kprobes` | 运行时通过 kprobe 断点动态插桩内核函数。内核占用极小，兼容性广泛。**MidoriSU-KX 和 MidoriSU-OX 的默认类型**（非 SUSFS）。 |
| `Tracepoint` | 接入内核的静态系统调用 tracepoint 基础设施（`sys_enter`/`sys_exit`），无需修改内核源码。**MidoriSU-NX 的默认类型**（非 SUSFS）。 |
| `Inline` | 编译时通过直接嵌入内核子系统源码的 `#ifdef CONFIG_KSU_SUSFS` 代码块注入。使用 `static_key` 分支实现运行时切换。不依赖 kprobes 或 LSM 钩子。硬编码于 VFS（`exec`、`open`、`stat`、`readdir`、`statfs`）、SELinux（`avc`、`hooks`、`services`）、input、mounts 和 procfs。**用于 MidoriSU-KX-SUSFS、MidoriSU-NX-SUSFS、MidoriSU-RX-SUSFS、MidoriSU-OX-SUSFS。** |
| `De-inlined` | 通过内核源码打补丁而非内联 `#ifdef CONFIG_KSU_SUSFS` 代码块来应用 SUSFS 钩子。SUSFS 逻辑与核心内核子系统分离更清晰。**用于 MidoriSU-XX-SUSFS。** |
| `Manual` | 静态内核源码打补丁。编译时将自定义钩子注入核心内核子系统。**MidoriSU-RX 的默认类型**（非 SUSFS）。 |
| `Hookless` | 纯 KernelSU 内置机制。所有内核版本均启用 `CONFIG_KSU_HACK_ARM64_BRANCH_LINK`。零内核源码修改。完全依赖 KernelSU 的内部 Hook 基础设施。**MidoriSU-XX 的默认类型**（非 SUSFS）。 |

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
