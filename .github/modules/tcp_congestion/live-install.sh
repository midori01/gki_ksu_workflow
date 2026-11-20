#!/system/bin/sh
# Legacy file-based installers keep modules_update for their normal next boot.
umask 077
active=/data/adb/modules/tcp_congestion
staged=/data/adb/modules_update/tcp_congestion
data=/data/adb/tcp_congestion
payload='module.prop skip_mount tcpcc service.sh uninstall.sh live-install.sh webroot'
stamp() {
	sed 's/^.*) //' "/proc/$1/stat" 2>/dev/null | awk '$1 != "Z" && NF >= 20 {print $20}'
}

installer_parent() {
	p=$1 zip=$2 match= depth=0
	[ -n "$zip" ] || return 1
	while [ "$p" -gt 1 ] && [ "$depth" -lt 32 ]; do
		start=$(stamp "$p"); [ -n "$start" ] || return 1
		if tr '\000' '\n' < "/proc/$p/cmdline" | INSTALL_ZIP="$zip" awk '
			$0 == ENVIRON["INSTALL_ZIP"] && ((prev == "install" && prev2 == "module") ||
			    prev == "--install-module" || (prev == "1" && prev2 == "dummy" && prev3 ~ /(^|\/)update-binary$/)) { found=1 }
			{ prev3=prev2; prev2=prev; prev=$0 } END { exit !found }'; then
			match="$p $start"
		fi
		parent=$(sed 's/^.*) //' "/proc/$p/stat" | awk '{print $2}')
		[ "$(stamp "$p")" = "$start" ] || return 1
		p=$parent depth=$((depth+1))
	done
	[ "$p" = 1 ] && [ -n "$match" ] && printf '%s\n' "$match"
}

finish() {
	token=$1 shell_pid=$2 shell_start=$3 outer_pid=$4 outer_start=$5
	for _ in $(seq 1 60); do
		if [ "$(stamp "$shell_pid")" != "$shell_start" ] && [ "$(stamp "$outer_pid")" != "$outer_start" ]; then
			exec 9<"$data" && flock -x 0 <&9 || return 1
			[ "$(cat "$active/.live-id" 2>/dev/null)" = "$token" ] &&
				[ "$(cat "$staged/.live-id" 2>/dev/null)" = "$token" ] || return 0
			[ ! -e "$active/remove" ] && [ ! -e "$active/disable" ] || return 0
			rm -f "$active/update"
			return $?
		fi
		sleep 1
	done
}

publish() (
	exec 9<"$data" && flock -x 0 <&9 || exit 1
	work=$(mktemp -d "$data/.install.XXXXXX") || exit 1
	cleanup() {
		if [ -d "$work/old" ] && [ ! -e "$active" ]; then
			mv "$work/old" "$active" || { echo "! Previous module retained at $work/old" >&2; return; }
		fi
		rm -rf "$work"
	}
	trap cleanup EXIT
	trap 'exit 1' HUP INT TERM

	mkdir "$work/new" || exit 1
	for item in $payload; do
		cp -Rp "$staged/$item" "$work/new/" || exit 1
	done
	printf '%s\n' "$token" > "$staged/.live-id" && cp "$staged/.live-id" "$work/new/" || exit 1
	chmod 0755 "$work/new" && chcon -R u:object_r:system_file:s0 "$work/new" || exit 1
	# Only move this module on an ordinary, unmounted, same-filesystem layout.
	[ "$(stat -c %d "$work")" = "$(stat -c %d "${active%/*}")" ] || exit 2
	if [ -d "$active" ]; then mv "$active" "$work/old" || exit 1; fi
	mv "$work/new" "$active" || exit 1
)

case $1 in
	finish) shift; finish "$@"; exit $? ;;
	install) shift ;;
	*) exit 1 ;;
esac

[ "${BOOTMODE:-}" = true ] && [ "$1" = "$staged" ] || exit 2
for path in "${active%/*}" "$active" "${staged%/*}" "$staged" "$data"; do
	[ ! -L "$path" ] || exit 2
done
[ ! -e "$active" ] || [ -d "$active" ] || exit 2
[ ! -e "$active/disable" ] && [ ! -e "$active/remove" ] || exit 2
if [ -f "$active/module.prop" ]; then
	grep -Fxq 'id=tcp_congestion' "$active/module.prop" || exit 2
fi
[ -r /proc/mounts ] && awk -v a="$active" -v s="$staged" -v ap="${active%/*}" -v sp="${staged%/*}" '
	$2 == ap || $2 == sp || $2 == a || $2 == s ||
	index($2,a "/")==1 || index($2,s "/")==1 { mounted=1 }
	END { exit mounted }' /proc/mounts || exit 2
grep -Fxq 'id=tcp_congestion' "$staged/module.prop" && [ -f "$staged/webroot/index.html" ] || exit 1
for item in $payload; do
	[ -e "$staged/$item" ] && [ ! -L "$staged/$item" ] || exit 1
done
[ -z "$(find "$staged/webroot" ! -type f ! -type d -print)" ] || exit 1
mkdir -p "$data" || exit 1
token=$(cat /proc/sys/kernel/random/uuid) && [ -n "$token" ] || exit 1
publish || exit $?
sh "$active/tcpcc" apply || echo "! Saved selection could not be applied." >&2

shell_pid=$2
shell_start=$(stamp "$shell_pid")
outer=$(installer_parent "$shell_pid" "$3")
if [ -n "$shell_start" ] && [ -n "$outer" ]; then
	set -- $outer
	nohup sh "$active/live-install.sh" finish "$token" "$shell_pid" "$shell_start" "$1" "$2" </dev/null >/dev/null 2>&1 &
else
	echo "- Files are active. The manager may still show a pending update."
fi
exit 0
