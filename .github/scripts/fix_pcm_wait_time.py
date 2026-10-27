#!/usr/bin/env python3
# Restore the pre-0d18de045eba ("ALSA: pcm: fix wait_time calculations")
# PCM timeouts on android14-6.1, which cause audio stutters on 6.1 GKI
# devices (e.g. Pixel 7/8). Later snd_pcm_drain() fixes are kept.
#
# Matches the code by shape instead of patch context, so it works across
# ASB/LTS revisions: sources without the commit (older ASBs, or a future
# upstream revert) are left alone, and unknown shapes only emit a warning.
# Run from the kernel source root (common/).
import re
import sys
from pathlib import Path

def warn(msg):
    print(f"::warning::PCM wait_time fix: {msg}")


def fix_lib(text):
    new = re.sub(
        r"(\t+)wait_time = 100;\n"
        r"\n"
        r"(\t+)if \(runtime->rate\) \{\n"
        r"(\t+)long t = runtime->buffer_size \* 1100 / runtime->rate;\n"
        r"(\t+wait_time = max\(t, wait_time\);\n"
        r"\t+\}\n)"
        r"(\t+)\}\n"
        r"\t+wait_time = msecs_to_jiffies\(wait_time\);\n",
        lambda m: (
            f"{m[1]}wait_time = 10;\n"
            f"\n"
            f"{m[2]}if (runtime->rate) {{\n"
            f"{m[3]}long t = runtime->period_size * 2 /\n"
            f"{m[3]}\t runtime->rate;\n"
            f"{m[4]}"
            f"{m[1]}wait_time = msecs_to_jiffies(wait_time * 1000);\n"
            f"{m[5]}}}\n"
        ),
        text,
    )
    return new if new != text else None


def fix_drain(text):
    start = text.find("static int snd_pcm_drain(")
    end = text.find("\n}\n", start)
    if start < 0 or end < 0:
        return None
    body = text[start:end]
    # UAF-fixed drain caches buffer_size before unlocking; cache period_size.
    body = re.sub(r"\bdrain_bufsz\b", "drain_period_size", body)
    body = body.replace("drain_period_size = to_check->buffer_size;",
                        "drain_period_size = to_check->period_size;")
    m = re.search(
        r"tout = 100;\n"
        r"(\t+if \(\S+\) \{\n)"
        r"(\t+)long t = (\S+) \* 1100 / (\S+);\n"
        r"(\t+tout = max\(t, tout\);\n"
        r"\t+\}\n)"
        r"(\t+)tout = msecs_to_jiffies\(tout\);",
        body,
    )
    if not m:
        return None
    frames = m[3]
    if frames.endswith("->buffer_size"):
        frames = frames[:-len("buffer_size")] + "period_size"
    elif frames != "drain_period_size":
        return None
    body = body[:m.start()] + (
        f"tout = 10;\n"
        f"{m[1]}"
        f"{m[2]}long t = {frames} * 2 / {m[4]};\n"
        f"{m[5]}"
        f"{m[6]}tout = msecs_to_jiffies(tout * 1000);"
    ) + body[m.end():]
    return text[:start] + body + text[end:]


def main():
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    # The old calculation converts seconds to jiffies; 0d18de dropped it.
    jobs = [
        (root / "sound/core/pcm_lib.c", fix_lib, "wait_for_avail()",
         "wait_time = msecs_to_jiffies(wait_time * 1000);"),
        (root / "sound/core/pcm_native.c", fix_drain, "snd_pcm_drain()",
         "tout = msecs_to_jiffies(tout * 1000);"),
    ]
    for path, fix, name, old in jobs:
        text = path.read_text()
        if old in text:
            print(f"{name}: old wait_time calculation already in place, skipping.")
            continue
        new = fix(text)
        if new is None or old not in new:
            warn(f"unexpected {name} code in {path.name}, left unchanged.")
            continue
        path.write_text(new)
        print(f"{name}: restored old wait_time calculation.")


if __name__ == "__main__":
    main()
