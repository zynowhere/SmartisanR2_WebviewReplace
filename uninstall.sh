#!/system/bin/sh
rm -rf /data/app/com.android.webview-* /data/app/~~*/com.android.webview-* 2>/dev/null
find /data/system/package_cache -iname "*webview*" -exec rm -rf {} + 2>/dev/null
rm -f /data/adb/post-fs-data.d/webview_upgrade_guard.sh 2>/dev/null
