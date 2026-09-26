#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# ==============================================================================
# Script:      sync_susfs_patches.py
# Description: Automated GitHub Actions sync tool for SUSFS inline-hook patches
#              with zero-offset verification and substantive code diff detection.
# Location:    .github/scripts/sync_susfs_patches.py
# Author:      midori01 <lv@lvlv.lv>, Gemini
# Version:     3.1.0
# Date:        2026-09-26
# ==============================================================================

import argparse
import email.utils
import hashlib
import os
import re
import subprocess
import sys
import tempfile
import time
import urllib.request

KERNEL_CONFIGS = {
    "6.1": {
        "kmi": "android14-6.1",
        "patch_rel_dir": "android14-6.1",
        "targets": {
            "single": {
                "branch": "android14-6.1-lts",
                "filename": "50_add_susfs_in_gki-android14-6.1.patch",
                "subject": "[PATCH] SUSFS inline hooks for gki-android14-6.1-lts",
                "desc": "Android 14 (6.1 LTS)",
            }
        },
    },
    "6.6": {
        "kmi": "android15-6.6",
        "patch_rel_dir": "android15-6.6",
        "targets": {
            "single": {
                "branch": "android15-6.6-lts",
                "filename": "50_add_susfs_in_gki-android15-6.6.patch",
                "subject": "[PATCH] SUSFS inline hooks for gki-android15-6.6-lts",
                "desc": "Android 15 (6.6 LTS)",
            }
        },
    },
    "6.12": {
        "kmi": "android16-6.12",
        "patch_rel_dir": "android16-6.12",
        "targets": {},  # Purely dynamic: discovered directly from kernel git refs at runtime
    },
}

DEFAULT_KERNEL_TREE_CANDIDATES = [
    "/tmp/kernel_tree",
    os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "common_android_kernel_tree")),
    os.path.expanduser("~/common_android_kernel_tree"),
]

DEFAULT_SUSFS_REPO_CANDIDATES = [
    "/tmp/susfs4ksu",
    os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "susfs4ksu")),
    os.path.expanduser("~/susfs4ksu"),
]

DEFAULT_PATCHES_DIR_CANDIDATES = [
    os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "patches")),
    os.path.expanduser("~/gki_ksu_workflow/.github/patches"),
]


def log(msg, level="INFO"):
    symbols = {
        "INFO": "\033[0;32m[+]\033[0m",
        "WARN": "\033[1;33m[!]\033[0m",
        "ERR":  "\033[0;31m[-]\033[0m",
        "STEP": "\033[0;36m[»]\033[0m",
        "PASS": "\033[1;32m[✓]\033[0m",
    }
    prefix = symbols.get(level, "[*]")
    print(f"{prefix} {msg}", flush=True)

def find_kernel_tree(specified_path=None):
    if specified_path:
        if os.path.isdir(os.path.join(specified_path, ".git")):
            return os.path.abspath(specified_path)
        raise FileNotFoundError(f"Specified kernel tree not found or not a git repo: {specified_path}")

    for candidate in DEFAULT_KERNEL_TREE_CANDIDATES:
        if os.path.isdir(os.path.join(candidate, ".git")):
            return os.path.abspath(candidate)

    raise FileNotFoundError("Could not locate kernel tree. Please specify via --tree.")

def find_susfs_repo(specified_path=None):
    if specified_path:
        if os.path.isdir(os.path.join(specified_path, ".git")):
            return os.path.abspath(specified_path)
        return None
    for candidate in DEFAULT_SUSFS_REPO_CANDIDATES:
        if os.path.isdir(os.path.join(candidate, ".git")):
            return os.path.abspath(candidate)
    return None

def find_patches_dir(specified_path=None):
    if specified_path:
        if os.path.isdir(specified_path):
            return os.path.abspath(specified_path)
        raise FileNotFoundError(f"Specified patches dir not found: {specified_path}")
    for candidate in DEFAULT_PATCHES_DIR_CANDIDATES:
        if os.path.isdir(candidate):
            return os.path.abspath(candidate)
    fallback = DEFAULT_PATCHES_DIR_CANDIDATES[0]
    os.makedirs(fallback, exist_ok=True)
    return fallback

def susfs_macro_guard(macro_name):
    """Generates regex pattern matching both #ifdef and #if defined(...) variants with flexible spacing."""
    esc = re.escape(macro_name)
    return rf"#\s*(?:ifdef\s+{esc}\b|if\s+defined\s*\(\s*{esc}\s*\))"

def run_git(tree, cmd, check=True, capture=True, input_data=None):
    if not isinstance(cmd, (list, tuple)):
        raise TypeError(f"cmd must be list or tuple, got {type(cmd).__name__}")
    cmd_args = list(cmd)
    full_cmd = ["git", "-C", os.path.abspath(tree), "-c", "merge.conflictstyle=merge"] + cmd_args
    res = subprocess.run(
        full_cmd,
        input=input_data,
        text=True,
        capture_output=capture
    )
    if check and res.returncode != 0:
        err = res.stderr.strip() or res.stdout.strip()
        cmd_str = " ".join(full_cmd)
        raise RuntimeError(f"Git command failed ({cmd_str}): {err}")
    return res

