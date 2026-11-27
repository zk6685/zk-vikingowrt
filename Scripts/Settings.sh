#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

#移除luci-app-attendedsysupgrade
find ./feeds/luci/collections/ -type f -name "Makefile" -exec sed -i "/attendedsysupgrade/d" {} +
#修改默认主题
find ./feeds/luci/collections/ -type f -name "Makefile" -exec sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" {} +
#修改immortalwrt.lan关联IP
find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js" -exec sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" {} +
#添加编译日期标识
find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js" -exec sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" {} +

#修改默认WIFI账号密码
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
ROUTER_TOOL="./package/emortal/luci-app-router-tool/root/etc/config/router-tool"
for file in "$ROUTER_TOOL" "$WIFI_UC"; do
	[ -f "$file" ] && sed -i "s/ssid '.*'/ssid '$WRT_SSID'/g; s/key '.*'/key '$WRT_WORD'/g" "$file"
done

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#引入私有扩展配置
if [ -f "$GITHUB_WORKSPACE/Config/PRIVATE.txt" ]; then
	echo "Applying private configurations from PRIVATE.txt..."
	cat $GITHUB_WORKSPACE/Config/PRIVATE.txt >> ./.config
fi

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

#高通平台调整
DTS_PATH="./target/linux/qualcommax/dts/"
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
	#无WIFI配置调整Q6大小
	if [[ "$WRT_WIFI" == "WIFI-NO" ]]; then
		find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
		echo "qualcommax set up nowifi successfully!"
	fi
fi

#强制启用busybox devmem(帧转发引擎/超频PLL需读物理内存)
#根因: make defconfig 会按 Config-defaults.in 的默认值重置所有 CONFIG_BUSYBOX_* applet,
#直接写 .config 里的 CONFIG_BUSYBOX_CONFIG_DEVMEM=y 会被覆盖为n, 故需改上游默认 BUSYBOX_DEFAULT_DEVMEM 为y
BB_DEF="./package/utils/busybox/Config-defaults.in"
if [ -f "$BB_DEF" ]; then
	sed -i '/^config BUSYBOX_DEFAULT_DEVMEM$/{n;n;s/^\([[:space:]]*\)default n$/\1default y/}' "$BB_DEF"
	echo "busybox devmem enabled (BUSYBOX_DEFAULT_DEVMEM=y)"
fi

#关闭 nginx 80->https 强制跳转(http 可正常访问 LuCI)
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/zz-nginx-http <<'INNER'
#!/bin/sh
[ -f /etc/config/nginx ] || exit 0
if uci -q get nginx._redirect2ssl >/dev/null 2>&1; then
	uci -q delete nginx._redirect2ssl
fi
if ! uci -q get nginx._lan.listen 2>/dev/null | grep -qx '80'; then
	uci -q add_list nginx._lan.listen='80'
fi
if ! uci -q get nginx._lan.listen 2>/dev/null | grep -qx '\[::\]:80'; then
	uci -q add_list nginx._lan.listen='[::]:80'
fi
if [ -n "$(uci -q changes nginx)" ]; then
	uci -q commit nginx
	/etc/init.d/nginx restart >/dev/null 2>&1 || true
fi
exit 0
INNER
chmod +x files/etc/uci-defaults/zz-nginx-http

#关闭 nginx 绝对重定向, 保留外网端口转发场景下的端口号
#根因: 包内 conf.d/luci.locations 写的是相对跳转 `return 302 /cgi-bin/luci/;`,
#     nginx 默认 absolute_redirect=on 会把它补成绝对 URL, 主机名取 Host 头(不含端口),
#     端口则取本机监听端口(80), 于是 WAN 8088->80 转发访问时被跳到 http://<外网IP>/cgi-bin/luci/,
#     8088 丢失后连接被墙/无监听 -> 打不开
#修复: 关闭绝对重定向, Location 保持相对, 浏览器按原地址(含 8088)继续请求
#位置: uci.conf 第 ~50 行在 http 上下文 include conf.d/*.conf, 故用 .conf 后缀对全部 server 生效
mkdir -p files/etc/nginx/conf.d
cat > files/etc/nginx/conf.d/00-absolute_redirect.conf <<'INNER'
# keep Location relative, so an external port (e.g. WAN 8088 -> 80) is not dropped
absolute_redirect off;
INNER

#restrict_locally 拒绝访问(403)时返回可读说明页, 白名单限制本身不变
#判断方法写进页面: 内网可开、外网返回 403 -> 即被 /etc/nginx/restrict_locally 拦截
mkdir -p files/www
cat > files/www/403-locally.html <<'INNER'
<!DOCTYPE html>
<html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>403 访问受限</title></head>
<body style="font-family:system-ui,'Microsoft YaHei',sans-serif;max-width:640px;margin:64px auto;padding:0 20px;line-height:1.9;color:#333">
<h2 style="margin:0 0 4px">403 · 访问受限</h2>
<p style="color:#888;font-size:13px;margin:0 0 20px">当前来源地址不在 nginx 白名单内，管理界面只允许内网访问。</p>
<p><b>怎么判断是这个问题：</b>内网 http://192.168.2.1 能正常打开，而通过公网 IP 加端口访问返回 403，
就是 /etc/nginx/restrict_locally 里的 allow/deny 规则拦下的（不是密码错，也不是端口没通）。</p>
<p><b>怎么处理：</b></p>
<ol>
<li>平时用内网地址访问，或通过 Tailscale / WireGuard 回家后再访问；</li>
<li>确实要从外网直连：编辑 /etc/nginx/restrict_locally，在 deny all; 之前加一行
<code style="background:#eee;padding:1px 5px">allow 你的公网IP;</code>，保存后执行
<br><code style="background:#eee;padding:1px 5px">nginx -t -c /etc/nginx/uci.conf &amp;&amp; /etc/init.d/nginx reload</code></li>
</ol>
<p style="color:#aaa;font-size:12px;margin-top:28px">ImmortalWrt · nginx 1.30.5</p>
</body></html>
INNER

