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

*用于编译和分发 GKI 内核的自动化 GitHub Actions CI/CD 流水线。*

</div>

---

## 🚀 概述

本仓库实现了一个统一的、配置驱动的构建编排系统，只需单次工作流触发，即可跨多个内核版本编译多种 **KernelSU** 变体。每个变体均封装在各自独立的 Job 中，最大化可维护性，简化故障隔离，并为未来的变体和内核版本实现无缝的水平扩展。

---

## ⚙️ 配置

所有内核版本相关的配置均集中在 [`.github/config/kernel_versions.json`](.github/config/kernel_versions.json) 中。触发工作流时只需提供 `kernel_version` 一个输入，即可驱动整个构建矩阵——包括内核版本、子版本、编译器、Rust 可用性以及 AnyKernel3 分支选择。

> [!NOTE]
> **内核 6.12.23 弃用说明：** 提交 [`650419b`](https://github.com/midori01/gki_ksu_workflow/commit/650419be4e0f4d976aa5f57bbfc9982d8bf130ed) 已将[已弃用](https://android.googlesource.com/kernel/common/+/refs/heads/deprecated/android16-6.12-2025-06)的 `android16-6.12-2025-06` 分支从默认构建矩阵中移除。若仍需该版本，只需还原该提交（`git revert 650419b`）；若需要其他内核版本或修订版本，可直接编辑 [`.github/config/kernel_versions.json`](.github/config/kernel_versions.json)。

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

> \* **MidoriSU-RX 与 MidoriSU-XX Hook 类型：** 可分别通过 `midorisu_rx_hook_mode` 与 `midorisu_xx_hook_mode` 进行配置。
> - `midorisu_rx_hook_mode` — `manual`（默认）/ `tracepoint`
> - `midorisu_xx_hook_mode`：
>   - `branch link hijacking` — MidoriSU-XX 的默认值；利用 `CONFIG_KSU_HACK_ARM64_BRANCH_LINK` 扫描内核 text 段，直接将调用处的跳转指令（`b`/`bl`）覆写并重定向至 Hook，规避 trampoline 开销且符合 ARM64 CFI 规范
>   - `syscall table tampering` — 利用 `CONFIG_KSU_TAMPER_SYSCALL_TABLE` 直接篡改 `sys_call_table` 表项，避免间接跳转（`blr`）开销且符合 Clang CFI 规范
>   - `manual` — 通过 `scope-min-manual-hooks-v2.3.patch` 打入的手动 Hook
> - `midorisu_xx_kpatch_compat` — 配合 `branch link hijacking` 使用，为 MidoriSU-XX 打入 KernelPatch 兼容修复（execve 回退与 syscall table mirror 跳过）

> [!TIP]
> **矩阵构建编排：** 矩阵始终为每个变体产出恰好 **1 个构建产物** — 启用的各项功能（Droidspaces 和/或 SUSFS）均应用至该单一构建产物。选择 `all` 变体时（MidoriSU-RX 不包含在 `all` 中，仅在单独选择时构建），每个内核版本的 **每个子版本产生 4 次构建**。从 `kernel_version` 下拉菜单中选择 `all` 将并行编译 6.1、6.6 与 6.12 的所有子版本，共 **32 个并发 Job**。

---

## 📱 MidoriSU 管理器

[**MidoriSU**](https://github.com/midori01/KernelSU) 是面向所有 MidoriSU 内核变体的官方配套应用。基于 [**KowSU**](https://github.com/KOWX712/KernelSU) 进行了深度定制与功能扩展，无缝兼容整个 MidoriSU 系列 — **KX、NX、OX、RX、XX** — 包括所有 SUSFS 与 Droidspaces 组合。

| 功能 | 描述 |
| :--- | :--- |
| **现代化 Bento 仪表盘** | Bento 风格响应式仪表盘，带弹性按压回弹动效；动态显示 KSU 驱动名称（原生驱动与动态 LKM 识别）、罗马数字 UAPI 版本、Hook 类型、SUSFS 版本、Droidspaces 版本、Re:Kernel(-X) 版本、内核构建时间与 OEM 解锁状态。 |
| **内置 SUSFS 管理** | 内核工具中原生集成的 SUSFS 控制面板，可取代 susfs4ksu 模块：支持 SUS Path、SUS Kstat、SUS Map 与 Open Redirect 规则；内核版本（`uname`）与启动参数（`/proc/cmdline` / `bootconfig`）伪装；AVC 日志伪装、SUS 挂载隐藏，以及对 `getpriority` / `ioprio` 探测隐藏指定应用的优先级 UID 过滤。规则由 `ksud` 在开机时应用（同样适用于延迟加载的 SUSFS LKM），并提供每次开机的应用报告、配置备份与恢复，以及从现有 susfs4ksu 模块一键导入。同时支持内置 SUSFS 与 susfs4ksu-lkm。 |
| **双主题与个性化** | 支持 Material 3 Expressive 与 Miuix 两套 UI 主题，并提供实时预览卡片；配备悬浮胶囊底部导航栏、再次点击当前标签页回到顶部、模块更新角标，内置切换器可在 **MidoriSU**、**KowSU** 与 **官方 KernelSU** 之间切换应用名称、图标与启动页主题。 |
| **OTA Payload 提取与 ARB 分析** | 通过 HTTP Range 请求从本地或在线 OTA zip / `payload.bin` 中直接提取 `boot.img`，无需下载数 GB 的完整包；内置防回滚（ARB）索引与 boot 内核版本分析。 |
| **刷写与安全检查** | 在应用内直接备份与刷写 `boot.img`，刷写 AnyKernel3 zip 包时可选择目标槽位（Slot A/B），并在刷入模块前自动进行安全检查，识别高危脚本以防止无限重启。 |
| **内核 Panic 与崩溃分析** | 专用崩溃分析工具：扫描 `/proc/last_kmsg`、`/sys/fs/pstore/console-ramoops*` 与 dmesg，精准定位 Kernel Panic、OOPS 调用栈、内存故障与异常重启。 |
| **授权列表备份与恢复** | 完整备份与恢复 Superuser 授权列表规则及应用配置（App Profile）。 |
| **模块导出为 ZIP** | 将任意已安装模块直接导出为标准的可刷写 ZIP 包。 |
| **内核模块 (LKM) 管理** | 查看已加载的内核模块，支持动态加载与卸载；提供开机模块黑名单，在内核加载前拦截指定模块。内核启动保护会容忍被拦截模块的加载失败以防止无限重启；拦截第一阶段模块所依赖的模块前会先请求确认。 |
| **内核诊断** | 在应用内查看、搜索、过滤与分享 `/proc/kallsyms` 符号表、实时 dmesg 内核日志与 `CONFIG_*` 内核编译选项，并提供底栏快捷切换组件。 |
| **快捷开关与功能集成** | 即时切换 SELinux 运行模式（Enforcing / Permissive）以及 KSU 驱动更新检查开关。 |

---

## 🔧 Hook 类型参考

| 类型 | 机制与特性 |
| :--- | :--- |
| `Kprobes` | 运行时通过 kprobe 断点动态插桩内核函数。内核占用极小，兼容性广泛。 |
| `Tracepoint` | 接入内核的静态系统调用 tracepoint 基础设施（`sys_enter`/`sys_exit`），无需修改内核源码。 |
| `Inline` | 编译时通过直接嵌入内核子系统源码的 `#ifdef CONFIG_KSU_SUSFS` 代码块注入。使用 `static_key` 分支实现运行时切换。不依赖 kprobes 或 LSM Hook。硬编码于 VFS（`exec`、`open`、`stat`、`readdir`、`statfs`）、SELinux（`avc`、`hooks`、`services`）、input、mounts 与 procfs。 |
| `De-inlined` | 通过内核源码打补丁而非内联 `#ifdef CONFIG_KSU_SUSFS` 代码块来应用 SUSFS Hook。SUSFS 逻辑与核心内核子系统分离更清晰。 |
| `Manual` | 静态内核源码打补丁。编译时将自定义 Hook 注入核心内核子系统。 |
| `Branch Link Hijacking` | 扫描内核 text 段并直接覆写调用处跳转指令（`b`/`bl`）重定向至 Hook，规避 trampoline 开销且符合 ARM64 Clang CFI 规范。通过 `CONFIG_KSU_HACK_ARM64_BRANCH_LINK` 启用。 |
| `Syscall Table Tampering` | 高性能系统调用表篡改方案，直接修改 `sys_call_table` 中用于 sucompat（如 `sys_execve` 等）与 `sys_reboot` 的函数指针，避免间接跳转（`blr`）开销且符合 Clang CFI 规范。通过 `CONFIG_KSU_TAMPER_SYSCALL_TABLE` 启用。 |

---

## 🧩 附加功能

| 功能 | 描述 |
| :--- | :--- |
| **内核版本** | 选择 `6.1`、`6.6`、`6.12` 或 `all` 来编译单个或全部内核版本。子版本、修订版本、编译器与 Rust 配置均从集中配置中自动解析。 |
| **源码镜像** | 支持在 Google 官方 AOSP 镜像与自建镜像之间进行选择，用于内核源码和工具链下载。 |
| **SUSFS** | SUSFS 内核补丁自动从上游同步，并为每个受支持的子版本生成，包括 `kernel_versions.json` 中固定的非 LTS 修订版本。通过单个 `susfs_commit` 输入控制各变体的 SUSFS 版本。SUSFS 直接在 MidoriSU 管理器中配置，发布中不再附带独立的 susfs4ksu 模块。 |
| **KSU 工具箱** | 自动从 nightly.link 获取最新的 [ksu_toolkit](https://github.com/backslashxx/ksu_toolkit) 模块，并在发布说明中附上下载链接。 |
| **Droidspaces** | 通过 [Droidspaces-OSS](https://github.com/ravindu644/Droidspaces-OSS) 提供容器支持 — SYSVIPC、IPC_NS、PID_NS、DEVTMPFS、NTSync 与网络。按变体通过 `use_droidspaces` 开关控制。 |
| **Re:Kernel(-X)** | 集成的 [Re:Kernel](https://github.com/Sakion-Team/Re-Kernel) 与 [Re:Kernel-X](https://github.com/myflavor/ReKernel-X) 模块直接编译进内核。提供 tombstone 冻结恢复、网络触发解冻与 binder 异步清理。通过 `use_rekernel` 开关控制。 |
| **VPNHide Next** | 通过树内 kpatch（`CONFIG_VPNHIDE=y`）集成 [VPNHide Next](https://github.com/soranerai/vpnhide_next_backend)，在内核层隐藏 VPN 网络接口、路由规则和套接字描述符，无需依赖动态 LKM。在发布说明中附上配套 `vpnhide-bridge.zip` 模块与管理器 APK（`vpnhide.apk`）的上游发布下载链接。通过 `use_vpnhide` 开关控制。 |
| **NoMount** | 集成的 [NoMount](https://github.com/maxsteeel/nomount) 直接编译进内核（`CONFIG_NOMOUNT=y`），这是一个 VFS 路径重定向框架，无需创建挂载、也不改动 `/proc/mounts` 即可注入和隐藏模块文件。在发布说明中附上配套 `NoMount-*.zip` 元模块的上游发布下载链接。通过 `use_nomount` 开关控制。 |
| **fgetpriority** | 集成的 [fgetpriority](https://github.com/aerath-stuff/fgetpriority) 直接编译进内核（`CONFIG_FGETPRIORITY=y`），对来自应用的 `getpriority` / `setpriority` / `ioprio_get` / `ioprio_set` 探测隐藏其他应用 UID。无需安装模块。通过 `use_fgetpriority` 开关控制。 |
| **Unicode 绕过修复** | 始终启用。修补内核 Unicode 规范化，以防止通过非标准 Unicode 编码进行文件系统绕过攻击。 |
| **CVE 修复** | 始终启用。检测内核源码中的 CVE-2026-43499（rtmutex）与 CVE-2026-64560（sighand / POSIX CPU timers），并在缺失时自动应用修复；各子版本的结果显示在发布说明中。 |
| **网络与文件系统** | 始终启用。TCP BBR、IPSET、增强型 NAT（IPv6 NAT 与 REDIRECT）以及 TMPFS xattr / POSIX ACL。 |
| **ADIOS I/O 调度器** | 可选集成 [ADIOS](https://github.com/firelzrd/adios) 作为内核的内置默认多队列 I/O 调度器。通过 `use_adios` 开关控制。 |
| **LZ4/ZSTD ZRAM 后端** | 可选将内核中的 LZ4 与 ZSTD 实现更新为官方 LZ4 1.10.0 与 Zstandard 1.5.7 版本，并为内核 6.12（仅在 6.12.23 上测试）启用 ZRAM 后端支持。通过 `use_lz4_zstd` 开关控制；6.1 与 6.6 构建保持不变。 |
| **Ccache** | 编译器缓存集成，配备 60 秒依赖安装等待保护，确保跨工作流运行的健壮加速增量重建。 |
| **伪装构建元数据** | 可为编译出的镜像自定义 `kernel name`、`build timestamp`、`user` 与 `host` 字符串。 |
| **额外功能与修复** | 为对应变体应用 [MidoriSU](https://github.com/midori01/KernelSU) 各分支顶部携带的额外功能与修复提交。通过 `use_extra_features` 开关控制。 |
| **KSU 调试** | 以 `CONFIG_KSU_DEBUG=y` 进行编译，并上传经 zstd 压缩的 `vmlinux` 构建产物以供 eBPF 调试。通过 `ksu_debug` 开关控制。 |
| **上游同步** | 构建前更新 `kernel_versions.json` 中的内核版本与源码，并从上游重新生成 SUSFS 补丁。通过 `sync_upstream` 开关控制。 |
| **发布类型** | `release` 发布正式版本并为每个内核版本保留最新 2 个发布，`pre-release` 发布预发布版本，`no-release` 仅上传构建产物。 |

---

## ✅ 已测试设备

以下设备已确认可使用本工作流构建的内核：

| 品牌 | 型号 |
| :--- | :--- |
| Google | Pixel 7/8/9/10/11 系列 (Tensor) |
| Xiaomi | Xiaomi 17 系列 (Snapdragon) |
| Xiaomi | REDMI K90 Pro Max (Snapdragon) |
| Xiaomi | POCO F8 Ultra (Snapdragon) |
| Tecno | Tecno Camon 40 Pro 4G (Helio) |
| Motorola | Moto Edge 70 Max (Snapdragon) |
| Lenovo | Legion Y70 2026 (Snapdragon) |
| Lenovo | Legion Y700 Infinite (Snapdragon) |

> [!NOTE]
> **兼容性说明：**
> - 以上设备均运行 Android 16+ 并搭载 GKI 内核（6.1/6.6/6.12）
> - SUSFS 与 Droidspaces 功能已在所有设备系列上完成测试
> - 建议原厂系统（Stock ROM）用户通过 MidoriSU 管理器或 Kernel Flasher 刷入内核

> [!TIP]
> **你的设备不在列表中？**  
> 如果你已在其他设备上成功测试内核，欢迎提交 Issue 或 Pull Request 将其加入列表！

---
