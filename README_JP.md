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

*GKIカーネルのビルドと配布を自動化する GitHub Actions CI/CD パイプライン*

</div>

---

## 🚀 概要

本リポジトリは、単一のワークフローから複数のカーネルバージョン向けに、多様な **KernelSU** バリアントを一括コンパイルできる設定駆動型の統合ビルドシステムです。各バリアントは独立したジョブとしてカプセル化されており、保守性を高め、障害の切り分けを容易にするとともに、将来的なバリアントやカーネルバージョンの追加にもシームレスに対応できる柔軟なスケーリングを実現します。

---

## ⚙️ 設定

カーネルバージョン固有の設定は、すべて [`.github/config/kernel_versions.json`](.github/config/kernel_versions.json) に集約されています。ワークフロー実行時に `kernel_version` を指定するだけで、カーネルバージョン、サブレベル、コンパイラ、Rust の要否、AnyKernel3 のブランチ選択など、ビルドマトリクス全体が自動的に決定されます。

---

## 📦 ビルドバリアント

| バリアント | SUSFS | Droidspaces | フック方式 |
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

> \* **MidoriSU-XX および MidoriSU-RE のフック方式:** 実行時に `hook_mode` で切り替え可能です。
> - `hookless` — MidoriSU-XX のデフォルト
> - `manual` — MidoriSU-RE のデフォルト
> - `tracepoint` — MidoriSU-RE のみ対応

> [!TIP]
> **マトリクスビルドの仕組み:** マトリクスは常にバリアントごとに **1 つの成果物** のみを生成します。有効化した機能（Droidspaces / SUSFS）は、その単一の成果物に適用されます。5 つのバリアントすべてを選択した場合、カーネルバージョンあたり **5 つのビルド** が実行されます。`kernel_version` で `all` を選択すると、6.1 / 6.6 / 6.12 が並列コンパイルされ、合計 **15 のジョブ** が同時に実行されます。

---

## 🔧 フック方式リファレンス

| 方式 | メカニズムと特徴 |
| :--- | :--- |
| `Kprobes` | 実行時に kprobe ブレークポイントを用いてカーネル関数を動的にフックします。カーネルへの影響が最小限で、幅広い互換性を持ちます。**MidoriSU-KO および MidoriSU-OG（非 SUSFS）のデフォルト。** |
| `Tracepoint` | カーネルの静的な syscall tracepoint 基盤（`sys_enter`/`sys_exit`）にフックするため、カーネルソースの改変を行いません。**MidoriSU-NX（非 SUSFS）のデフォルト。** |
| `Inline` | `#ifdef CONFIG_KSU_SUSFS` ブロックをカーネルサブシステムのソースに直接埋め込む、コンパイル時注入方式です。`static_key` 分岐により実行時の切り替えが可能です。kprobe や LSM フックには依存しません。VFS（`exec`、`open`、`stat`、`readdir`、`statfs`）、SELinux（`avc`、`hooks`、`services`）、input、mounts、procfs に組み込まれます。**MidoriSU-KO-SUSFS、MidoriSU-NX-SUSFS、MidoriSU-RE-SUSFS、MidoriSU-OG-SUSFS で使用。** |
| `De-inlined` | `#ifdef CONFIG_KSU_SUSFS` によるインラインブロックを使用せず、カーネルソースへのパッチ適用により SUSFS フックを組み込みます。SUSFS ロジックがコアカーネルサブシステムからより明確に分離されます。**MidoriSU-XX-SUSFS で使用。** |
| `Manual` | カーネルソースへの静的なパッチ適用方式です。コンパイル時に独自のフックをコアカーネルサブシステムへ注入します。**MidoriSU-RE（非 SUSFS）のデフォルト。** |
| `Hookless` | KernelSU 組み込みの機構のみを使用します。`CONFIG_KSU_TAMPER_SYSCALL_TABLE` を有効化し、カーネルソースの改変は一切行いません。KernelSU 内部のフック基盤に完全に依存します。**MidoriSU-XX（非 SUSFS）のデフォルト。** |

---

## 🧩 その他の機能

| 機能 | 説明 |
| :--- | :--- |
| **カーネルバージョン** | `6.1`、`6.6`、`6.12`、または `all` から、単一または全バージョンを選択できます。サブレベル、リビジョン、コンパイラ、Rust の各設定は、一元化された config から自動解決されます。 |
| **ソースミラー** | カーネルソースおよびツールチェーンの取得先として、Google 公式の AOSP ミラー、またはセルフホストミラーを選択可能です。 |
| **eBPF Scene Hider** | オプションで [Scene Port Hider by eBPF](https://github.com/Andrea-lyz/Scene-Port-Hider-by-eBPF) をカーネル成果物と併せてコンパイルし、同梱します。最初のカーネルビルド完了と同時に起動し、他のマトリクスジョブとは独立して動作します。 |
| **SUSFS モジュール** | SUSFS 有効時に、最新の [susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module) を自動取得してリリースに同梱します。全バリアントの SUSFS バージョンは単一の `susfs_commit` 入力で一元管理されます。 |
| **KSU ツールキット** | 最新の [ksu_toolkit](https://github.com/backslashxx/ksu_toolkit) モジュールを nightly.link から自動取得し、リリースに同梱します。 |
| **Droidspaces** | [Droidspaces-OSS](https://github.com/ravindu644/Droidspaces-OSS) を利用したコンテナ対応。SYSVIPC、IPC_NS、PID_NS、DEVTMPFS、NTSync、ネットワーク機能を提供します。`use_droidspaces` トグルでバリアントごとに有効化できます。 |
| **Re:Kernel** | [Re:Kernel](https://github.com/Sakion-Team/Re-Kernel) モジュールをカーネルに直接組み込みます。tombstone によるフリーズ復旧と、オプションのネットワークトリガーによる解除が可能です。`use_rekernel` スイッチで制御します。 |
| **Unicode バイパス修正** | 非標準の Unicode エンコーディングを用いたファイルシステムバイパス攻撃を防ぐため、カーネルの Unicode 正規化処理にパッチを適用します。`unicode_bypass_fix` スイッチで制御します。 |
| **Ccache** | 依存関係のインストール完了後に 60 秒間の待機プロセスを設けることでコンパイラキャッシュを安全に統合。ワークフロー実行をまたいだ、安定かつ堅牢な増分ビルドの高速化を実現します。 |
| **ビルドメタデータのカスタマイズ** | コンパイル済みイメージに埋め込む `カーネル名`、`ビルド日時`、`ユーザー名`、`ホスト名` を任意に設定できます。 |