cat > files/etc/nginx/conf.d/99-locally-403.locations <<'INNER'
# restrict_locally 拒绝访问时返回说明页（allow/deny 规则本身不变）
error_page 403 =403 /403-locally.html;
location = /403-locally.html {
	allow all;
	internal;
}
INNER

#打开 xtables / ipset 内核开关(mwan3 依赖链需要; mwan3 本体不编, 由用户自行安装)
#根因: target/linux/generic/config-6.18 里 NETFILTER_XTABLES / IP_NF_IPTABLES /
#     IP6_NF_IPTABLES / IP_SET 都是 "# ... is not set", 于是 kmod-ipt-core、
#     kmod-ip6tables、kmod-ipt-ipset、kmod-nft-compat 在 menuconfig 里全部不可选,
#     LuCI 软件包页会显示"不可用/所有仓库都未提供"
#做法: 在 airoha 的 target config 里覆盖为 =y; 统一走 iptables-nft 后端(与 fw4 的 nf_tables 同栈),
#     不开 iptables-legacy(legacy ip_tables 与 nft 并行会更重, 也无必要)
AIROHA_KCFG="./target/linux/airoha/config-6.18"
if [[ "${WRT_TARGET^^}" == *AIROHA* ]] && [ -f "$AIROHA_KCFG" ]; then
	for kv in CONFIG_NETFILTER_XTABLES CONFIG_IP_NF_IPTABLES CONFIG_IP6_NF_IPTABLES CONFIG_IP_SET; do
		if grep -q "^${kv}=" "$AIROHA_KCFG"; then
			sed -i "s|^${kv}=.*|${kv}=y|" "$AIROHA_KCFG"
		elif grep -q "^# ${kv} is not set" "$AIROHA_KCFG"; then
			sed -i "s|^# ${kv} is not set|${kv}=y|" "$AIROHA_KCFG"
		else
			echo "${kv}=y" >> "$AIROHA_KCFG"
		fi
	done
	echo "xtables/ipset kernel options enabled (mwan3 dependencies)"
fi

#移植 AN7581 PPE IPv6 PPPoE 硬件流卸载修复(931，依赖上游已有的 930 L2B 布局修复)
#根因: L3 IPv6 路由报文在 foe_flow 查不到时无条件跌入 l2_lookup -> 被当成 L2 子流提交,
#      src_mac_hi 被 0xf 抹掉 PPPoE Session ID, PSE_PORT 又被改写为 6(NPU) -> 硬件管线死锁,
#      IPv6 下行从满速跌到几十 KB/s (阿里 CDN/夸克网盘等 br-lan 下行场景)
#保护: 补丁经 target/linux/airoha/patches-6.18 的 quilt 序列自动应用, 上下文不匹配会在
#      kernel prepare 阶段直接报错中止编译, 不会带病出包
PATCH_SRC="$GITHUB_WORKSPACE/Scripts/patches/931-net-airoha-fix-wan-ipv6-pppoe-flow-offload.patch"
PATCH_DIR="./target/linux/airoha/patches-6.18"
PATCH_NAME="931-net-airoha-fix-wan-ipv6-pppoe-flow-offload.patch"
if [[ "${WRT_TARGET^^}" == *AIROHA* ]] && [ -f "$PATCH_SRC" ] && [ -d "$PATCH_DIR" ]; then
	if [ -f "$PATCH_DIR/$PATCH_NAME" ]; then
		echo "airoha 931 patch already present upstream, skip"
	else
		for token in "PPE_PKT_TYPE_IPV6_ROUTE_3T" "AIROHA_FOE_MAC_PPPOE_ID" "l2_lookup:" "WAN_MTU1_MASK"; do
			grep -q "$token" "$PATCH_SRC" || { echo "ERROR: 931 patch incomplete (missing $token)"; exit 1; }
		done
		cp -f "$PATCH_SRC" "$PATCH_DIR/$PATCH_NAME"
		echo "airoha 931 IPv6 PPPoE PPE offload fix installed"
	fi
fi

#airoha: 兜底确保 /dev/mem 节点存在(内核 DEVMEM 打开后 /sys/class/mem/mem 才会出现,
#正常由 procd/mdev 自动建节点, 这里只在内核已注册但节点缺失时手动补)
if [[ "${WRT_TARGET^^}" == *AIROHA* ]]; then
	mkdir -p files/etc/uci-defaults
	cat > files/etc/uci-defaults/zz-airoha-devmem <<'INNER'
#!/bin/sh
[ -e /dev/mem ] && exit 0
[ -e /sys/class/mem/mem/dev ] || exit 0
mknod /dev/mem c 1 1 2>/dev/null && chmod 640 /dev/mem
exit 0
INNER
	chmod +x files/etc/uci-defaults/zz-airoha-devmem
fi
