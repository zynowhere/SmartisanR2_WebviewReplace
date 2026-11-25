#!/system/bin/sh

[ "$ARCH" = "arm64" ] || abort "! 仅支持 arm64 架构设备 (当前: $ARCH)"

ui_print "- 目标设备: $(getprop ro.product.model) ($(getprop ro.product.device)), SDK $(getprop ro.build.version.sdk)"

# 确保遮蔽原厂 /product/app/webview/oat 预编译目录
mkdir -p "$MODPATH/system/product/app/webview/oat"
: > "$MODPATH/system/product/app/webview/oat/.replace"

# 部署 post-fs-data 回滚守卫：停用或移除模块时在 system_server 启动前清理副本与包解析缓存
GUARD_DIR="/data/adb/post-fs-data.d"
GUARD_FILE="$GUARD_DIR/webview_upgrade_guard.sh"
mkdir -p "$GUARD_DIR"
cat > "$GUARD_FILE" <<'EOF'
#!/system/bin/sh
MODDIR="/data/adb/modules/webview_upgrade"

if [ ! -d "$MODDIR" ] || [ -f "$MODDIR/disable" ] || [ -f "$MODDIR/remove" ]; then
  rm -rf /data/app/com.android.webview-* /data/app/~~*/com.android.webview-* 2>/dev/null
  find /data/system/package_cache -iname "*webview*" -exec rm -rf {} + 2>/dev/null
  [ ! -d "$MODDIR" ] && rm -f "$0"
fi
EOF
chmod 0755 "$GUARD_FILE"
chown 0:0 "$GUARD_FILE" 2>/dev/null

set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755

ui_print "- 已配置原厂 oat 目录遮蔽 (.replace)"
ui_print "- 已部署停用/卸载自动清理回滚守卫"
ui_print "- 重启开机后约 10 秒将自动同步 134 至 /data/app (完美兼容 Shamiko / 排除列表)"
