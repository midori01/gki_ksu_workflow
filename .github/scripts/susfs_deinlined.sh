#!/bin/bash
# susfs_deinlined.sh - Convert official SUSFS inline-hook patch to de-inlined version

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <official_susfs_patch> [output_patch]"
    exit 1
fi

INPUT="$1"
OUTPUT="${2:-deinlined.patch}"

python3 - "$INPUT" "$OUTPUT" << 'EOF'
import sys
import re

def read_patch(filename):
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found!", file=sys.stderr)
        sys.exit(1)

def split_patch(content):
    parts = re.split(r'(?=^diff --git )', content, flags=re.MULTILINE)
    return parts[1:]

def get_target_file(patch):
    for line in patch.split('\n'):
        if line.startswith('+++ b/'):
            return line[6:].split('\t')[0]
    return None

def get_body(patch):
    lines = patch.split('\n')
    for i, line in enumerate(lines):
        if line.startswith('@@'):
            return lines[:i], lines[i:]
    return lines, []

def remove_duplicate_plus_empty(lines):
    result = []
    prev_plus_empty = False
    for line in lines:
        is_plus_empty = (line.strip() == '+')
        if is_plus_empty and prev_plus_empty:
            continue
        result.append(line)
        prev_plus_empty = is_plus_empty
    return result

def process_input_c(body):
    result = []
    i = 0
    replaced = False
    while i < len(body):
        line = body[i]
        if line.strip() == '+#ifdef CONFIG_KSU_SUSFS':
            depth = 1
            j = i + 1
            while j < len(body) and depth > 0:
                if body[j].strip() == '+#ifdef CONFIG_KSU_SUSFS':
                    depth += 1
                elif body[j].strip() == '+#endif':
                    depth -= 1
                j += 1
            if not replaced:
                result.append('+extern struct static_key_false ksu_input_hook_key_false;')
                result.append('+')
                replaced = True
            i = j
            continue
        result.append(line)
        i += 1
    return remove_duplicate_plus_empty(result)

def process_normal_file(body, target):
    result = []
    i = 0
    while i < len(body):
        line = body[i]

        if line.strip() == '+#ifdef CONFIG_KSU_SUSFS':
            block_end = i + 1
            depth = 1
            has_include = False
            while block_end < len(body) and depth > 0:
                if body[block_end].strip() == '+#ifdef CONFIG_KSU_SUSFS':
                    depth += 1
                elif body[block_end].strip() == '+#endif':
                    depth -= 1
                if '#include' in body[block_end]:
                    has_include = True
                block_end += 1

            if has_include:
                remaining = '\n'.join(body[block_end:])
                if 'CONFIG_KSU_SUSFS_' in remaining:
                    result.extend(body[i:block_end])
                    i = block_end
                    continue

            i = block_end
            continue

        if line.strip() == '+#ifndef CONFIG_KSU_SUSFS':
            depth = 1
            block_end = i + 1
            else_idx = -1
            endif_idx = -1
            while block_end < len(body) and depth > 0:
                stripped = body[block_end].strip()
                if stripped.startswith('+#if'):
                    depth += 1
                elif stripped == '+#else' and depth == 1:
                    else_idx = block_end
                elif stripped == '+#endif':
                    depth -= 1
                    if depth == 0:
                        endif_idx = block_end
                block_end += 1

            if else_idx > 0 and endif_idx > 0:
                result.extend(body[else_idx + 1:endif_idx])
            i = endif_idx + 1 if endif_idx > 0 else block_end
            continue

        result.append(line)
        i += 1

    return result

def parse_hunk_header(line):
    match = re.match(r'@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@(.*)', line)
    if not match:
        return None
    return (
        int(match.group(1)),
        int(match.group(2)) if match.group(2) else 1,
        int(match.group(3)),
        int(match.group(4)) if match.group(4) else 1,
        match.group(5)
    )

def format_hunk_header(old_start, old_total, new_start, new_total, suffix):
    old_str = f"-{old_start}" if old_total == 1 else f"-{old_start},{old_total}"
    new_str = f"+{new_start}" if new_total == 1 else f"+{new_start},{new_total}"
    return f"@@ {old_str} {new_str} @@{suffix}"

def clean_body(body):
    cleaned = []
    i = 0
    while i < len(body):
        line = body[i]

        if line.startswith('@@'):
            hunk_lines = []
            j = i + 1
            while j < len(body):
                if body[j].startswith('@@') or body[j].startswith('diff --git'):
                    break
                hunk_lines.append(body[j])
                j += 1

            ins_all = sum(1 for l in hunk_lines if l.startswith('+') and not l.startswith('+++'))
            dels_all = sum(1 for l in hunk_lines if l.startswith('-') and not l.startswith('---'))

            ins_meaningful = sum(1 for l in hunk_lines 
                                if l.startswith('+') and not l.startswith('+++') and l.strip() != '+')
            dels_meaningful = sum(1 for l in hunk_lines 
                                 if l.startswith('-') and not l.startswith('---') and l.strip() != '-')

            if ins_meaningful == 0 and dels_meaningful == 0:
                i = j
                continue

            header_info = parse_hunk_header(line)
            if header_info:
                old_start, _, new_start, _, suffix = header_info
                context = sum(1 for l in hunk_lines if l.startswith(' '))
                old_total = dels_all + context
                new_total = ins_all + context
                cleaned.append(format_hunk_header(old_start, old_total, new_start, new_total, suffix))
                cleaned.extend(hunk_lines)
                i = j
                continue

        cleaned.append(line)
        i += 1

    return cleaned

def has_real_changes(body):
    for line in body:
        stripped = line.strip()
        if line.startswith('+') and not line.startswith('+++') and stripped != '+':
            return True
        if line.startswith('-') and not line.startswith('---') and stripped != '-':
            return True
    return False

def process_patch(patch):
    target = get_target_file(patch)
    if not target:
        return None

    if target.startswith('security/'):
        return None

    header, body = get_body(patch)
    if not body:
        return None

    if target == 'drivers/input/input.c':
        new_body = process_input_c(body)
    else:
        new_body = process_normal_file(body, target)

    new_body = clean_body(new_body)

    if not has_real_changes(new_body):
        return None

    return '\n'.join(header + new_body)

def main():
    if len(sys.argv) < 2:
        print("Usage: susfs_deinlined.sh <input_patch> [output_patch]", file=sys.stderr)
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else 'deinlined.patch'

    content = read_patch(input_file)
    file_patches = split_patch(content)

    if not file_patches:
        print("Error: No diff --git sections found in patch!", file=sys.stderr)
        sys.exit(1)

    print(f"Processing {len(file_patches)} file patches...")

    processed = []
    removed = []

    for patch in file_patches:
        target = get_target_file(patch)
        result = process_patch(patch)

        if result:
            processed.append(result.rstrip('\n'))
            print(f"  [KEEP] {target}")
        else:
            removed.append(target)
            print(f"  [DROP] {target}")

    if not processed:
        print("Error: No file patches remain after processing!", file=sys.stderr)
        sys.exit(1)

    with open(output_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(processed))
        f.write('\n')

    print(f"\nDone! Output: {output_file}")
    print(f"Kept: {len(processed)} files")
    print(f"Dropped: {len(removed)} files")
    for f in removed:
        print(f"  - {f}")

if __name__ == '__main__':
    main()
EOF

echo "Done"