def reset_tree(tree, branch):
    """Resets and checks out the specified branch."""
    run_git(tree, ["reset", "--hard", "HEAD"], check=False)
    run_git(tree, ["clean", "-fd"], check=False)
    run_git(tree, ["checkout", "-q", branch], check=True)
    run_git(tree, ["reset", "--hard", "HEAD"], check=True)
    run_git(tree, ["clean", "-fd"], check=True)

def prepare_branch(tree, branch, pull_upstream=False):
    run_git(tree, ["reset", "--hard", "HEAD"], check=False)
    run_git(tree, ["clean", "-fd"], check=False)
    if pull_upstream:
        log(f"Fetching latest upstream for branch '{branch}' from origin...", level="STEP")
        res = run_git(tree, ["fetch", "origin", branch], check=False)
        if res.returncode == 0:
            run_git(tree, ["checkout", "-q", "-B", branch, "FETCH_HEAD"], check=True)
            log(f"Branch '{branch}' synchronized to latest upstream FETCH_HEAD.", level="INFO")
        else:
            err = res.stderr.strip() or res.stdout.strip()
            raise RuntimeError(f"Network error: Failed to fetch upstream branch '{branch}': {err}")
    else:
        # Check if local branch exists, else track remote origin branch
        chk = run_git(tree, ["rev-parse", "--verify", f"refs/heads/{branch}"], check=False)
        if chk.returncode == 0:
            run_git(tree, ["checkout", "-q", branch], check=True)
        else:
            run_git(tree, ["checkout", "-q", "-b", branch, f"origin/{branch}"], check=True)

    run_git(tree, ["reset", "--hard", "HEAD"], check=True)
    run_git(tree, ["clean", "-fd"], check=True)

def discover_targets(tree, kmi, kv, patches_dir, static_targets=None):
    """
    Dynamically discovers upstream GKI ASB & LTS branches directly from the kernel tree,
    extracts the exact SUBLEVEL from Makefile, and builds the target matrix automatically.
    """
    discovered = {}
    if static_targets:
        discovered.update(static_targets)

    if kv != "6.12":
        return discovered

    refs_to_check = [
        f"refs/remotes/origin/{kmi}-*",
        f"refs/remotes/origin/deprecated/{kmi}-*",
    ]
    ref_args = ["for-each-ref", "--format=%(refname)"] + refs_to_check
    res = run_git(tree, ref_args, check=False)
    if res.returncode != 0:
        err = res.stderr.strip() or res.stdout.strip()
        raise RuntimeError(f"Git command failed during ref enumeration: {err}")
    ref_lines = [r.strip() for r in res.stdout.splitlines() if r.strip()]

    if not ref_lines:
        local_ref_args = [
            "for-each-ref",
            "--format=%(refname)",
            f"refs/heads/{kmi}-*",
            f"refs/heads/deprecated/{kmi}-*",
        ]
        res_local = run_git(tree, local_ref_args, check=False)
        if res_local.returncode != 0:
            err = res_local.stderr.strip() or res_local.stdout.strip()
            raise RuntimeError(f"Git command failed during local ref enumeration: {err}")
        ref_lines = [r.strip() for r in res_local.stdout.splitlines() if r.strip()]

    for ref in ref_lines:
        if ref.startswith("refs/remotes/origin/"):
            branch = ref[len("refs/remotes/origin/"):]
        elif ref.startswith("refs/heads/"):
            branch = ref[len("refs/heads/"):]
        else:
            branch = ref

        suffix = branch.split(f"{kmi}-")[-1]
        is_asb = bool(re.match(r"^\d{4}-\d{2}$", suffix))
        is_lts = (suffix == "lts")
        if not (is_asb or is_lts):
            continue

        desc = "6.12 LTS" if is_lts else suffix
        mf_res = run_git(tree, ["show", f"{ref}:Makefile"], check=False)
        if mf_res.returncode != 0:
            log(f"Branch '{branch}' ({desc}) is currently an empty branch stub (no Makefile yet), safely skipping.", level="INFO")
            continue
        mf = mf_res.stdout
        m_sub = re.search(r"^SUBLEVEL\s*=\s*(\d+)", mf, re.M)
        if not m_sub:
            continue
        sublevel = m_sub.group(1)

        chk = run_git(tree, ["cat-file", "-e", f"{ref}:kernel/sys.c"], check=False)
        if chk.returncode != 0:
            log(f"Branch '{branch}' ({desc}) has no kernel code yet (unpopulated stub), safely skipping.", level="INFO")
            continue

        is_deprecated = ("deprecated" in branch) or ("deprecated" in ref)
        desc = "6.12 LTS" if is_lts else suffix
        if is_deprecated:
            desc += " (deprecated)"
        filename = f"50_add_susfs_in_gki-{kmi}.{sublevel}.patch"
        subject = f"[PATCH] SUSFS inline hooks for gki-{branch.split('/')[-1]}"

        if sublevel in discovered:
            if is_deprecated and not discovered[sublevel]["is_deprecated"]:
                discovered[sublevel] = {
                    "branch": branch,
                    "filename": filename,
                    "subject": subject,
                    "desc": desc,
                    "is_deprecated": True,
                    "is_lts": is_lts,
                }
            continue

        discovered[sublevel] = {
            "branch": branch,
            "filename": filename,
            "subject": subject,
            "desc": desc,
            "is_deprecated": is_deprecated,
            "is_lts": is_lts,
        }

    sorted_discovered = dict(sorted(discovered.items(), key=lambda item: int(item[0]) if item[0].isdigit() else 9999))
    return sorted_discovered

