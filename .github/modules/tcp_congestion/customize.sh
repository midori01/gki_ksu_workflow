set_perm_recursive "$MODPATH" 0 0 0755 0644
for script in tcpcc service.sh uninstall.sh live-install.sh; do
	set_perm "$MODPATH/$script" 0 0 0755
done

if [ "${BOOTMODE:-}" = true ]; then
	if [ "${KSU_HAS_HOT_INSTALL:-}" = true ]; then
		export MODULE_HOT_INSTALL_REQUEST=true
		export MODULE_HOT_RUN_SCRIPT=tcpcc
		ui_print "- Requested native KernelSU hot installation."
	else
		live_result=0
		BOOTMODE="$BOOTMODE" sh "$MODPATH/live-install.sh" install "$MODPATH" "$$" "${ZIPFILE:-}" || live_result=$?
		case "$live_result" in
			0) ui_print "- WebUI is active. Open the module to choose an algorithm." ;;
			2) ui_print "- Staged for activation on the next boot." ;;
			*) abort "! Could not activate TCP Congestion Control." ;;
		esac
	fi
fi
