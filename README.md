# zk-vikingwrt

自用 OpenWrt / ImmortalWrt 云编译仓库。基于 [VIKINGYFY/OpenWRT-CI](https://github.com/VIKINGYFY/OpenWRT-CI) 模板改造，源码取自 [VIKINGYFY/immortalwrt](https://github.com/VIKINGYFY/immortalwrt) 的 `owrt` 分支，由 GitHub Actions 全自动编译，主线为 Airoha AN7581 / AN7583 光猫类设备（Nokia XG-040G-MD、FiberHome HG5585F-CT 等）。

## 编译说明

### 触发方式

- **自动**：`Auto-Clean` 运行完成后，自动拉起 `AIROHA-ALL` 编译。
- **手动**：进入 Actions，选择目标 workflow，点击 **Run workflow**，有两个可选参数：
  - `PACKAGE`：追加编译配置。内容会原样写入 `.config`，因此要写完整行，多个用 `\n` 分隔，例如 `CONFIG_PACKAGE_luci-app-dockerman=y`。
  - `TEST`：勾选后只生成并上传配置文件，不编译固件，用于快速验证配置是否合法。

### 编译矩阵

| Workflow | 覆盖平台 / 用途 |
| --- | --- |
| `AIROHA-ALL` | Airoha AN7581、AN7583（主线） |
| `MTK-ALL` | MediaTek 系列 |
| `QCA-ALL` | Qualcomm IPQ 系列 |
| `QCB-ALL` | Qualcomm 其他系列 |
| `OWRT-ALL` | 其余平台合集 |
| `WRT-TEST` | 配置测试 |
| `WRT-CORE` | 公共编译核心，被以上 workflow 调用 |
| `Auto-Clean` / `Cache-Clean` | 缓存与旧产物清理 |

### 配置与脚本

| 位置 | 作用 |
| --- | --- |
| `Config/<机型>.txt` | 单机型配置，如 `AIROHA-AN7581.txt` |
| `Config/GENERAL.txt` | 通用配置，在机型配置**之后**追加，优先级更高 |
| `Scripts/Packages.sh` | 拉取第三方插件源码到编译目录（只决定“有哪些源码”，不决定“编不编”） |
| `Scripts/Handles.sh` | 对主题、插件做源码级修补 |
| `Scripts/Settings.sh` | 默认主题、主机名、IP、WiFi、编译日期标识等定制 |

编译时的配置组装顺序：

1. `cat Config/<机型>.txt Config/GENERAL.txt >> .config`（`TEST` 配置只读自身）
2. 执行 `Scripts/Settings.sh`，追加主题、LuCI、自定义插件等
3. `make defconfig && make clean`
4. 补写 `CONFIG_BUSYBOX_CONFIG_DEVMEM=y`（`defconfig` 会把该隐藏项重置为 `n`）
5. 下载依赖并编译，打包上传

### 产物

- Release tag：`<配置>-<源码仓库>-<分支>-<编译时间>`，例如 `AIROHA-AN7581-VIKINGYFY-owrt-26.11.04-21.55.12`
- 固件文件名：`zk-daepon-<target>-<device>-<镜像类型>-<源码>-<分支>-<WIFI>-<日期>.<扩展名>`
- 每次编译同时上传 `Config-*.txt`，可据此核对实际生效的配置

## 机型支持清单

`ALL_PROFILES` 表示该 target 下上游支持的全部设备一次性出包；`WIFI-YES` / `WIFI-NO` 为同一套设备定义，差别只在是否编入无线驱动与固件包。

| 平台 | 配置文件 | target / subtarget | 机型数 |
| --- | --- | --- | --- |
| Airoha | `AIROHA-AN7581` | `airoha/an7581` | 全量（`ALL_PROFILES`） |
| Airoha | `AIROHA-AN7583` | `airoha/an7583` | 全量（`ALL_PROFILES`） |
| Qualcomm | `IPQ53XX` | `qualcommbe/ipq53xx` | 5 |
| Qualcomm | `IPQ60XX-WIFI-YES` / `-NO` | `qualcommax/ipq60xx` | 13 |
| Qualcomm | `IPQ807X-WIFI-YES` / `-NO` | `qualcommax/ipq807x` | 12 |
| Qualcomm | `IPQ95XX` | `qualcommbe/ipq95xx` | 6 |
| MediaTek | `MEDIATEK-WIFI-YES` | `mediatek/filogic` | 70 |
| MediaTek | `MEDIATEK-WIFI-NO` | `mediatek/filogic` | 4 |
| Rockchip | `ROCKCHIP` | `rockchip/armv8` | 26 |
| x86 | `X86` | `x86/64` | 全量（`ALL_PROFILES`） |
| 测试 | `TEST` | `qualcommax/ipq50xx` | 1 |

### Airoha（主线）

- `AIROHA-AN7581`：`airoha/an7581` 全部设备，固件内置 `luci-app-airoha-npu`（芯片状态页）
- `AIROHA-AN7583`：`airoha/an7583` 全部设备，同上
- 已实测出包机型：Nokia XG-040G-MD、FiberHome HG5585F-CT

### Qualcomm IPQ53xx（5 款）

```text
jdcloud_re-cs-06 jdcloud_re-cs-08 xiaomi_be3600-pro-wired-p5 xiaomi_be3600-pro-wired-p8 xiaomi_be6500
```

### Qualcomm IPQ60xx（13 款）

```text
qihoo_360v6 anysafe_e1 cmiot_ax18 dptech_ap3000-2c glinet_gl-ax1800 glinet_gl-axt1800
link_nn6000-v1 link_nn6000-v2 linksys_mr7350 linksys_mr7500 redmi_ax5 xiaomi_ax1800
zn_m2
```

### Qualcomm IPQ807x（12 款）

```text
aliyun_ap8220 dynalink_dl-wrx36 linksys_homewrk linksys_mx4300 qnap_301w redmi_ax6
redmi_ax6-stock verizon_cr1000a xiaomi_ax3600 xiaomi_ax3600-stock xiaomi_ax9000 xiaomi_ax9000-stock
```

### Qualcomm IPQ95xx（6 款）

```text
askey_sbe1v1k nokia_beacon10 xiaomi_be7000 xiaomi_be7000-pro xiaomi_be10000 xiaomi_be10000-pro
```

### MediaTek filogic · WIFI-YES（70 款）

```text
abt_asr3000 airpi_ap3000m asus_tuf-ax4200 asus_tuf-ax4200q asus_tuf-ax6000 cetron_ct3003-stock
cetron_ct3003-ubootmod cmcc_a10-stock cmcc_a10-ubootmod cmcc_rax3000m cmcc_rax3000me comfast_cf-e393ax
comfast_cf-wr632ax comfast_cf-wr632ax-ubootmod comfast_cf-xr186 creatlentem_clt-r30b1 creatlentem_clt-r30b1-112m cudy_tr3000-v1
cudy_tr3000-v1-256mb cudy_tr3000-v1-ubootmod glinet_gl-mt3000 glinet_gl-mt3600be glinet_gl-mt6000 glinet_gl-x3000
glinet_gl-xe3000 globitel_bt-r320 h3c_magic-nx30-pro-ubootmod huasifei_wh3000-emmc huasifei_wh3000-pro-emmc huasifei_wh3000-pro-nand
imou_hx21 jcg_q30-pro jdcloud_re-cp-03 konka_komi-a31 netcore_n60 netcore_n60-pro
nokia_ea0326gmp qihoo_360t7 qihoo_360t7-ubi ruijie_rg-x60 ruijie_rg-x60-pro supergateway_s20l
supergateway_s20p tenda_be12-pro tplink_tl-7dr7230-v1 tplink_tl-7dr7230-v2 tplink_tl-7dr7250-v1 tplink_tl-7dr7299-v1
tplink_tl-xdr4288 tplink_tl-xdr6086 tplink_tl-xdr6088 tplink_tl-xtr8488 tplink_wma301-v2-1-256m-ubootmod tplink_wma301-v2-1-ubootmod
tplink_wma301-v2-256m-ubootmod tplink_wma301-v2-ubootmod xiaomi_mi-router-ax3000t-stock xiaomi_mi-router-ax3000t-ubootmod xiaomi_mi-router-wr30u-stock xiaomi_mi-router-wr30u-ubootmod
xiaomi_redmi-router-ax6000-stock xiaomi_redmi-router-ax6000-ubootmod zbtlink_zbt-z8102ax zbtlink_zbt-z8102ax-v2 zbtlink_zbt-z8103ax zbtlink_zbt-z8103ax-c
zbtlink_zbt-z8106ax-s zbtlink_zbt-z8106ax-t zbtlink_zbt-z8803be zyxel_ex5700-telenor
```

### MediaTek filogic · WIFI-NO（4 款）

```text
supergateway_s20l supergateway_s20m supergateway_s20p zyxel_ex5700-telenor
```

### Rockchip armv8（26 款）

```text
ezpro_mrkaio-m68s friendlyarm_nanopc-t4 friendlyarm_nanopc-t6 friendlyarm_nanopi-m5 friendlyarm_nanopi-r2c friendlyarm_nanopi-r2c-plus
friendlyarm_nanopi-r2s friendlyarm_nanopi-r3s friendlyarm_nanopi-r4s friendlyarm_nanopi-r4se friendlyarm_nanopi-r4s-enterprise friendlyarm_nanopi-r5c
friendlyarm_nanopi-r5s friendlyarm_nanopi-r6c friendlyarm_nanopi-r6s friendlyarm_nanopi-r76s linkease_easepi-r1 lunzn_fastrhino-r66s
lunzn_fastrhino-r68s radxa_e20c radxa_e25 radxa_e52c xunlong_orangepi-5 xunlong_orangepi-5-plus
xunlong_orangepi-r1-plus xunlong_orangepi-r1-plus-lts
```

### 其他

- `X86`：`x86/64` 全部 profile，输出 `grub` 与 `vmdk` 镜像，内置 `mt7915/7921/7925` 无线驱动
- `TEST`：`qualcommax/ipq50xx` 的 `cmcc_mr3000d-ci`，仅用于验证配置

## 固件特点

### 基础信息

- 主线机型：Airoha AN7581 / AN7583（`airoha/an7581`、`airoha/an7583`）
- `AIROHA-ALL` 默认主题 `vantage`、主机名 `DAEPON`、管理地址 `192.168.10.1`、WiFi `OWRT` / `12345678`（各 workflow 取值可能不同）

### 关键定制

- **devmem 编入固件**：`Config/GENERAL.txt` 设置 `CONFIG_BUSYBOX_DEFAULT_DEVMEM=y`、`CONFIG_BUSYBOX_CONFIG_DEVMEM=y`，并在 `make defconfig` 之后强制补回 `CONFIG_BUSYBOX_CONFIG_DEVMEM=y`。芯片状态页的帧转发引擎、PSE 队列、PPE、超频 PLL 等寄存器读取都依赖它。
- **关闭 HTTP 到 HTTPS 的强制跳转**：首次启动通过 `/etc/uci-defaults/zz-nginx-http` 删除 nginx 的 `_redirect2ssl` server 段，并把 80 端口并入 `_lan`，`http://` 可直接访问 LuCI；`uhttpd` 的重定向同样保持关闭。
- **不编译 Homeproxy**：`Config/GENERAL.txt` / `Config/TEST.txt` 中 `CONFIG_PACKAGE_luci-app-homeproxy=n`，需要时由用户自行安装（连带 `sing-box` 依赖）。
- **eBPF / BTF 内核**：启用 `CONFIG_KERNEL_DEBUG_INFO_BTF`、`CONFIG_KERNEL_CGROUP_BPF`、`CONFIG_KERNEL_XDP_SOCKETS` 等，作为 dae / honk 的 CO-RE 运行前提；内置 BTF 使内核增大约 7.3 MB，`nn6000` 的内核分区已从 6M 调到 12M，6M 分区的机型未采用该方案。
- **仅内置运行依赖**：dae、honk、clouddrive2 只编入运行依赖（`ca-bundle`、`kmod-sched-bpf`、`jsonfilter`、`sqlite3-cli`、`usign`、`fuse-utils` 等），本体由用户后期自行安装。
- **菜单修补**：`Scripts/Handles.sh` 修正 argon 主题配色、aurora 菜单、vantage 进度条字体，以及 mini-diskmanager、natmapt 的菜单位置。

### 内置组件

- 界面：`luci`、中文语言包、`vantage` 主题、`aurora` 主题及其配置页、iStore（`luci-app-store` + `taskd`）、`ttyd`、`quickfile`
- 插件：`autoreboot`、`gecoosac`、`mini-diskmanager`、`natmapt`、`partexp`、`samba4`、`upnp`
- 内核模块：nftables 全套（含 `kmod-nft-offload`、`kmod-nft-tproxy`）、USB 网卡与存储、`kmod-wireguard`、`kmod-fs-btrfs`、`kmod-fs-ksmbd`、`kmod-dsa`、`kmod-bonding` 等
- 工具：`htop`、`iperf3`、`ip-full`、`curl`、`smartmontools`、`nand-utils`、`nvme-cli`、`zram-swap`、`coremark` 等

### 不编入固件

`luci-app-attendedsysupgrade`、`luci-app-wol`、`luci-app-wolultra`、`luci-app-homeproxy`

## 交流与资源

### 高质量（免费）交流群

[IPQ技术讨论群](https://qm.qq.com/q/v7nMhzB4oU)

### 高质量（付费）中转站

[LiBwrt-Ai](https://api.zipimg.cn/register?aff=FFPS3UMJ8HJD)

## 相关仓库与工具

### 本地编译器

https://github.com/VIKINGYFY/OWRT-Tools.git

### 自用修改版插件

https://github.com/VIKINGYFY/packages.git

### OpenWRT-CI 源码

官方版：

https://github.com/immortalwrt/immortalwrt.git

自用版：

https://github.com/VIKINGYFY/immortalwrt.git

### U-BOOT

高通版-沉心：

https://github.com/chenxin527/uboot-qsdk12.5-build.git

高通版-小猪：

https://github.com/1980490718/u-boot-2016.git

联发科-全新版：

https://github.com/VIKINGYFY/UBOOT-CI/releases

联发科-官方版：

https://drive.wrt.moe/uboot/mediatek

## 固件简要说明

固件每天早上5点自动编译。

固件信息里的时间为编译开始的时间，方便核对上游源码提交时间。

MEDIATEK系列、QUALCOMMAX系列、ROCKCHIP系列、X86系列。

## 目录简要说明

- `workflows`——自定义 CI 配置，各平台编译入口与公共编译核心
- `Scripts`——自定义脚本，插件拉取、源码修补与固件定制
- `Config`——自定义配置，各机型编译配置，`GENERAL.txt` 为通用基底

## Star History

<a href="https://www.star-history.com/?repos=vikingyfy%2Fopenwrt-ci&type=date&legend=top-left">
 <picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=vikingyfy/openwrt-ci&type=date&theme=dark&legend=top-left" />
  <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=vikingyfy/openwrt-ci&type=date&legend=top-left" />
  <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=vikingyfy/openwrt-ci&type=date&legend=top-left" />
 </picture>
</a>