def check_patch_cleanliness(tree, branch, patch_content):
    reset_tree(tree, branch)
    warns = []

    # Layer 1: GNU patch dry-run (zero offset, zero fuzz, no rejects)
    res_patch = subprocess.run(
        ["patch", "-p1", "-d", os.path.abspath(tree), "--dry-run"],
        input=patch_content,
        text=True,
        capture_output=True
    )
    out = res_patch.stdout + "\n" + res_patch.stderr
    for l in out.splitlines():
        if any(w in l.lower() for w in ["offset", "fuzz", "failed", "reject"]):
            warns.append(l.strip())
    if res_patch.returncode != 0:
        warns.append(f"patch command failed with exit code {res_patch.returncode}")

    # Layer 2: Git apply check
    res_git = run_git(tree, ["apply", "--check"], check=False, input_data=patch_content)
    if res_git.returncode != 0:
        git_err = (res_git.stderr.strip() or res_git.stdout.strip()).splitlines()
        warns.append(f"git apply --check failed: {git_err[0] if git_err else 'unknown error'}")

    # Layer 3: Real apply test
    if not warns:
        res_apply = run_git(tree, ["apply"], check=False, input_data=patch_content)
        if res_apply.returncode != 0:
            err = res_apply.stderr.strip() or res_apply.stdout.strip()
            warns.append(f"Real git apply failed unexpectedly: {err}")
        else:
            status = run_git(tree, ["status", "--porcelain"], check=False).stdout.strip()
            if not status:
                warns.append("Real git apply succeeded but produced zero working tree changes")

    reset_tree(tree, branch)
    return len(warns) == 0, warns

def extract_susfs_preprocessor_blocks(text):
    guard_pattern = susfs_macro_guard("CONFIG_KSU_SUSFS")
    blocks = []
    lines = text.splitlines(keepends=True)
    cleaned_lines = []
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        if re.match(rf"^{guard_pattern}", stripped):
            start = i
            depth = 1
            i += 1
            while i < len(lines) and depth > 0:
                l_strip = lines[i].strip()
                if re.match(r"^#\s*(if|ifdef|ifndef)\b", l_strip):
                    depth += 1
                elif re.match(r"^#\s*endif\b", l_strip):
                    depth -= 1
                i += 1
            if depth == 0:
                block = "".join(lines[start:i])
                blocks.append(block)
            else:
                cleaned_lines.extend(lines[start:i])
        else:
            cleaned_lines.append(line)
            i += 1
    return blocks, "".join(cleaned_lines)

def resolve_header_conflict(block):
    m = re.match(r"<<<<<<< ours\n([\s\S]*?)(?:\|\|\|\|\|\|\| [^\n]*\n[\s\S]*?)?=======\n([\s\S]*?)>>>>>>> theirs\n?", block)
    if not m:
        return block
    ours, theirs = m.group(1), m.group(2)
    combined = ours + theirs

    susfs_blocks, cleaned_combined = extract_susfs_preprocessor_blocks(combined)

    non_header_lines = [l for l in cleaned_combined.splitlines() if l.strip() and not (
        l.strip().startswith("#include") or 
        l.strip().startswith("//") or 
        l.strip().startswith("/*") or 
        l.strip().startswith("*") or 
        l.strip().startswith("#ifdef") or 
        l.strip().startswith("#endif")
    )]
    if non_header_lines:
        return block

    includes = []
    for line in cleaned_combined.splitlines(keepends=True):
        if line.strip().startswith("#include") and line not in includes:
            includes.append(line)

    unique_susfs = []
    for b in susfs_blocks:
        b_clean = b if b.endswith("\n") else b + "\n"
        if b_clean not in unique_susfs:
            unique_susfs.append(b_clean)

    return "".join(includes) + "".join(unique_susfs)

