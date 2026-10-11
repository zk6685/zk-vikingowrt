#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

#安装和更新软件包
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local PKG_LIST=("$PKG_NAME" $5)  # 第5个参数为自定义名称列表
	local REPO_NAME=${PKG_REPO#*/}
	local REPO_PATH="./package/$REPO_NAME"

	echo " "

	# 删除本地可能存在的不同名称的软件包
	for NAME in "${PKG_LIST[@]}"; do
		# 查找匹配的目录
		echo "Search directory: $NAME"
		local FOUND_DIRS=$(find ./feeds/luci/ ./feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" 2>/dev/null)

		# 删除找到的目录
		if [ -n "$FOUND_DIRS" ]; then
			while read -r DIR; do
				rm -rf "$DIR"
				echo "Delete directory: $DIR"
			done <<< "$FOUND_DIRS"
		else
			echo "Not fonud directory: $NAME"
		fi
	done

	# 克隆 GitHub 仓库
	git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git" $REPO_PATH

	# 处理克隆的仓库
	if [[ "$PKG_SPECIAL" == "pkg" ]]; then
		# pkg 模式：仓库可能为多包结构，提取含包名的子目录到 ./package/。
		# 先把 clone 仓库移到临时目录，避免提取的子目录与 clone 目标同名时 cp 嵌套覆盖
		# （如 argon/quickfile 等仓库根目录与包同名，导致根包未注册、编译期依赖缺失）
		local TMPDIR="./package/.$REPO_NAME-src"
		mv "$REPO_PATH" "$TMPDIR" 2>/dev/null
		find "$TMPDIR" -mindepth 1 -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./package \;
		rm -rf "$TMPDIR"
	fi
}

#从 kenzok8/small-package 一次性提取多个指定包到 ./package/（避免多次 clone 大仓库）
SMALLPKG() {
	local PKGS="$1"
	local REPO_PATH="./package/small-package"
	#删除 feeds 中可能与提取包冲突的同名包
	for NAME in $PKGS; do
		find ./feeds/luci/ ./feeds/packages/ -maxdepth 4 -type d -iname "*$NAME*" -exec rm -rf {} \; 2>/dev/null
	done
	git clone --depth=1 --single-branch --branch main "https://github.com/kenzok8/small-package.git" $REPO_PATH
	for NAME in $PKGS; do
		cp -rf $REPO_PATH/$NAME ./package/ 2>/dev/null
	done
	rm -rf $REPO_PATH
}

# 调用示例
# UPDATE_PACKAGE "OpenAppFilter" "destan19/OpenAppFilter" "master" "" "custom_name1 custom_name2"
# UPDATE_PACKAGE "open-app-filter" "destan19/OpenAppFilter" "master" "" "luci-app-appfilter oaf" 这样会把原有的open-app-filter，luci-app-appfilter，oaf相关组件删除，不会出现coremark错误。

# UPDATE_PACKAGE "包名" "项目地址" "项目分支" "pkg，可选，从大杂烩中单独提取包名插件"
# argon 仓库为多包结构(luci-theme-argon + luci-app-argon-config)，用 pkg 模式一次性提取全部 argon 相关包到 ./package/
UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "openwrt-25.12" "pkg"
UPDATE_PACKAGE "aurora" "eamonxg/luci-theme-aurora" "master"
UPDATE_PACKAGE "aurora-config" "eamonxg/luci-app-aurora-config" "master"
UPDATE_PACKAGE "fluent" "LazuliKao/luci-theme-fluent" "main"
UPDATE_PACKAGE "footstrap" "VizzleTF/luci-theme-footstrap" "main"
UPDATE_PACKAGE "kucat" "sirpdboy/luci-theme-kucat" "master"
UPDATE_PACKAGE "kucat-config" "sirpdboy/luci-app-kucat-config" "master"
UPDATE_PACKAGE "shadcn" "eamonxg/luci-theme-shadcn" "main"

UPDATE_PACKAGE "momo" "nikkinikki-org/OpenWrt-momo" "main"
UPDATE_PACKAGE "nikki" "nikkinikki-org/OpenWrt-nikki" "main"
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"
UPDATE_PACKAGE "passwall" "Openwrt-Passwall/openwrt-passwall" "main" "pkg"
UPDATE_PACKAGE "passwall2" "Openwrt-Passwall/openwrt-passwall2" "main" "pkg"

UPDATE_PACKAGE "diskmanager" "4IceG/luci-app-mini-diskmanager" "main"
UPDATE_PACKAGE "easytier" "EasyTier/luci-app-easytier" "main"
UPDATE_PACKAGE "qmodem" "FUjr/QModem" "main"
UPDATE_PACKAGE "viking" "VIKINGYFY/packages" "main" "" "axonhub gecoosac sing-box luci-app-homeproxy luci-app-timewol luci-app-wolplus luci-app-wolultra"
UPDATE_PACKAGE "vnt" "lmq8267/luci-app-vnt" "main"

UPDATE_PACKAGE "diskman" "sbwml/luci-app-diskman" "main"
UPDATE_PACKAGE "mosdns" "sbwml/luci-app-mosdns" "v5" "" "v2dat"
UPDATE_PACKAGE "openlist2" "sbwml/luci-app-openlist2" "main"
UPDATE_PACKAGE "qbittorrent" "sbwml/luci-app-qbittorrent" "master" "" "qt6base qt6tools rblibtorrent"
UPDATE_PACKAGE "quickfile" "sbwml/luci-app-quickfile" "main" "pkg" "luci-app-quickfile quickfile"

UPDATE_PACKAGE "ddns-go" "sirpdboy/luci-app-ddns-go" "main"
UPDATE_PACKAGE "netspeedtest" "sirpdboy/netspeedtest" "main" "" "homebox ookla-speedtest"
UPDATE_PACKAGE "netwizard" "sirpdboy/luci-app-netwizard" "main"
UPDATE_PACKAGE "partexp" "sirpdboy/luci-app-partexp" "main"
UPDATE_PACKAGE "timecontrol" "sirpdboy/luci-app-timecontrol" "main"

UPDATE_PACKAGE "natmapt" "muink/openwrt-natmapt" "master"
UPDATE_PACKAGE "stuntman" "muink/openwrt-stuntman" "master"
UPDATE_PACKAGE "luci-app-natmapt" "muink/luci-app-natmapt" "master"

UPDATE_PACKAGE "airpi3000m-fancontrol" "LianXia233/luci-app-airpi3000m-fancontrol" "main"
UPDATE_PACKAGE "chfs" "LianXia233/luci-app-chfs" "main"
UPDATE_PACKAGE "fm350" "LianXia233/luci-app-fm350" "main"
UPDATE_PACKAGE "h5000m-netmode" "LianXia233/luci-app-h5000m-netmode" "main"
UPDATE_PACKAGE "mt5700" "LianXia233/luci-app-mt5700" "main"
UPDATE_PACKAGE "mt5700m" "LianXia233/luci-app-mt5700m" "main"
UPDATE_PACKAGE "netmonitor" "LianXia233/luci-app-netmonitor" "main"
UPDATE_PACKAGE "qmodem-generic" "LianXia233/luci-app-qmodem-generic" "main"

#daede(istore整合管理界面) + dae + daed，改用 kenzok8/small-package
SMALLPKG "luci-app-daede dae daed"
#istore 商店 + istorex 首页及其依赖（均来自 small-package；补 quickstart/luci-lib-xterm 以满足 luci-app-quickstart 与 luci-lib-taskd 的依赖）
SMALLPKG "luci-app-istorex luci-app-store luci-app-quickstart luci-lib-taskd luci-lib-iform taskd quickstart luci-lib-xterm"
# quickstart 温度修复：替换 istore_backend.lua，为 /istore/system/status/ 响应注入 cpuTemperature（读 /sys/class/thermal/thermal_zone0/temp）
cat > ./package/luci-app-quickstart/luasrc/controller/istore_backend.lua <<'LUAEOF'
-- Copyright 2022 xiaobao <xiaobao@linkease.com>
-- Licensed to the public under the MIT License

local http = require "luci.http"
local nixio = require "nixio"
local ltn12 = require "luci.ltn12"
local table = require "table"
local util = require "luci.util"

module("luci.controller.istore_backend", package.seeall)

local BLOCKSIZE = 2048
local ISTOREOS_PORT = 3038

function index()
    entry({"istore"}, call("istore_backend")).leaf=true
end

local function sink_socket(sock, io_err)
  if sock then
    return function(chunk, err)
      if not chunk then
        return 1
      else
        return sock:send(chunk)
      end
    end
  else
    return ltn12.sink.error(io_err or "unable to send socket")
  end
end

local function session_retrieve(sid, allowed_users)
  local sdat = util.ubus("session", "get", { ubus_rpc_session = sid })
  if type(sdat) == "table" and
      type(sdat.values) == "table" and
      type(sdat.values.token) == "string" and
      (not allowed_users or
      util.contains(allowed_users, sdat.values.username))
  then
      return sid, sdat.values
  end
  return nil, nil
end

local function get_session()
  local sid
  local key
  local sdat
  for _, key in ipairs({"sysauth_https", "sysauth_http", "sysauth"}) do
    sid = http.getcookie(key)
    if sid then
      sid, sdat = session_retrieve(sid, nil)
      if sid and sdat then
        return sid, sdat
      end
    end
  end
  return nil, nil
end

local function chunksource(sock, buffer)
        buffer = buffer or ""
        return function()
                local output
                local _, endp, count = buffer:find("^([0-9a-fA-F]+);?.-\r\n")
                while not count and #buffer <= 1024 do
                        local newblock, code = sock:recv(1024 - #buffer)
                        if not newblock then
                                return nil, code
                        end
                        buffer = buffer .. newblock
                        _, endp, count = buffer:find("^([0-9a-fA-F]+);?.-\r\n")
                end
                count = tonumber(count, 16)
                if not count then
                        return nil, -1, "invalid encoding"
                elseif count == 0 then
                        return nil
                elseif count + 2 <= #buffer - endp then
                        output = buffer:sub(endp+1, endp+count)
                        buffer = buffer:sub(endp+count+3)
                        return output
                else
                        output = buffer:sub(endp+1, endp+count)
                        buffer = ""
                        if count - #output > 0 then
                                local remain, code = sock:recvall(count-#output)
                                if not remain then
                                        return nil, code
                                end
                                output = output .. remain
                                count, code = sock:recvall(2)
                        else
                                count, code = sock:recvall(count+2-#buffer+endp)
                        end
                        if not count then
                                return nil, code
                        end
                        return output
                end
        end
end

local function get_cpu_temperature()
  local temp_file = io.open("/sys/class/thermal/thermal_zone0/temp", "r")
  if temp_file then
    local temp = temp_file:read("*n")
    temp_file:close()
    if temp then
      return math.floor(temp / 1000)
    end
  end
  return 0
end

function istore_backend()
  -- 检查是否为 system/status 请求
  local uri = http.getenv("REQUEST_URI")
  local is_status_request = string.match(uri, "/istore/system/status/")

  local sock = nixio.connect("127.0.0.1", ISTOREOS_PORT)
  if not sock then
    http.status(500, "connect failed")
    return
  end
  local input = {}
  input[#input+1] = http.getenv("REQUEST_METHOD") .. " " .. http.getenv("REQUEST_URI") .. " HTTP/1.1"
  local req = http.context.request
  local start = "HTTP_"
  local start_len = string.len(start)
  local ctype = http.getenv("CONTENT_TYPE")
  if ctype then
    input[#input+1] = "Content-Type: " .. ctype
  end
  for k, v in pairs(req.message.env) do
    if string.sub(k, 1, start_len) == start and not string.find(k, "FORWARDED") then
      input[#input+1] = string.sub(k, start_len+1, string.len(k)) .. ": " .. v
    end
  end
  local sid, sdat = get_session()
  if sdat ~= nil then
    input[#input+1] = "X-Forwarded-Sid: " .. sid
    input[#input+1] = "X-Forwarded-Token: " .. sdat.token
  end
  local num = tonumber(http.getenv("CONTENT_LENGTH")) or 0
  input[#input+1] = "Content-Length: " .. tostring(num)
  input[#input+1] = "\r\n"
  local source = ltn12.source.cat(ltn12.source.string(table.concat(input, "\r\n")), http.source())
  local ret = ltn12.pump.all(source, sink_socket(sock, "write sock error"))
  if ret ~= 1 then
    sock:close()
    http.status(500, "proxy error")
    return
  end

  local linesrc = sock:linesource()
  local line, code, error = linesrc()
  if not line then
    sock:close()
    http.status(500, "response parse failed")
    return
  end

  local protocol, status, msg = line:match("^([%w./]+) ([0-9]+) (.*)")
  if not protocol then
    sock:close()
    http.status(500, "response protocol error")
    return
  end
  num = tonumber(status) or 0
  http.status(num, msg)

  local chunked = 0
  line = linesrc()
  while line and line ~= "" do
    local key, val = line:match("^([%w-]+)%s?:%s?(.*)")
    if key and key ~= "Status" then
      if key == "Transfer-Encoding" and val == "chunked" then
        chunked = 1
      end
      if key ~= "Connection" and key ~= "Transfer-Encoding" and key ~= "Content-Length" then
        http.header(key, val)
      end
    end
    line = linesrc()
  end
  if not line then
    sock:close()
    http.status(500, "parse header failed")
    return
  end

  local body_buffer = linesrc(true)
  if chunked == 1 then
    if is_status_request then
      -- 收集所有数据
      local chunks = {}
      local source = chunksource(sock, body_buffer)
      local chunk
      repeat
        chunk = source()
        if chunk then
          table.insert(chunks, chunk)
        end
      until not chunk

      -- 修改 JSON
      local json = table.concat(chunks)
      local cpu_temp = get_cpu_temperature()
      local modified_json = json:gsub('"result":{', string.format('"result":{"cpuTemperature":%d,', cpu_temp))

      -- 发送修改后的数据
      http.write(modified_json)
    else
      ltn12.pump.all(chunksource(sock, body_buffer), http.write)
    end
  else
    if is_status_request then
      -- 收集所有数据
      local chunks = {}
      local body_source = ltn12.source.cat(ltn12.source.string(body_buffer), sock:blocksource())
      local sink = ltn12.sink.table(chunks)
      ltn12.pump.all(body_source, sink)

      -- 修改 JSON
      local json = table.concat(chunks)
      local cpu_temp = get_cpu_temperature()
      local modified_json = json:gsub('"result":{', string.format('"result":{"cpuTemperature":%d,', cpu_temp))

      -- 发送修改后的数据
      http.write(modified_json)
    else
      local body_source = ltn12.source.cat(ltn12.source.string(body_buffer), sock:blocksource())
      ltn12.pump.all(body_source, http.write)
    end
  end

  sock:close()
end
LUAEOF
# libdaemon 修复：当前 owrt snapshot 的 feeds 中 libdaemon 包注册异常（avahi 等依赖它导致编译失败），
# 从 immortalwrt/packages master 拉取正常 Makefile 放到 ./package/，并删除 feeds 中的异常目录
rm -rf ./feeds/packages/libs/libdaemon
mkdir -p ./package/libdaemon
curl -fsSL "https://raw.githubusercontent.com/immortalwrt/packages/master/libs/libdaemon/Makefile" -o ./package/libdaemon/Makefile
# daed 处理：删除 daed 对不存在的 vmlinux-btf 的条件依赖；并在 daed install 段追加软链，
# 把 v2ray 的 geoip.dat/geosite.dat 装入 /usr/share/daed/。
# (luci-app-daede 依赖 dae/daed，其 DEPENDS 不含 daed-geoip/daed-geosite，无需 sed 处理)
python3 <<'PYEOF'
import re
p='./package/daed/Makefile'
s=open(p).read()
# 删除 "+@KERNEL_XDP_SOCKETS \" 续行到 "vmlinux-btf" 的条件依赖整段
s=re.sub(r'\s*\+@KERNEL_XDP_SOCKETS\s*\\\r?\n\s*\+DAED_USE_VMLINUX_BTF:vmlinux-btf\r?\n','\n',s)
# 兜底：删除任何残留的 vmlinux-btf 依赖行
s=re.sub(r'^.*vmlinux-btf.*\r?\n','',s,flags=re.M)
# 清理删除后 DEPENDS 末尾遗留的悬空续行符（\ 后接空行）
s=re.sub(r'\+v2ray-geosite\s*\\\r?\n','+v2ray-geosite\n',s)
# install 段末尾追加 geoip/geosite 软链（把 v2ray 的数据软链进 daed 目录）
s=s.replace('$(INSTALL_DATA) $(CURDIR)/files/daed.keep $(1)/lib/upgrade/keep.d/daed\nendef',
            '$(INSTALL_DATA) $(CURDIR)/files/daed.keep $(1)/lib/upgrade/keep.d/daed\n\t$(LN) ../v2ray/geoip.dat $(1)/usr/share/daed/geoip.dat\n\t$(LN) ../v2ray/geosite.dat $(1)/usr/share/daed/geosite.dat\nendef')
open(p,'w').write(s)
print("daed patched")
PYEOF
UPDATE_PACKAGE "clouddrive2" "xuanranran/openwrt-clouddrive2" "master"

#更新软件包版本
UPDATE_VERSION() {
	local PKG_NAME=$1
	local PKG_MARK=${2:-false}
	local PKG_FILES=$(find ./ ./feeds/packages/ -maxdepth 3 -type f -wholename "*/$PKG_NAME/Makefile")

	if [ -z "$PKG_FILES" ]; then
		echo "$PKG_NAME not found!"
		return
	fi

	echo -e "\n$PKG_NAME version update has started!"

	for PKG_FILE in $PKG_FILES; do
		local PKG_REPO=$(grep -Po "PKG_SOURCE_URL:=https://.*github.com/\K[^/]+/[^/]+(?=.*)" $PKG_FILE)
		local PKG_TAG=$(curl -sL "https://api.github.com/repos/$PKG_REPO/releases" | jq -r "map(select(.prerelease == $PKG_MARK)) | first | .tag_name")

		local OLD_VER=$(grep -Po "PKG_VERSION:=\K.*" "$PKG_FILE")
		local OLD_URL=$(grep -Po "PKG_SOURCE_URL:=\K.*" "$PKG_FILE")
		local OLD_FILE=$(grep -Po "PKG_SOURCE:=\K.*" "$PKG_FILE")
		local OLD_HASH=$(grep -Po "PKG_HASH:=\K.*" "$PKG_FILE")

		local PKG_URL=$([[ "$OLD_URL" == *"releases"* ]] && echo "${OLD_URL%/}/$OLD_FILE" || echo "${OLD_URL%/}")

		local NEW_VER=$(echo $PKG_TAG | sed -E 's/[^0-9]+/\./g; s/^\.|\.$//g')
		local NEW_URL=$(echo $PKG_URL | sed "s/\$(PKG_VERSION)/$NEW_VER/g; s/\$(PKG_NAME)/$PKG_NAME/g")
		local NEW_HASH=$(curl -sL "$NEW_URL" | sha256sum | cut -d ' ' -f 1)

		echo "old version: $OLD_VER $OLD_HASH"
		echo "new version: $NEW_VER $NEW_HASH"

		if [[ "$NEW_VER" =~ ^[0-9].* ]] && dpkg --compare-versions "$OLD_VER" lt "$NEW_VER"; then
			sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" "$PKG_FILE"
			sed -i "s/PKG_HASH:=.*/PKG_HASH:=$NEW_HASH/g" "$PKG_FILE"
			echo "$PKG_FILE version has been updated!"
		else
			echo "$PKG_FILE version is already the latest!"
		fi
	done
}

#UPDATE_VERSION "软件包名" "测试版，true，可选，默认为否"
#UPDATE_VERSION "sing-box"

#引入私有扩展脚本
if [ -f "$GITHUB_WORKSPACE/Scripts/PRIVATE.sh" ]; then
	source "$GITHUB_WORKSPACE/Scripts/PRIVATE.sh"
fi
