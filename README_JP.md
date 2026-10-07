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

> [!NOTE]
> **カーネル 6.12.23 削除について：** コミット [`650419b`](https://github.com/midori01/gki_ksu_workflow/commit/650419be4e0f4d976aa5f57bbfc9982d8bf130ed) により、[非推奨（deprecated）](https://android.googlesource.com/kernel/common/+/refs/heads/deprecated/android16-6.12-2025-06)となった `android16-6.12-2025-06` ブランチがデフォルトのビルドマトリクスから削除されました。このバージョンが引き続き必要な場合は、該当コミットを revert（`git revert 650419b`）してください。また、その他のカーネルバージョンが必要な場合は、[`.github/config/kernel_versions.json`](.github/config/kernel_versions.json) を直接編集してカスタマイズできます。

---

## 📦 ビルドバリアント

| バリアント | SUSFS | Droidspaces | フック方式 |
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

> \* **MidoriSU-RX および MidoriSU-XX のフック方式:** `midorisu_rx_hook_mode` および `midorisu_xx_hook_mode` で個別に設定可能です。
> - `midorisu_rx_hook_mode` — `manual`（デフォルト）/ `tracepoint`
> - `midorisu_xx_hook_mode`:
>   - `branch link hijacking` — MidoriSU-XX のデフォルト；`CONFIG_KSU_HACK_ARM64_BRANCH_LINK` を使用してカーネル text 内の分岐命令（`b`/`bl`）を直接フックへリダイレクトし、トランポリンオーバーヘッドを回避しつつ ARM64 CFI に適合
>   - `syscall table tampering` — `CONFIG_KSU_TAMPER_SYSCALL_TABLE` を使用して `sys_call_table` の関数ポインタを直接改ざんし、間接分岐（`blr`）オーバーヘッドを回避しつつ Clang CFI に適合
>   - `manual` — `scope-min-manual-hooks-v2.3.patch` による手動フック

> [!TIP]
> **マトリクスビルドの仕組み:** マトリクスは常にバリアントごとに **1 つの成果物** のみを生成します。有効化した機能（Droidspaces / SUSFS）は、その単一の成果物に適用されます。5 つのバリアントすべてを選択した場合、カーネルバージョンの **各サブレベルごとに 5 つのビルド** が実行されます。`kernel_version` で `all` を選択すると、6.1 / 6.6 / 6.12 の全サブレベルが並列コンパイルされ、デフォルト設定では合計 **50 のジョブ** が同時に実行されます。

---

## 📱 MidoriSU マネージャー

[**MidoriSU**](https://github.com/midori01/KernelSU) は、MidoriSU 全カーネルバリアント対応の公式コンパニオンアプリです。[**KowSU**](https://github.com/KOWX712/KernelSU) をベースに大幅な独自拡張を施しており、**KX、NX、OX、RX、XX** の全バリアント、および SUSFS / Droidspaces の全組み合わせにシームレスに対応します。

| 機能 | 説明 |
| :--- | :--- |
| **モダンな Bento ダッシュボード** | 弾むようなプレスフィードバックを備えた弁当スタイルのレスポンシブダッシュボード。KSU ドライバ名（ネイティブ名および LKM 動的検出）、ローマ数字 UAPI バージョン、フックタイプ、SUSFS バージョン、Droidspaces バージョン、Re:Kernel(-X) バージョン、カーネルビルド時刻、OEM ロック解除状態を一目で確認可能。 |
| **デュアルテーマと外観カスタマイズ** | Material 3 Expressive と Miuix の両 UI スタイルおよびリアルタイムプレビューに完全対応。Material 向けフローティングピル型ボトムナビゲーション、タブ再タップによるトップへのスムーズスクロール、モジュール更新バッジ、さらに **MidoriSU**、**KowSU**、**公式 KernelSU** のアプリ名・アイコン・起動画面テーマの即時切り替えを搭載。 |
| **OTA Payload 抽出と ARB 解析** | ローカルまたはオンラインの OTA ZIP / `payload.bin` から `boot.img` を秒速抽出。HTTP Range Request により大容量パッケージ全体をダウンロードすることなく直接抽出可能。アンチロールバック（ARB）インデックスおよびブートカーネルバージョンの解析機能を内蔵。 |
| **フラッシュ・安全事前検査** | アプリ内で `boot.img` のバックアップと直接フラッシュが可能。AnyKernel3 ZIP の直接フラッシュおよび対象スロット選択（Slot A/B）に対応。モジュールフラッシュ前の自動静的セキュリティ検査により、危険なスクリプトを検知しブートループを未然に防止。 |
| **カーネル Panic・クラッシュログ解析** | 専用のクラッシュ解析ツール：`/proc/last_kmsg`、`/sys/fs/pstore/console-ramoops*`、dmesg をスキャンし、Kernel Panic、OOPS コールトレース、メモリエラー、予期せぬ再起動の根本原因を特定。 |
| **許可リストのバックアップと復元** | Superuser 許可リストとアプリプロファイル設定の完全なバックアップ・復元に対応。 |
| **モジュールを ZIP としてエクスポート** | インストール済みモジュールを標準のフラッシュ可能な ZIP アーカイブとして直接書き出し可能。 |
| **カーネルモジュール (LKM) 管理** | ロードされているカーネルモジュールの確認、動的ロードおよびアンロードをサポート。 |
| **カーネル診断ツール** | `/proc/kallsyms` シンボルテーブル、リアルタイム dmesg ログ、`CONFIG_*` カーネルビルド設定の閲覧・検索・共有が可能。ボトムバーのクイックスイッチャーウィジェットに対応。 |
| **クイック切替と統合機能** | SELinux 動作モード（Enforcing / Permissive）の即時切替、SUSFS WebUI へのショートカット、KSU ドライバ更新確認トグルを搭載。 |

---

## 🔧 フック方式リファレンス

| 方式 | メカニズムと特徴 |
| :--- | :--- |
| `Kprobes` | 実行時に kprobe ブレークポイントを用いてカーネル関数を動的にフックします。カーネルへの影響が最小限で、幅広い互換性を持ちます。 |
| `Tracepoint` | カーネルの静的な syscall tracepoint 基盤（`sys_enter`/`sys_exit`）にフックするため、カーネルソースの改変を行いません。 |
| `Inline` | `#ifdef CONFIG_KSU_SUSFS` ブロックをカーネルサブシステムのソースに直接埋め込む、コンパイル時注入方式です。`static_key` 分岐により実行時の切り替えが可能です。kprobe や LSM フックには依存しません。VFS（`exec`、`open`、`stat`、`readdir`、`statfs`）、SELinux（`avc`、`hooks`、`services`）、input、mounts、procfs に組み込まれます。 |
| `De-inlined` | `#ifdef CONFIG_KSU_SUSFS` によるインラインブロックを使用せず、カーネルソースへのパッチ適用により SUSFS フックを組み込みます。SUSFS ロジックがコアカーネルサブシステムからより明確に分離されます。 |
| `Manual` | カーネルソースへの静的なパッチ適用方式です。コンパイル時に独自のフックをコアカーネルサブシステムへ注入します。 |
| `Branch Link Hijacking` | カーネル text セクションをスキャンし、呼び出し元の分岐命令（`b`/`bl`）を直接フックへ書き換えることで、トランポリンオーバーヘッドを回避し Clang CFI に適合します。`CONFIG_KSU_HACK_ARM64_BRANCH_LINK` で有効化。 |
| `Syscall Table Tampering` | `sys_call_table` 内の関数ポインタ（`sys_reboot`、`sys_execve` 等）を直接差し替える高性能フック方式。間接分岐（`blr`）オーバーヘッドを回避し、Clang CFI に適合します。`CONFIG_KSU_TAMPER_SYSCALL_TABLE` で有効化。 |

---

## 🧩 その他の機能

| 機能 | 説明 |
| :--- | :--- |
| **カーネルバージョン** | `6.1`、`6.6`、`6.12`、または `all` から、単一または全バージョンを選択できます。サブレベル、リビジョン、コンパイラ、Rust の各設定は、一元化された config から自動解決されます。 |
| **ソースミラー** | カーネルソースおよびツールチェーンの取得先として、Google 公式の AOSP ミラー、またはセルフホストミラーを選択可能です。 |
| **SUSFS モジュール** | SUSFS 有効時に、最新の [susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module) を自動取得してリリースに同梱します。全バリアントの SUSFS バージョンは単一の `susfs_commit` 入力で一元管理されます。 |
| **KSU ツールキット** | 最新の [ksu_toolkit](https://github.com/backslashxx/ksu_toolkit) モジュールを nightly.link から自動取得し、リリースに同梱します。 |
| **Droidspaces** | [Droidspaces-OSS](https://github.com/ravindu644/Droidspaces-OSS) を利用したコンテナ対応。SYSVIPC、IPC_NS、PID_NS、DEVTMPFS、NTSync、ネットワーク機能を提供します。`use_droidspaces` トグルでバリアントごとに有効化できます。 |
| **Re:Kernel(-X)** | [Re:Kernel](https://github.com/Sakion-Team/Re-Kernel) および [Re:Kernel-X](https://github.com/myflavor/ReKernel-X) モジュールをカーネルに直接組み込みます。tombstone によるフリーズ復旧、ネットワークトリガーによる解除、binder 非同期クリーンアップを提供します。`use_rekernel` スイッチで制御します。 |
| **VPNHide Next** | In-tree kpatch（`CONFIG_VPNHIDE=y`）を介して [VPNHide Next](https://github.com/soranerai/vpnhide_next_backend) を統合し、動的 LKM に依存することなくカーネルレベルで VPN ネットワークインターフェース、ルーティングルール、ソケット記述子を隠蔽します。付属の `vpnhide-bridge.zip` モジュールおよびマネージャー APK（`vpnhide.apk`）を自動取得してリリースに同梱します。`use_vpnhide` スイッチで制御します。 |
| **Unicode バイパス修正** | 常に有効です。非標準の Unicode エンコーディングを用いたファイルシステムバイパス攻撃を防ぐため、カーネルの Unicode 正規化処理にパッチを適用します。 |
| **ADIOS I/O スケジューラ** | [ADIOS](https://github.com/firelzrd/adios) をカーネル内蔵のデフォルト・マルチキュー I/O スケジューラとして統合します。`use_adios` スイッチで制御します。 |
| **LZ4/ZSTD ZRAM バックエンド** | オプションでカーネルの LZ4 と ZSTD 実装を公式 LZ4 1.10.0 および Zstandard 1.5.7 に更新し、kernel 6.12 (6.12.23でのみテスト済み) の ZRAM バックエンドを有効化します。`use_lz4_zstd` トグルで制御し、6.1 および 6.6 ビルドは変更されません。 |
| **Ccache** | 依存関係のインストール完了後に 60 秒間の待機プロセスを設けることでコンパイラキャッシュを安全に統合。ワークフロー実行をまたいだ、安定かつ堅牢な増分ビルドの高速化を実現します。 |
| **ビルドメタデータのカスタマイズ** | コンパイル済みイメージに埋め込む `カーネル名`、`ビルド日時`、`ユーザー名`、`ホスト名` を任意に設定できます。 |

---

## ✅ 動作確認済み端末

本ワークフローでビルドしたカーネルにて、下記端末での動作を確認済みです。

| ブランド | モデル |
| :--- | :--- |
| Google | Pixel 7/8/9/10 シリーズ (Tensor) |
| Xiaomi | Xiaomi 17 シリーズ (Snapdragon) |
| Xiaomi | REDMI K90 Pro Max (Snapdragon) |
| Tecno | Tecno Camon 40 Pro 4G (Helio) |

> [!NOTE]
> **互換性について**
> - 記載の端末はいずれも Android 16 以降・GKI カーネル（6.1/6.6/6.12）環境で動作しています
> - SUSFS / Droidspaces は全シリーズで検証済みです
> - 純正 ROM をご利用の場合は、MidoriSU マネージャーもしくは Kernel Flasher からの書き込みを推奨します

> [!TIP]
> **お使いの端末がリストにない場合**  
> カーネルの動作確認ができましたら、Issue または Pull Request でお知らせください。リストに追記します。

---