def resolve_code_conflict(block, fn):
    if os.path.basename(fn) != "task_mmu.c":
        return block

    m = re.match(r"<<<<<<< ours\n([\s\S]*?)(?:\|\|\|\|\|\|\| [^\n]*\n[\s\S]*?)?=======\n([\s\S]*?)>>>>>>> theirs\n?", block)
    if not m:
        return block
    ours, theirs = m.group(1), m.group(2)

    guard_sus_map = susfs_macro_guard("CONFIG_KSU_SUSFS_SUS_MAP")

    if ("vma_next" in theirs and any(c in theirs for c in ["Case 4", "Case 3", "Case 1"])) and "vma_next" not in ours:
        return ours

    m_bypass = re.search(
        rf"({guard_sus_map}[\s\S]*?SUSFS_IS_INODE_SUS_MAP[\s\S]*?goto\s+(\w+);[\s\S]*?#\s*endif[^\n]*\n)",
        theirs
    )
    if m_bypass:
        hook_start = m_bypass.group(1)
        label = m_bypass.group(2)
        m_label = re.search(
            rf"({guard_sus_map}\s*\n\s*{re.escape(label)}:[\s\S]*?#\s*endif[^\n]*\n)",
            theirs
        )
        hook_end = m_label.group(1) if m_label else f"#ifdef CONFIG_KSU_SUSFS_SUS_MAP\n{label}:\n#endif\n"

        m_range = re.search(r"(\n\s*if\s*\(vma->vm_start\s*<[\s\S]*?\n\s*}\s*else\s*\{[\s\S]*?\n\s*}\n)", ours)
        m_direct = re.search(r"(\n\s*\bsmap_gather_stats\s*\([^;]+;\n)", ours)

        if m_range:
            start_idx = m_range.start(1)
            end_idx = m_range.end(1)
            anchor_stmt = m_range.group(1)
        elif m_direct:
            start_idx = m_direct.start(1)
            end_idx = m_direct.end(1)
            anchor_stmt = m_direct.group(1)
        else:
            anchor_stmt = None

        if anchor_stmt:
            anchor_core = anchor_stmt.lstrip("\n")
            resolved = ours[:start_idx+1] + hook_start + anchor_core + hook_end + ours[end_idx:]

            pos_hook = resolved.find(hook_start)
            pos_anchor = resolved.find(anchor_core, pos_hook)
            pos_end = resolved.find(hook_end, pos_anchor + len(anchor_core)) if pos_anchor != -1 else -1
            if pos_hook == -1 or pos_anchor == -1 or pos_end == -1:
                raise RuntimeError(f"Lexical invariant failed while resolving conflict in {fn}: invalid hook injection topology!")
            if f"{label}:" not in hook_end:
                raise RuntimeError(f"Label integrity failed while resolving conflict in {fn}: target label '{label}' missing in hook_end!")
            label_pattern = rf"(?m)^\s*{re.escape(label)}\s*:"
            found_labels = re.findall(label_pattern, resolved)
            if len(found_labels) != 1:
                raise RuntimeError(f"Label integrity failed in {fn}: expected exactly one '{label}:' label, found {len(found_labels)}!")
            return resolved

    m_early_ret = re.search(
        rf"({guard_sus_map}[\s\S]*?SUSFS_IS_INODE_SUS_MAP[\s\S]*?return\s+[^;]+;[\s\S]*?#\s*endif[^\n]*\n+)",
        theirs
    )
    if m_early_ret:
        hook_ret = m_early_ret.group(1)
        sep = "\n" if not hook_ret.endswith("\n\n") and not ours.startswith("\n") else ""
        return hook_ret + sep + ours

    return block

def auto_resolve_known_conflicts(tree):
    diff_u = run_git(tree, ["diff", "--name-only", "--diff-filter=U"], check=False).stdout.split()
    if not diff_u:
        return

    for fn in diff_u:
        fpath = os.path.join(tree, fn)
        with open(fpath, "r", encoding="utf-8", errors="replace") as fp:
            content = fp.read()

        blocks = re.findall(r"<<<<<<< ours[\s\S]*?>>>>>>> theirs\n?", content)
        for b in blocks:
            resolved = resolve_header_conflict(b)
            if resolved != b:
                content = content.replace(b, resolved)

        blocks = re.findall(r"<<<<<<< ours[\s\S]*?>>>>>>> theirs\n?", content)
        for b in blocks:
            resolved = resolve_code_conflict(b, fn)
            if resolved != b:
                content = content.replace(b, resolved)

        with open(fpath, "w", encoding="utf-8") as fp:
            fp.write(content)

    for fn in diff_u:
        fpath = os.path.join(tree, fn)
        with open(fpath, "r", encoding="utf-8", errors="replace") as fp:
            data = fp.read()
            for marker in ["<<<<<<<", "=======", ">>>>>>>", "|||||||"]:
                if marker in data:
                    raise RuntimeError(f"Unresolved conflict marker '{marker}' remains in {fn}")

