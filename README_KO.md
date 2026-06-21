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

*GKI 커널 빌드 및 배포를 자동화하는 GitHub Actions CI/CD 파이프라인*

</div>

---

## 🚀 개요

본 레포지토리는 단일 워크플로우 실행만으로 여러 커널 버전에 걸쳐 다양한 **KernelSU** 배리언트를 일괄 컴파일할 수 있는 설정 기반의 통합 빌드 오케스트레이션 시스템입니다. 각 배리언트는 독립된 작업(Job)으로 캡슐화되어 있어 유지보수성을 높이고 장애 발생 시 원인 격리를 용이하게 합니다. 또한, 향후 새로운 배리언트나 커널 버전을 추가할 때도 유연하게 대응할 수 있는 수평적 확장성을 제공합니다.

---

## ⚙️ 설정

커널 버전별 설정은 모두 [`.github/config/kernel_versions.json`](.github/config/kernel_versions.json) 파일에서 통합 관리됩니다. 워크플로우 실행 시 `kernel_version`만 지정하면 커널 버전, 서브 레벨, 컴파일러, Rust 사용 여부, AnyKernel3 브랜치 선택 등 빌드 매트릭스 전체가 자동으로 결정됩니다.

---

## 📦 빌드 배리언트

| 배리언트 | SUSFS | Droidspaces | 후크 방식 |
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
| [MidoriSU-XX](https://github.com/backslashxx/KernelSU) | ❌ | ❌ | `Manual` |
| [MidoriSU-XX-DS](https://github.com/backslashxx/KernelSU) | ❌ | ✅ | `Manual` |
| [MidoriSU-XX-SUSFS](https://github.com/backslashxx/KernelSU) | ✅ | ❌ | `De-inlined` |
| [MidoriSU-XX-SUSFS-DS](https://github.com/backslashxx/KernelSU) | ✅ | ✅ | `De-inlined` |

> \* **MidoriSU-XX 및 MidoriSU-RE 후크 방식:** 실행 시 `hook_mode` 옵션을 통해 변경할 수 있습니다.
> - `manual` — 두 배리언트의 기본 방식
> - `hookless` — MidoriSU-XX 6.12 전용
> - `tracepoint` — MidoriSU-RE 전용

> [!TIP]
> **매트릭스 빌드 동작 방식:** 매트릭스는 항상 배리언트당 정확히 **단 하나의 결과물**만 생성합니다. 활성화된 기능(Droidspaces / SUSFS)은 해당 결과물에 함께 적용됩니다. 5개 배리언트를 모두 선택하면 커널 버전당 **5개의 빌드**가 실행됩니다. `kernel_version`에서 `all`을 선택하면 6.1 / 6.6 / 6.12 버전이 병렬로 컴파일되어 총 **15개의 작업(Job)**이 동시에 실행됩니다.

---

## 🔧 후크 방식 레퍼런스

| 방식 | 메커니즘 및 특징 |
| :--- | :--- |
| `Kprobes` | 실행 시 kprobe 브레이크포인트를 사용하여 커널 함수를 동적으로 후킹합니다. 커널에 미치는 영향을 최소화하며 광범위한 호환성을 제공합니다. **MidoriSU-KO 및 MidoriSU-OG(비 SUSFS 환경)의 기본 방식입니다.** |
| `Tracepoint` | 커널의 정적인 syscall tracepoint 인프라(`sys_enter`/`sys_exit`)에 후킹하므로 커널 소스를 수정하지 않습니다. **MidoriSU-NX(비 SUSFS 환경)의 기본 방식입니다.** |
| `Inline` | `#ifdef CONFIG_KSU_SUSFS` 블록을 커널 서브시스템 소스에 직접 삽입하는 컴파일 타임 주입 방식입니다. `static_key` 분기를 통해 런타임에 활성/비활성 전환이 가능하며, kprobe나 LSM 후크에 의존하지 않습니다. VFS(`exec`, `open`, `stat`, `readdir`, `statfs`), SELinux(`avc`, `hooks`, `services`), input, mounts, procfs에 내장됩니다. **MidoriSU-KO-SUSFS, MidoriSU-NX-SUSFS, MidoriSU-RE-SUSFS, MidoriSU-OG-SUSFS에서 사용됩니다.** |
| `De-inlined` | `#ifdef CONFIG_KSU_SUSFS` 인라인 블록을 사용하는 대신 커널 소스에 패치를 적용하여 SUSFS 후크를 통합합니다. 이를 통해 SUSFS 로직이 코어 커널 서브시스템과 더욱 명확하게 분리됩니다. **MidoriSU-XX-SUSFS에서 사용됩니다.** |
| `Manual` | 커널 소스에 대한 정적 패치 방식입니다. 컴파일 시 자체 후크를 코어 커널 서브시스템에 직접 주입합니다. **MidoriSU-XX 및 MidoriSU-RE(비 SUSFS 환경)의 기본 방식입니다.** |
| `Hookless` | KernelSU 내장 메커니즘만을 사용합니다. `CONFIG_KSU_HACK_ARM64_BRANCH_LINK`를 활성화하며 커널 소스를 전혀 수정하지 않고 KernelSU 내부의 후크 인프라에 완전히 의존합니다. **MidoriSU-XX 전용 옵션입니다**(`hook_mode: hookless`). |

---

## 🧩 기타 기능

| 기능 | 설명 |
| :--- | :--- |
| **커널 버전** | `6.1`, `6.6`, `6.12` 중 단일 버전을 선택하거나 `all`을 통해 전체 버전을 선택할 수 있습니다. 서브 레벨, 리비전, 컴파일러, Rust 설정 등은 중앙 집중식 config에서 자동으로 적용됩니다. |
| **소스 미러** | 커널 소스 및 툴체인 다운로드 시 Google 공식 AOSP 미러 또는 자체 호스팅 미러 중에서 선택할 수 있습니다. |
| **eBPF Scene Hider** | 선택적으로 [Scene Port Hider by eBPF](https://github.com/Andrea-lyz/Scene-Port-Hider-by-eBPF)를 커널 결과물과 함께 컴파일하여 포함할 수 있습니다. 첫 번째 커널 빌드 완료와 동시에 실행되며 다른 매트릭스 작업과는 독립적으로 동작합니다. |
| **SUSFS 모듈** | SUSFS 활성화 시 최신 [susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module)을 자동으로 가져와 릴리스에 포함합니다. 모든 배리언트의 SUSFS 버전은 단일 `susfs_commit` 입력값을 통해 통합 관리됩니다. |
| **KSU 툴킷** | 최신 [ksu_toolkit](https://github.com/backslashxx/ksu_toolkit) 모듈을 nightly.link에서 자동으로 가져와 릴리스에 포함합니다. |
| **Droidspaces** | [Droidspaces-OSS](https://github.com/ravindu644/Droidspaces-OSS)를 활용한 컨테이너 지원 기능으로 SYSVIPC, IPC_NS, PID_NS, DEVTMPFS, NTSync, 네트워킹 기능을 제공합니다. `use_droidspaces` 옵션을 통해 배리언트마다 활성화할 수 있습니다. |
| **Re:Kernel** | [Re:Kernel](https://github.com/Sakion-Team/Re-Kernel) 모듈을 커널에 직접 내장합니다. 툼스톤(tombstone) 기반 프리즈 복구 및 네트워크 트리거를 통한 선택적 해제가 가능합니다. `use_rekernel` 옵션으로 제어합니다. |
| **유니코드 바이패스 수정** | 비표준 유니코드 인코딩을 이용한 파일시스템 우회 공격을 방지하기 위해 커널의 유니코드 정규화 로직을 패치합니다. `unicode_bypass_fix` 옵션으로 제어합니다. |
| **Ccache** | 의존성 설치 완료 후 60초 대기 시간을 두어 컴파일러 캐시를 안전하게 통합합니다. 여러 워크플로우 실행에 걸쳐 안정적이고 강력한 증분 빌드 속도 향상을 제공합니다. |
| **빌드 메타데이터 커스터마이징** | 컴파일된 이미지에 포함되는 `커널 이름`, `빌드 타임스탬프`, `사용자 이름`, `호스트 이름` 문자열을 자유롭게 설정할 수 있습니다. |
