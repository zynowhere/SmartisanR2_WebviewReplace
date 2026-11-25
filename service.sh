#!/system/bin/sh
MODDIR=${0%/*}
LOG="$MODDIR/service.log"

count=0
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 2
  count=$((count + 1))
  [ "$count" -ge 90 ] && exit 0
done
sleep 3

[ -f "$MODDIR/disable" ] || [ -f "$MODDIR/remove" ] && exit 0

CUR_PATH="$(pm path com.android.webview 2>/dev/null | head -n 1)"
case "$CUR_PATH" in
  package:/data/app/*)
    echo "$(date '+%F %T') active in /data/app: $CUR_PATH" > "$LOG"
    exit 0
    ;;
esac

APK="$MODDIR/system/product/app/webview/webview.apk"
TMP="/data/local/tmp/webview_upgrade_134.apk"

if [ -f "$APK" ]; then
  echo "$(date '+%F %T') installing WebView 134 to /data/app (previous: $CUR_PATH)..." > "$LOG"
  cp "$APK" "$TMP" && chmod 0644 "$TMP"
  RES="$(pm install -r "$TMP" 2>&1)"
  rm -f "$TMP"
  echo "$(date '+%F %T') pm install: $RES" >> "$LOG"
  echo "$(date '+%F %T') current path: $(pm path com.android.webview 2>/dev/null | tr '\n' ' ')" >> "$LOG"
fi