def get_official_susfs_patch(kmi, susfs_repo=None, patches_dir=None, pull_upstream=False):
    repo_path = find_susfs_repo(susfs_repo)
    if repo_path:
        branch_name = f"gki-{kmi}"
        rel_patch_path = f"kernel_patches/50_add_susfs_in_gki-{kmi}.patch"
        if pull_upstream:
            log(f"Fetching latest official SUSFS for '{branch_name}'...", level="STEP")
            res = run_git(repo_path, ["fetch", "origin", branch_name], check=False)
            if res.returncode != 0:
                err = res.stderr.strip() or res.stdout.strip()
                raise RuntimeError(f"Network error: Failed to fetch latest SUSFS branch '{branch_name}': {err}")

        for ref in [f"origin/{branch_name}", branch_name]:
            res = run_git(repo_path, ["show", f"{ref}:{rel_patch_path}"], check=False)
            if res.returncode == 0 and res.stdout:
                full_sha = run_git(repo_path, ["rev-parse", ref], check=False).stdout.strip()
                commit_sha = full_sha if full_sha else "unknown"
                short_sha = commit_sha[:12] if len(commit_sha) >= 12 else commit_sha
                log(f"Extracted official {kmi} SUSFS patch from {repo_path} ({ref} @ {short_sha})", level="INFO")
                return res.stdout, ref, commit_sha
        log(f"Could not read {rel_patch_path} from local {repo_path}", level="WARN")

    if patches_dir and not pull_upstream:
        root_patch = os.path.join(patches_dir, f"50_add_susfs_in_gki-{kmi}.patch")
        if os.path.isfile(root_patch):
            with open(root_patch, "rb") as fp:
                data_bytes = fp.read()
            digest = f"sha256:{hashlib.sha256(data_bytes).hexdigest()}"
            return data_bytes.decode("utf-8", errors="replace"), "local_patches_dir", digest

    log(f"Notice: Primary SUSFS git source unavailable; falling back to remote raw patch for {kmi}...", level="INFO")
    urls = [
        f"https://gitlab.com/simonpunk/susfs4ksu/-/raw/gki-{kmi}/kernel_patches/50_add_susfs_in_gki-{kmi}.patch",
        f"https://github.com/midori01/susfs4ksu/raw/gki-{kmi}/kernel_patches/50_add_susfs_in_gki-{kmi}.patch",
    ]
    remote_errors = []
    for u in urls:
        try:
            req = urllib.request.Request(u, headers={"User-Agent": "sync_susfs_patches/3.1"})
            with urllib.request.urlopen(req, timeout=15) as resp:
                if resp.status == 200:
                    data_bytes = resp.read()
                    source_tag = "gitlab_raw" if "gitlab" in u else "github_raw"
                    digest = f"sha256:{hashlib.sha256(data_bytes).hexdigest()}"
                    return data_bytes.decode("utf-8"), source_tag, digest
                remote_errors.append(f"{u}: HTTP {resp.status}")
        except Exception as e:
            remote_errors.append(f"{u}: {e}")

    err_details = "; ".join(remote_errors) if remote_errors else "unknown error"
    raise RuntimeError(f"Could not retrieve official SUSFS patch for {kmi}: {err_details}")

