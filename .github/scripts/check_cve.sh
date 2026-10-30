#!/bin/bash
# check_cve.sh - CVE-2026-43499 / CVE-2026-64560 Detection Script
# Usage: check_cve.sh [43499|64560]  (default: check all)

RTMUTEX="kernel/locking/rtmutex.c"
RTMUTEX_API="kernel/locking/rtmutex_api.c"
EXIT="kernel/exit.c"
SIGNAL="kernel/signal.c"
POSIX_CPU_TIMERS="kernel/time/posix-cpu-timers.c"

# Ensure required files exist
for f in "$RTMUTEX" "$RTMUTEX_API" "$EXIT" "$SIGNAL" "$POSIX_CPU_TIMERS"; do
    if [ ! -f "$f" ]; then
        echo "Error: $f not found. Run from kernel source root." >&2
        exit 1
    fi
done

# Print summary and return 0 (patched), 1 (vulnerable) or 2 (partial)
summary() {
    local cve="$1"
    shift
    local all=true none=true
    for r in "$@"; do
        ${r#*=} && none=false || all=false
    done

    echo "========================================="
    echo "Result:"
    echo "========================================="

    if $all; then
        echo "✅ Fully patched — no CVE-$cve vulnerability"
        return 0
    elif $none; then
        echo "❌ Vulnerable — CVE-$cve not patched"
        return 1
    else
        echo "⚠️  Inconsistent state detected:"
        for r in "$@"; do
            printf '  %-18s%s\n' "${r%%=*}:" "$(${r#*=} && echo '✅' || echo '❌')"
        done
        echo ""
        echo "Partial patch application detected. Manual inspection required."
        return 2
    fi
}

check_43499() {
    echo "========================================="
    echo "CVE-2026-43499 Vulnerability Detection"
    echo "========================================="
    echo ""

    # Primary fix
    echo "[1] Primary fix (waiter_task local variable)"
    if grep -Fq 'struct task_struct *waiter_task = waiter->task;' "$RTMUTEX"; then
        echo "    ✅ Fixed"
        PRIMARY=true
    else
        echo "    ❌ Vulnerable: direct waiter->task usage"
        PRIMARY=false
    fi
    echo ""

    # Null guard
    echo "[2] Null pointer guard"
    if grep -Fq 'if (!waiter_task) /* never enqueued */' "$RTMUTEX"; then
        echo "    ✅ Fixed"
        NULL_GUARD=true
    else
        echo "    ❌ Missing null pointer guard"
        NULL_GUARD=false
    fi
    echo ""

    # Proxy guard
    echo "[3] Proxy error handling"
    if grep -Fq 'if (unlikely(ret < 0))' "$RTMUTEX_API"; then
        echo "    ✅ Fixed"
        PROXY_GUARD=true
    else
        echo "    ❌ Missing proxy error handling"
        PROXY_GUARD=false
    fi
    echo ""

    summary 2026-43499 "Primary fix=$PRIMARY" "Null guard=$NULL_GUARD" "Proxy guard=$PROXY_GUARD"
}

check_64560() {
    echo "========================================="
    echo "CVE-2026-64560 Vulnerability Detection"
    echo "========================================="
    echo ""

    # Release store
    echo "[1] Release store of sighand in __exit_signal()"
    if grep -Fq 'smp_store_release(&tsk->sighand, NULL);' "$EXIT"; then
        echo "    ✅ Fixed"
        RELEASE=true
    else
        echo "    ❌ Vulnerable: plain tsk->sighand = NULL store"
        RELEASE=false
    fi
    echo ""

    # Acquire barrier
    echo "[2] Acquire barrier in lock_task_sighand()"
    if grep -Fq 'smp_acquire__after_ctrl_dep();' "$SIGNAL"; then
        echo "    ✅ Fixed"
        ACQUIRE=true
    else
        echo "    ❌ Missing acquire barrier"
        ACQUIRE=false
    fi
    echo ""

    # Sighand lookup helper
    echo "[3] Timer sighand lookup with retry"
    if grep -Fq 'static struct task_struct *timer_lock_sighand(struct k_itimer *timer, unsigned long *flags)' "$POSIX_CPU_TIMERS"; then
        echo "    ✅ Fixed"
        LOOKUP=true
    else
        echo "    ❌ Vulnerable: non-leader exec() race in timer del/set/rearm"
        LOOKUP=false
    fi
    echo ""

    summary 2026-64560 "Release store=$RELEASE" "Acquire barrier=$ACQUIRE" "Sighand lookup=$LOOKUP"
}

RET=0
for cve in ${1:-43499 64560}; do
    case "$cve" in
        43499) check_43499 ;;
        64560) check_64560 ;;
        *) echo "Error: unknown CVE $cve" >&2; exit 1 ;;
    esac
    rc=$?
    [ $rc -gt $RET ] && RET=$rc
    echo ""
done
exit $RET