def generate_single_patch(tree, branch, subject, base_patch_file, author="github-actions <actions@github.com>", pull_upstream=False, susfs_provenance=None):
    prepare_branch(tree, branch, pull_upstream=pull_upstream)
    commit_info = run_git(tree, ["log", "-1", "--format=%h (\"%s\", %cd)", "--date=short"]).stdout.strip()
    target_full_sha = run_git(tree, ["rev-parse", "HEAD"]).stdout.strip()
    log(f"  Target commit: {commit_info}", level="INFO")

    apply_res = run_git(tree, ["apply", "--3way", base_patch_file], check=False)
    if apply_res.returncode != 0:
        diff_u = run_git(tree, ["diff", "--name-only", "--diff-filter=U"], check=False).stdout.split()
        if not diff_u:
            mod_files = run_git(tree, ["status", "--porcelain"], check=False).stdout.split()
            if not mod_files:
                err_msg = apply_res.stderr.strip() or apply_res.stdout.strip()
                raise RuntimeError(f"git apply --3way failed fatally on '{branch}' without producing any changes or conflicts: {err_msg}")

    auto_resolve_known_conflicts(tree)

    run_git(tree, ["add", "-A"], check=True)
    remaining_u = run_git(tree, ["diff", "--name-only", "--diff-filter=U"], check=False).stdout.split()
    if remaining_u:
        raise RuntimeError(f"Unresolved Git index conflicts remain on branch '{branch}': {', '.join(remaining_u)}")

    diffstat = run_git(tree, ["diff", "--cached", "--stat"]).stdout.rstrip()
    diffbody = run_git(tree, ["diff", "--cached"]).stdout.rstrip()

    if not diffbody:
        raise RuntimeError(f"Failed to generate diff on branch '{branch}': empty diff!")

    added_lines = "\n".join(
        line[1:] for line in diffbody.splitlines()
        if line.startswith("+") and not line.startswith("+++")
    )
    required_patterns = [
        (r"#ifdef\s+CONFIG_KSU_SUSFS", "CONFIG_KSU_SUSFS hook block"),
        (r"CONFIG_KSU_SUSFS_SUS_MAP", "CONFIG_KSU_SUSFS_SUS_MAP memory hook"),
        (r"CONFIG_KSU_SUSFS_SUS_KSTAT", "CONFIG_KSU_SUSFS_SUS_KSTAT stat hook"),
    ]
    for pat, desc in required_patterns:
        if not re.search(pat, added_lines):
            raise RuntimeError(f"Semantic invariant failed on '{branch}': required hook '{desc}' is missing from added diff code!")

    susfs_calls = re.findall(r"\bsusfs_[A-Za-z0-9_]+\s*\(", added_lines)
    if len(susfs_calls) < 50:
        raise RuntimeError(f"Semantic invariant failed on '{branch}': expected at least 50 active SUSFS API function calls, found {len(susfs_calls)}!")

    unique_susfs_calls = set(re.findall(r"\b(susfs_[A-Za-z0-9_]+)\s*\(", added_lines))
    if len(unique_susfs_calls) < 20:
        raise RuntimeError(f"Semantic invariant failed on '{branch}': expected at least 20 unique SUSFS API functions, found {len(unique_susfs_calls)}!")

    critical_apis = [
        "susfs_sus_kstat_spoof_generic_fillattr",
        "susfs_open_redirect_spoof_do_sys_openat",
        "susfs_spoof_uname",
    ]
    for api_fn in critical_apis:
        if not re.search(rf"\b{re.escape(api_fn)}\s*\(", added_lines):
            raise RuntimeError(f"Semantic invariant failed on '{branch}': critical SUSFS API '{api_fn}()' is missing from added diff code!")

    forbidden_markers = ["<<<<<<<", "=======", ">>>>>>>", "|||||||"]
    for marker in forbidden_markers:
        if marker in diffbody:
            raise RuntimeError(f"Forbidden conflict marker '{marker}' detected in generated patch for '{branch}'!")

    date_str = email.utils.formatdate(time.time(), localtime=True)
    extra_headers = [
        f"X-Kernel-Target-Branch: {branch}",
        f"X-Kernel-Target-Commit: {target_full_sha}",
    ]
    if susfs_provenance:
        s_ref, s_sha = susfs_provenance
        extra_headers.append(f"X-SUSFS-Source-Ref: {s_ref}")
        if s_sha.startswith("sha256:"):
            extra_headers.append(f"X-SUSFS-Source-Digest: {s_sha}")
        else:
            extra_headers.append(f"X-SUSFS-Source-Commit: {s_sha}")
    extra_hdr_str = "\n".join(extra_headers) + "\n"

    header = (
        f"From: {author}\n"
        f"Date: {date_str}\n"
        f"Subject: {subject}\n"
        f"{extra_hdr_str}\n"
        f"---\n"
        f"{diffstat}\n\n"
    )
    footer = "\n-- \n2.55.0\n"
    patch_content = header + diffbody + "\n" + footer

    for marker in forbidden_markers:
        if marker in patch_content:
            raise RuntimeError(f"Forbidden conflict marker '{marker}' detected in assembled patch for '{branch}'!")

    is_zero_offset, warns = check_patch_cleanliness(tree, branch, patch_content)
    return patch_content, is_zero_offset, warns

def extract_substantive_code_diff(patch_text):
    """
    Extracts purely substantive code changes (diff blocks) from a patch,
    stripping headers (From, Date, Subject, X-*, diffstat) and git footer.
    Used to prevent commit noise when only timestamp or metadata headers change.
    """
    lines = patch_text.splitlines()
    code_lines = []
    in_diff = False
    for line in lines:
        if line.startswith("diff --git "):
            in_diff = True
        if not in_diff:
            continue
        # Ignore index lines e.g. index 38c2ee7..93bbc15
        if line.startswith("index ") and re.match(r"^index [0-9a-fA-F]+\.\.[0-9a-fA-F]+", line):
            continue
        code_lines.append(line)

    # Pop off trailing git format-patch footer (e.g. '-- \n2.55.0') from the end
    while code_lines and code_lines[-1].strip() == "":
        code_lines.pop()
    if len(code_lines) >= 2 and re.match(r"^\d+\.\d+", code_lines[-1].strip()) and code_lines[-2].strip() == "--":
        code_lines.pop()  # remove version string
        code_lines.pop()  # remove '--'
    elif code_lines and code_lines[-1].strip() == "--":
        code_lines.pop()

    return "\n".join(code_lines).strip()

def main():
    parser = argparse.ArgumentParser(
        description="Sync and generate 0-offset SUSFS patches for all kernels in GitHub Actions."
    )
    parser.add_argument(
        "-k", "--kernel",
        default="all",
        choices=["6.1", "6.6", "6.12", "all"],
        help="Kernel version to synchronize (default: all)",
    )
    parser.add_argument(
        "--base",
        default="official",
        help="Base patch source: 'official' (from susfs4ksu repo), or file path",
    )
    parser.add_argument(
        "--patches-dir",
        default=None,
        help="Path to .github/patches directory (auto-detected if omitted)",
    )
    parser.add_argument(
        "--susfs-repo",
        default=None,
        help="Path to susfs4ksu git repository (auto-detected if omitted)",
    )
    parser.add_argument(
        "--tree",
        default=None,
        help="Path to kernel git repository (auto-detected if omitted)",
    )
    parser.add_argument(
        "--sublevels",
        default="all",
        help="Sublevels for 6.12 ('all', 'active', or comma-separated list like '38,69,81,93')",
    )
    parser.add_argument(
        "--author",
        default="github-actions <actions@github.com>",
        help="Author string for generated patch headers",
    )
    parser.add_argument(
        "--pull",
        action="store_true",
        help="Pull latest upstream from remote (if running in pre-existing persistent tree)",
    )
    parser.add_argument(
        "--check-only",
        action="store_true",
        help="Validate existing patch files against the kernel tree without writing new patches",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Simulate generation and verify 0-offset without writing to files",
    )
    args = parser.parse_args()

    tree = find_kernel_tree(args.tree)
    susfs_repo = find_susfs_repo(args.susfs_repo)
    patches_base_dir = find_patches_dir(args.patches_dir)

    dirty_check = run_git(tree, ["status", "--porcelain=v1", "--untracked-files=all"], check=False).stdout.strip()
    if dirty_check:
        log(f"Kernel tree at '{tree}' has uncommitted changes. Please commit or stash them before running sync.", level="ERR")
        sys.exit(1)
    log("Kernel tree is clean; automated branch checkout and reset operations are permitted.", level="INFO")

    log(f"Kernel tree:  {tree}")
    log(f"Patches dir:  {patches_base_dir}")
    if susfs_repo:
        log(f"SUSFS repo:   {susfs_repo}")

    selected_kvs = ["6.1", "6.6", "6.12"] if args.kernel == "all" else [args.kernel]

    temp_files_to_clean = []
    initial_branch = None
    initial_commit = None
    is_detached = False

    cur_commit = run_git(tree, ["rev-parse", "HEAD"], check=False).stdout.strip()
    sym_res = run_git(tree, ["symbolic-ref", "--quiet", "--short", "HEAD"], check=False)
    cur_branch = sym_res.stdout.strip()
    initial_commit = cur_commit
    if sym_res.returncode == 0 and cur_branch:
        initial_branch = cur_branch
        is_detached = False
    elif cur_commit:
        initial_branch = cur_commit
        is_detached = True

    try:
        # Check-only Mode
        if args.check_only:
            log("Running 0-offset validation on existing patch files...")
            all_ok = True
            for kv in selected_kvs:
                kcfg = KERNEL_CONFIGS[kv]
                kmi = kcfg["kmi"]
                pdir = os.path.join(patches_base_dir, kcfg["patch_rel_dir"])
                targets = discover_targets(tree, kmi, kv, patches_base_dir, static_targets=kcfg.get("targets", {}))
                if kv == "6.12" and args.sublevels == "active":
                    sub_keys = [k for k, t in targets.items() if not t.get("is_deprecated", False)]
                elif kv == "6.12" and args.sublevels != "all":
                    sub_keys = [s.strip() for s in args.sublevels.split(",") if s.strip() in targets]
                else:
                    sub_keys = list(targets.keys())

                for sk in sub_keys:
                    tinfo = targets[sk]
                    ppath = os.path.join(pdir, tinfo["filename"])
                    label = f"{kv}" if sk == "single" else f"{kv}.{sk}"
                    if not os.path.isfile(ppath):
                        log(f"{label} ({tinfo['desc']}): NOT FOUND ({ppath})", level="WARN")
                        all_ok = False
                        continue
                    with open(ppath, "r", encoding="utf-8", errors="replace") as fp:
                        content = fp.read()
                    prepare_branch(tree, tinfo["branch"], pull_upstream=args.pull)
                    ok, warns = check_patch_cleanliness(tree, tinfo["branch"], content)
                    if ok:
                        log(f"{label:7s} ({tinfo['desc']}): 100% CLEAN (0 offset, 0 fuzz)", level="PASS")
                    else:
                        log(f"{label:7s} ({tinfo['desc']}): HAS WARNINGS ({len(warns)})", level="WARN")
                        for w in warns[:3]:
                            print(f"    {w}")
                        all_ok = False
            sys.exit(0 if all_ok else 1)

        # Generation Mode
        grand_results = {}
        for kv in selected_kvs:
            kcfg = KERNEL_CONFIGS[kv]
            kmi = kcfg["kmi"]
            pdir = os.path.join(patches_base_dir, kcfg["patch_rel_dir"])
            os.makedirs(pdir, exist_ok=True)

            if args.base in ["official", "simonpunk", "upstream"]:
                log(f"Obtaining official {kv} SUSFS patch for {kmi}...", level="STEP")
                content, s_ref, s_sha = get_official_susfs_patch(kmi, susfs_repo, patches_base_dir, pull_upstream=args.pull)
                susfs_prov = (s_ref, s_sha)
                tf = tempfile.NamedTemporaryFile("w", suffix=".patch", delete=False)
                tf.write(content)
                tf.close()
                temp_files_to_clean.append(tf.name)
                base_patch_file = tf.name
            else:
                base_patch_file = os.path.abspath(args.base)
                if not os.path.isfile(base_patch_file):
                    log(f"Specified base patch not found: {base_patch_file}", level="ERR")
                    sys.exit(1)
                with open(base_patch_file, "rb") as bp_fp:
                    custom_digest = f"sha256:{hashlib.sha256(bp_fp.read()).hexdigest()}"
                susfs_prov = (os.path.basename(base_patch_file), custom_digest)

            targets = discover_targets(tree, kmi, kv, patches_base_dir, static_targets=kcfg.get("targets", {}))
            if kv == "6.12" and args.sublevels == "active":
                sub_keys = [k for k, t in targets.items() if not t.get("is_deprecated", False)]
            elif kv == "6.12" and args.sublevels != "all":
                sub_keys = [s.strip() for s in args.sublevels.split(",") if s.strip() in targets]
            else:
                sub_keys = list(targets.keys())

            kv_results = {}
            for sk in sub_keys:
                tinfo = targets[sk]
                label = f"{kv}" if sk == "single" else f"{kv}.{sk}"
                log(f"Generating patch for {label} ({tinfo['desc']}) on branch '{tinfo['branch']}'...", level="STEP")
                p_content, is_ok, warns = generate_single_patch(
                    tree, tinfo["branch"], tinfo["subject"], base_patch_file, author=args.author, pull_upstream=args.pull, susfs_provenance=susfs_prov
                )
                if is_ok:
                    log(f"{label}: 100% 0-OFFSET / 0-FUZZ / 0-FAILURES!", level="PASS")
                else:
                    log(f"{label}: HAS WARNINGS", level="WARN")
                    for w in warns[:3]:
                        print(f"    {w}")
                kv_results[sk] = (p_content, is_ok, tinfo["filename"], pdir)
            grand_results[kv] = kv_results

        # Summary Display
        print("\n" + "=" * 65)
        log("Synchronization Summary:")
        for kv, results in grand_results.items():
            for sk, (content, is_ok, fname, pdir) in results.items():
                label = f"Kernel {kv}" if sk == "single" else f"Kernel {kv}.{sk}"
                status = "\033[1;32mPERFECT 0-OFFSET\033[0m" if is_ok else "\033[1;33mHAS OFFSET/FUZZ\033[0m"
                print(f"  - {label:14s}: {status} ({len(content.splitlines())} lines)")
        print("=" * 65)

        # Write to files with Substantive Code Diff Guard
        if not args.dry_run:
            new_count = 0
            updated_count = 0
            unchanged_count = 0

            for kv, results in grand_results.items():
                for sk, (content, is_ok, fname, pdir) in results.items():
                    target_file = os.path.join(pdir, fname)
                    existed = os.path.isfile(target_file)
                    if existed:
                        with open(target_file, "r", encoding="utf-8", errors="replace") as fp:
                            old_content = fp.read()
                        old_code = extract_substantive_code_diff(old_content)
                        new_code = extract_substantive_code_diff(content)
                        if old_code == new_code:
                            log(f"Unchanged code diff for {fname} (preserving existing timestamp): skipping write.", level="INFO")
                            unchanged_count += 1
                            continue
                        else:
                            log(f"Substantive code changes detected for {fname}: updating file.", level="PASS")
                            updated_count += 1
                    else:
                        log(f"New patch created: {fname}", level="PASS")
                        new_count += 1

                    with open(target_file, "w", encoding="utf-8") as fp:
                        fp.write(content)

            log(f"Sync complete: {new_count} new, {updated_count} updated, {unchanged_count} unchanged.", level="PASS")
        else:
            log("Dry-run complete. No files were written to disk.", level="INFO")

    finally:
        for tf in temp_files_to_clean:
            if os.path.isfile(tf):
                try:
                    os.remove(tf)
                except Exception:
                    pass

        try:
            if initial_branch:
                run_git(tree, ["reset", "--hard", "HEAD"], check=False)
                run_git(tree, ["clean", "-fd"], check=False)
                if is_detached:
                    run_git(tree, ["checkout", "-q", "--detach", initial_commit], check=False)
                else:
                    run_git(tree, ["checkout", "-q", initial_branch], check=False)
        except Exception:
            pass

if __name__ == "__main__":
    main()
