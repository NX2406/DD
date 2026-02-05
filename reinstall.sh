#!/bin/bash
#
# DD Reinstall Script - 一键DD重装系统脚本
# 支持 Debian/Ubuntu/CentOS/AlmaLinux/RockyLinux/Fedora/Alpine/Windows
# 自动检测地区，国内使用清华/阿里/腾讯镜像源，国外使用官方源
#
# GitHub: https://github.com/YOUR_USERNAME/dd-reinstall
# License: MIT
#

set -e

# ==================== 版本信息 ====================
VERSION="1.0.0"
SCRIPT_NAME="DD Reinstall Script"

# ==================== 颜色定义 ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ==================== 全局变量 ====================
REGION=""           # 地区: cn (中国大陆) | overseas (海外)
ARCH=""             # 架构: x86_64 | aarch64
BOOT_MODE=""        # 引导模式: bios | efi
DISTRO=""           # 发行版
VERSION_ID=""       # 版本号
PASSWORD=""         # root 密码
SSH_KEY=""          # SSH 公钥
SSH_PORT="22"       # SSH 端口
MIRROR=""           # 镜像源: auto | cn | overseas
DD_URL=""           # DD 镜像 URL (用于 Windows)
INTERFACE=""        # 网络接口
IP_ADDR=""          # IP 地址
GATEWAY=""          # 网关
NETMASK=""          # 子网掩码
DNS1="8.8.8.8"      # DNS 1
DNS2="8.8.4.4"      # DNS 2
FORCE_MODE=false    # 强制模式
DRY_RUN=false       # 测试模式

# ==================== 镜像源配置 ====================
# 清华大学镜像源
MIRROR_TSINGHUA="mirrors.tuna.tsinghua.edu.cn"
# 阿里云镜像源
MIRROR_ALIYUN="mirrors.aliyun.com"
# 腾讯云镜像源
MIRROR_TENCENT="mirrors.cloud.tencent.com"
# 华为云镜像源
MIRROR_HUAWEI="repo.huaweicloud.com"
# 中科大镜像源
MIRROR_USTC="mirrors.ustc.edu.cn"

# 官方镜像源
MIRROR_DEBIAN="deb.debian.org"
MIRROR_UBUNTU="archive.ubuntu.com"
MIRROR_CENTOS="mirror.centos.org"
MIRROR_ALMALINUX="repo.almalinux.org"
MIRROR_ROCKYLINUX="download.rockylinux.org"
MIRROR_FEDORA="download.fedoraproject.org"
MIRROR_ALPINE="dl-cdn.alpinelinux.org"

# ==================== 第三方 DD 镜像源 ====================
# 常用的 Windows DD 镜像源
DD_SOURCES=(
    "https://dd.1024.vip"
    "https://a.disk.re"
    "https://dd.ci"
    "https://iso.cat"
)

# ==================== 帮助函数 ====================
print_logo() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                                ║"
    echo "║   ██████╗ ██████╗     ██████╗ ███████╗██╗███╗   ██╗███████╗   ║"
    echo "║   ██╔══██╗██╔══██╗    ██╔══██╗██╔════╝██║████╗  ██║██╔════╝   ║"
    echo "║   ██║  ██║██║  ██║    ██████╔╝█████╗  ██║██╔██╗ ██║███████╗   ║"
    echo "║   ██║  ██║██║  ██║    ██╔══██╗██╔══╝  ██║██║╚██╗██║╚════██║   ║"
    echo "║   ██████╔╝██████╔╝    ██║  ██║███████╗██║██║ ╚████║███████║   ║"
    echo "║   ╚═════╝ ╚═════╝     ╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝   ║"
    echo "║                                                                ║"
    echo "║              DD Reinstall Script v${VERSION}                      ║"
    echo "║         一键DD重装系统 | Auto Region Detection                 ║"
    echo "║                                                                ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_help() {
    print_logo
    echo -e "${BOLD}用法:${NC}"
    echo "  bash reinstall.sh <发行版> [版本] [选项]"
    echo ""
    echo -e "${BOLD}支持的发行版:${NC}"
    echo -e "  ${GREEN}Debian 系列:${NC}  debian 9|10|11|12|13"
    echo -e "  ${GREEN}Ubuntu 系列:${NC}  ubuntu 16.04|18.04|20.04|22.04|24.04"
    echo -e "  ${GREEN}CentOS 系列:${NC}  centos 7|8|9"
    echo -e "  ${GREEN}AlmaLinux:${NC}    almalinux 8|9"
    echo -e "  ${GREEN}RockyLinux:${NC}   rockylinux 8|9"
    echo -e "  ${GREEN}Fedora:${NC}       fedora 38|39|40|41|42|43"
    echo -e "  ${GREEN}Alpine:${NC}       alpine 3.17|3.18|3.19|3.20|3.21"
    echo -e "  ${GREEN}Windows:${NC}      windows --dd <URL>"
    echo ""
    echo -e "${BOLD}选项:${NC}"
    echo "  --password <密码>     设置 root 密码 (默认随机生成)"
    echo "  --ssh-key <公钥>      设置 SSH 公钥"
    echo "  --ssh-port <端口>     设置 SSH 端口 (默认 22)"
    echo "  --mirror <源>         指定镜像源: auto|cn|overseas (默认 auto)"
    echo "  --dd <URL>            指定 DD 镜像 URL (用于 Windows)"
    echo "  --interface <接口>    指定网络接口 (默认自动检测)"
    echo "  --ip <IP>             指定 IP 地址 (默认自动检测)"
    echo "  --gateway <网关>      指定网关 (默认自动检测)"
    echo "  --netmask <掩码>      指定子网掩码 (默认自动检测)"
    echo "  --dns <DNS1,DNS2>     指定 DNS 服务器"
    echo "  --force               强制执行，跳过确认"
    echo "  --dry-run             测试模式，不实际执行"
    echo "  --detect-region       仅检测地区"
    echo "  --list-mirrors        列出所有可用镜像源"
    echo "  --list-dd             列出可用的 DD 镜像源"
    echo "  -h, --help            显示帮助信息"
    echo "  -v, --version         显示版本信息"
    echo ""
    echo -e "${BOLD}示例:${NC}"
    echo "  bash reinstall.sh debian 12"
    echo "  bash reinstall.sh ubuntu 22.04 --password mypassword"
    echo "  bash reinstall.sh centos 9 --mirror cn"
    echo "  bash reinstall.sh windows --dd https://example.com/win10.gz"
    echo ""
    echo -e "${BOLD}注意:${NC}"
    echo -e "  ${RED}⚠ 此脚本会清除硬盘上的所有数据！${NC}"
    echo -e "  ${RED}⚠ 请确保已备份重要数据！${NC}"
    echo ""
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    if [[ "$DEBUG" == "true" ]]; then
        echo -e "${PURPLE}[DEBUG]${NC} $1"
    fi
}

# ==================== 检测函数 ====================

# 检测是否为 root 用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本必须以 root 权限运行"
        log_info "请尝试: sudo bash $0 $*"
        exit 1
    fi
}

# 检测操作系统
check_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        CURRENT_OS=$ID
        CURRENT_VERSION=$VERSION_ID
    elif [[ -f /etc/redhat-release ]]; then
        CURRENT_OS="centos"
        CURRENT_VERSION=$(cat /etc/redhat-release | grep -oE '[0-9]+' | head -1)
    else
        log_error "无法检测操作系统"
        exit 1
    fi
    log_info "当前系统: $CURRENT_OS $CURRENT_VERSION"
}

# 检测 CPU 架构
check_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64|amd64)
            ARCH="x86_64"
            ;;
        aarch64|arm64)
            ARCH="aarch64"
            ;;
        *)
            log_error "不支持的 CPU 架构: $ARCH"
            exit 1
            ;;
    esac
    log_info "CPU 架构: $ARCH"
}

# 检测引导模式
check_boot_mode() {
    if [[ -d /sys/firmware/efi ]]; then
        BOOT_MODE="efi"
    else
        BOOT_MODE="bios"
    fi
    log_info "引导模式: $BOOT_MODE"
}

# 检测虚拟化类型
check_virt() {
    VIRT_TYPE=""
    if command -v systemd-detect-virt &>/dev/null; then
        VIRT_TYPE=$(systemd-detect-virt 2>/dev/null || echo "none")
    elif [[ -f /proc/cpuinfo ]]; then
        if grep -qi "hypervisor" /proc/cpuinfo; then
            VIRT_TYPE="vm"
        fi
    fi
    
    # 检测不支持的虚拟化类型
    case $VIRT_TYPE in
        openvz|lxc|lxc-libvirt)
            log_error "不支持 OpenVZ/LXC 虚拟化环境"
            log_info "请参考: https://github.com/LloydAsp/OsMutation"
            exit 1
            ;;
    esac
    
    if [[ -n "$VIRT_TYPE" && "$VIRT_TYPE" != "none" ]]; then
        log_info "虚拟化类型: $VIRT_TYPE"
    fi
}

# 检测内存
check_memory() {
    TOTAL_MEM=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
    log_info "总内存: ${TOTAL_MEM}MB"
    
    if [[ $TOTAL_MEM -lt 256 ]]; then
        log_warn "内存不足 256MB，部分发行版可能无法安装"
    fi
}

# 检测磁盘
check_disk() {
    # 获取主磁盘
    if [[ -b /dev/vda ]]; then
        DISK="/dev/vda"
    elif [[ -b /dev/sda ]]; then
        DISK="/dev/sda"
    elif [[ -b /dev/xvda ]]; then
        DISK="/dev/xvda"
    elif [[ -b /dev/nvme0n1 ]]; then
        DISK="/dev/nvme0n1"
    else
        log_error "无法检测主磁盘"
        exit 1
    fi
    
    DISK_SIZE=$(lsblk -b -d -n -o SIZE "$DISK" 2>/dev/null | head -1)
    DISK_SIZE_GB=$((DISK_SIZE / 1024 / 1024 / 1024))
    
    log_info "主磁盘: $DISK (${DISK_SIZE_GB}GB)"
    
    if [[ $DISK_SIZE_GB -lt 5 ]]; then
        log_error "磁盘空间不足 5GB"
        exit 1
    fi
}

# 检测网络配置
check_network() {
    # 获取默认网络接口
    if [[ -z "$INTERFACE" ]]; then
        INTERFACE=$(ip route | awk '/default/ {print $5}' | head -1)
    fi
    
    if [[ -z "$INTERFACE" ]]; then
        log_error "无法检测网络接口"
        exit 1
    fi
    
    # 获取 IP 地址
    if [[ -z "$IP_ADDR" ]]; then
        IP_ADDR=$(ip -4 addr show "$INTERFACE" | awk '/inet / {print $2}' | cut -d'/' -f1 | head -1)
    fi
    
    # 获取子网掩码
    if [[ -z "$NETMASK" ]]; then
        CIDR=$(ip -4 addr show "$INTERFACE" | awk '/inet / {print $2}' | cut -d'/' -f2 | head -1)
        NETMASK=$(cidr_to_netmask "$CIDR")
    fi
    
    # 获取网关
    if [[ -z "$GATEWAY" ]]; then
        GATEWAY=$(ip route | awk '/default/ {print $3}' | head -1)
    fi
    
    log_info "网络接口: $INTERFACE"
    log_info "IP 地址: $IP_ADDR"
    log_info "子网掩码: $NETMASK"
    log_info "网关: $GATEWAY"
    log_info "DNS: $DNS1, $DNS2"
}

# CIDR 转换为子网掩码
cidr_to_netmask() {
    local cidr=$1
    local mask=""
    local full_octets=$((cidr / 8))
    local partial_octet=$((cidr % 8))
    
    for ((i=0; i<4; i++)); do
        if [[ $i -lt $full_octets ]]; then
            mask+="255"
        elif [[ $i -eq $full_octets ]]; then
            mask+=$((256 - (1 << (8 - partial_octet))))
        else
            mask+="0"
        fi
        [[ $i -lt 3 ]] && mask+="."
    done
    
    echo "$mask"
}

# ==================== 地区检测 ====================

# 通过多个 API 检测地区
detect_region() {
    log_info "正在检测服务器地区..."
    
    local country=""
    local apis=(
        "https://ipapi.co/country_code"
        "https://ifconfig.co/country-iso"
        "https://api.ip.sb/geoip"
        "https://ipinfo.io/country"
    )
    
    for api in "${apis[@]}"; do
        if country=$(curl -s --connect-timeout 5 --max-time 10 "$api" 2>/dev/null); then
            # 处理 JSON 响应
            if echo "$country" | grep -q "country_code"; then
                country=$(echo "$country" | grep -oP '"country_code"\s*:\s*"\K[^"]+')
            fi
            
            if [[ -n "$country" && ${#country} -eq 2 ]]; then
                break
            fi
        fi
    done
    
    # 判断是否为中国大陆
    if [[ "$country" == "CN" ]]; then
        REGION="cn"
        log_success "检测到地区: 中国大陆 (将使用国内镜像源)"
    else
        REGION="overseas"
        log_success "检测到地区: 海外 [$country] (将使用官方镜像源)"
    fi
    
    # 备用检测方法: 时区
    if [[ -z "$REGION" ]]; then
        local timezone=$(timedatectl 2>/dev/null | grep "Time zone" | awk '{print $3}')
        if [[ "$timezone" == "Asia/Shanghai" || "$timezone" == "Asia/Chongqing" ]]; then
            REGION="cn"
            log_warn "通过时区检测: 中国大陆"
        else
            REGION="overseas"
            log_warn "通过时区检测: 海外"
        fi
    fi
}

# 测试镜像源速度
test_mirror_speed() {
    local mirror=$1
    local start_time=$(date +%s%N)
    
    if curl -s --connect-timeout 3 --max-time 5 "https://$mirror/" >/dev/null 2>&1; then
        local end_time=$(date +%s%N)
        local elapsed=$(((end_time - start_time) / 1000000))
        echo "$elapsed"
    else
        echo "9999"
    fi
}

# 选择最佳镜像源
select_best_mirror() {
    local distro=$1
    
    if [[ "$MIRROR" == "cn" ]]; then
        REGION="cn"
    elif [[ "$MIRROR" == "overseas" ]]; then
        REGION="overseas"
    elif [[ -z "$REGION" ]]; then
        detect_region
    fi
    
    log_info "正在选择最佳镜像源..."
    
    if [[ "$REGION" == "cn" ]]; then
        # 中国大陆镜像源优先级
        local cn_mirrors=("$MIRROR_TSINGHUA" "$MIRROR_ALIYUN" "$MIRROR_TENCENT" "$MIRROR_USTC" "$MIRROR_HUAWEI")
        local best_mirror=""
        local best_speed=9999
        
        for mirror in "${cn_mirrors[@]}"; do
            local speed=$(test_mirror_speed "$mirror")
            log_debug "测试 $mirror: ${speed}ms"
            if [[ $speed -lt $best_speed ]]; then
                best_speed=$speed
                best_mirror=$mirror
            fi
        done
        
        if [[ -n "$best_mirror" ]]; then
            SELECTED_MIRROR=$best_mirror
            log_success "选择镜像源: $SELECTED_MIRROR (${best_speed}ms)"
        else
            SELECTED_MIRROR=$MIRROR_TSINGHUA
            log_warn "使用默认镜像源: $SELECTED_MIRROR"
        fi
    else
        # 海外使用官方镜像源
        case $distro in
            debian)
                SELECTED_MIRROR=$MIRROR_DEBIAN
                ;;
            ubuntu)
                SELECTED_MIRROR=$MIRROR_UBUNTU
                ;;
            centos)
                SELECTED_MIRROR=$MIRROR_CENTOS
                ;;
            almalinux)
                SELECTED_MIRROR=$MIRROR_ALMALINUX
                ;;
            rockylinux)
                SELECTED_MIRROR=$MIRROR_ROCKYLINUX
                ;;
            fedora)
                SELECTED_MIRROR=$MIRROR_FEDORA
                ;;
            alpine)
                SELECTED_MIRROR=$MIRROR_ALPINE
                ;;
            *)
                SELECTED_MIRROR=$MIRROR_DEBIAN
                ;;
        esac
        log_success "使用官方镜像源: $SELECTED_MIRROR"
    fi
}

# 列出所有镜像源
list_mirrors() {
    echo -e "${BOLD}国内镜像源:${NC}"
    echo "  清华大学: $MIRROR_TSINGHUA"
    echo "  阿里云:   $MIRROR_ALIYUN"
    echo "  腾讯云:   $MIRROR_TENCENT"
    echo "  华为云:   $MIRROR_HUAWEI"
    echo "  中科大:   $MIRROR_USTC"
    echo ""
    echo -e "${BOLD}官方镜像源:${NC}"
    echo "  Debian:     $MIRROR_DEBIAN"
    echo "  Ubuntu:     $MIRROR_UBUNTU"
    echo "  CentOS:     $MIRROR_CENTOS"
    echo "  AlmaLinux:  $MIRROR_ALMALINUX"
    echo "  RockyLinux: $MIRROR_ROCKYLINUX"
    echo "  Fedora:     $MIRROR_FEDORA"
    echo "  Alpine:     $MIRROR_ALPINE"
}

# 列出 DD 镜像源
list_dd_sources() {
    echo -e "${BOLD}可用的 DD 镜像源:${NC}"
    for source in "${DD_SOURCES[@]}"; do
        echo "  $source"
    done
    echo ""
    echo -e "${BOLD}常用 Windows DD 镜像:${NC}"
    echo "  Windows 10 LTSC: https://dd.1024.vip/windows/lite/win10-ltsc-2021.gz"
    echo "  Windows 11:      https://dd.1024.vip/windows/lite/win11-23h2.gz"
    echo "  Windows Server:  https://dd.1024.vip/windows/server/2022.gz"
}

# ==================== 依赖安装 ====================

install_dependencies() {
    log_info "检查并安装依赖..."
    
    local deps="wget curl gawk grep sed"
    local pkg_manager=""
    local install_cmd=""
    
    # 检测包管理器
    if command -v apt-get &>/dev/null; then
        pkg_manager="apt"
        install_cmd="apt-get update && apt-get install -y"
    elif command -v yum &>/dev/null; then
        pkg_manager="yum"
        install_cmd="yum install -y"
    elif command -v dnf &>/dev/null; then
        pkg_manager="dnf"
        install_cmd="dnf install -y"
    elif command -v apk &>/dev/null; then
        pkg_manager="apk"
        install_cmd="apk add"
    else
        log_error "无法检测包管理器"
        exit 1
    fi
    
    for dep in $deps; do
        if ! command -v "$dep" &>/dev/null; then
            log_info "安装 $dep..."
            eval "$install_cmd $dep" >/dev/null 2>&1 || true
        fi
    done
    
    log_success "依赖检查完成"
}

# ==================== 生成密码 ====================

generate_password() {
    local length=${1:-16}
    tr -dc 'A-Za-z0-9!@#$%^&*' </dev/urandom | head -c "$length"
}

# ==================== 安装系统函数 ====================

# 获取 Debian/Ubuntu 镜像 URL
get_debian_url() {
    local distro=$1
    local version=$2
    local arch=$3
    local base_url=""
    
    if [[ "$REGION" == "cn" ]]; then
        base_url="https://${SELECTED_MIRROR}"
    else
        if [[ "$distro" == "debian" ]]; then
            base_url="https://${MIRROR_DEBIAN}"
        else
            base_url="https://${MIRROR_UBUNTU}"
        fi
    fi
    
    if [[ "$distro" == "debian" ]]; then
        echo "${base_url}/debian/dists/${version}/main/installer-${arch}/current/images/netboot/debian-installer/${arch}/"
    else
        echo "${base_url}/ubuntu/dists/${version}/main/installer-${arch}/current/images/netboot/ubuntu-installer/${arch}/"
    fi
}

# 获取 CentOS/RHEL 系列镜像 URL
get_rhel_url() {
    local distro=$1
    local version=$2
    local arch=$3
    local base_url=""
    
    if [[ "$REGION" == "cn" ]]; then
        base_url="https://${SELECTED_MIRROR}"
    fi
    
    case $distro in
        centos)
            if [[ "$REGION" == "cn" ]]; then
                echo "${base_url}/centos-stream/${version}-stream/BaseOS/${arch}/os/images/pxeboot/"
            else
                echo "https://mirror.stream.centos.org/${version}-stream/BaseOS/${arch}/os/images/pxeboot/"
            fi
            ;;
        almalinux)
            if [[ "$REGION" == "cn" ]]; then
                echo "${base_url}/almalinux/${version}/BaseOS/${arch}/os/images/pxeboot/"
            else
                echo "https://repo.almalinux.org/almalinux/${version}/BaseOS/${arch}/os/images/pxeboot/"
            fi
            ;;
        rockylinux)
            if [[ "$REGION" == "cn" ]]; then
                echo "${base_url}/rocky/${version}/BaseOS/${arch}/os/images/pxeboot/"
            else
                echo "https://download.rockylinux.org/pub/rocky/${version}/BaseOS/${arch}/os/images/pxeboot/"
            fi
            ;;
        fedora)
            if [[ "$REGION" == "cn" ]]; then
                echo "${base_url}/fedora/releases/${version}/Everything/${arch}/os/images/pxeboot/"
            else
                echo "https://download.fedoraproject.org/pub/fedora/linux/releases/${version}/Everything/${arch}/os/images/pxeboot/"
            fi
            ;;
    esac
}

# 获取 Alpine 镜像 URL
get_alpine_url() {
    local version=$1
    local arch=$2
    local base_url=""
    
    if [[ "$REGION" == "cn" ]]; then
        base_url="https://${SELECTED_MIRROR}/alpine"
    else
        base_url="https://dl-cdn.alpinelinux.org/alpine"
    fi
    
    echo "${base_url}/v${version}/releases/${arch}/"
}

# 下载安装文件
download_files() {
    local url=$1
    local file=$2
    local dest=$3
    
    log_info "下载 $file..."
    
    if ! wget -q --show-progress -O "$dest" "${url}${file}"; then
        log_error "下载失败: ${url}${file}"
        return 1
    fi
    
    return 0
}

# 配置 GRUB 安装
setup_grub() {
    local kernel=$1
    local initrd=$2
    local append=$3
    
    log_info "配置 GRUB 启动项..."
    
    # 备份 GRUB 配置
    cp /etc/default/grub /etc/default/grub.bak 2>/dev/null || true
    
    # 创建自定义启动项
    cat > /boot/grub/custom.cfg << EOF
menuentry "DD Reinstall" {
    linux $kernel $append
    initrd $initrd
}
EOF
    
    # 更新 GRUB
    if command -v grub2-mkconfig &>/dev/null; then
        grub2-mkconfig -o /boot/grub2/grub.cfg
    elif command -v grub-mkconfig &>/dev/null; then
        grub-mkconfig -o /boot/grub/grub.cfg
    fi
}

# 安装 Debian
install_debian() {
    local version=${VERSION_ID:-12}
    
    log_info "准备安装 Debian $version..."
    
    # 版本映射
    declare -A version_map=(
        ["9"]="stretch"
        ["10"]="buster"
        ["11"]="bullseye"
        ["12"]="bookworm"
        ["13"]="trixie"
    )
    
    local codename=${version_map[$version]:-"bookworm"}
    select_best_mirror "debian"
    
    local installer_url=$(get_debian_url "debian" "$codename" "$ARCH")
    
    mkdir -p /boot/netboot
    download_files "$installer_url" "linux" "/boot/netboot/vmlinuz"
    download_files "$installer_url" "initrd.gz" "/boot/netboot/initrd.gz"
    
    # 构建安装参数
    local append="auto=true priority=critical"
    append+=" interface=$INTERFACE"
    append+=" netcfg/choose_interface=$INTERFACE"
    append+=" netcfg/disable_autoconfig=true"
    append+=" netcfg/get_ipaddress=$IP_ADDR"
    append+=" netcfg/get_netmask=$NETMASK"
    append+=" netcfg/get_gateway=$GATEWAY"
    append+=" netcfg/get_nameservers=$DNS1"
    append+=" netcfg/confirm_static=true"
    append+=" passwd/root-password=$PASSWORD"
    append+=" passwd/root-password-again=$PASSWORD"
    
    if [[ "$REGION" == "cn" ]]; then
        append+=" mirror/http/hostname=$SELECTED_MIRROR"
        append+=" mirror/http/directory=/debian"
    fi
    
    setup_grub "/boot/netboot/vmlinuz" "/boot/netboot/initrd.gz" "$append"
    
    log_success "Debian $version 安装准备完成"
}

# 安装 Ubuntu
install_ubuntu() {
    local version=${VERSION_ID:-22.04}
    
    log_info "准备安装 Ubuntu $version..."
    
    select_best_mirror "ubuntu"
    
    local installer_url=$(get_debian_url "ubuntu" "$version" "$ARCH")
    
    mkdir -p /boot/netboot
    download_files "$installer_url" "linux" "/boot/netboot/vmlinuz" || {
        log_warn "尝试使用云镜像安装..."
        install_ubuntu_cloud "$version"
        return
    }
    download_files "$installer_url" "initrd.gz" "/boot/netboot/initrd.gz"
    
    local append="auto=true priority=critical"
    append+=" interface=$INTERFACE"
    append+=" netcfg/choose_interface=$INTERFACE"
    append+=" netcfg/disable_autoconfig=true"
    append+=" netcfg/get_ipaddress=$IP_ADDR"
    append+=" netcfg/get_netmask=$NETMASK"
    append+=" netcfg/get_gateway=$GATEWAY"
    append+=" netcfg/get_nameservers=$DNS1"
    append+=" passwd/root-password=$PASSWORD"
    append+=" passwd/root-password-again=$PASSWORD"
    
    if [[ "$REGION" == "cn" ]]; then
        append+=" mirror/http/hostname=$SELECTED_MIRROR"
        append+=" mirror/http/directory=/ubuntu"
    fi
    
    setup_grub "/boot/netboot/vmlinuz" "/boot/netboot/initrd.gz" "$append"
    
    log_success "Ubuntu $version 安装准备完成"
}

# 安装 Ubuntu 云镜像
install_ubuntu_cloud() {
    local version=$1
    log_info "使用云镜像安装 Ubuntu $version..."
    
    local cloud_url=""
    if [[ "$REGION" == "cn" ]]; then
        cloud_url="https://${SELECTED_MIRROR}/ubuntu-cloud-images/releases/${version}/release/"
    else
        cloud_url="https://cloud-images.ubuntu.com/releases/${version}/release/"
    fi
    
    # TODO: 实现云镜像安装逻辑
    log_warn "云镜像安装功能开发中..."
}

# 安装 CentOS
install_centos() {
    local version=${VERSION_ID:-9}
    
    log_info "准备安装 CentOS $version..."
    
    select_best_mirror "centos"
    
    local installer_url=$(get_rhel_url "centos" "$version" "$ARCH")
    
    mkdir -p /boot/netboot
    download_files "$installer_url" "vmlinuz" "/boot/netboot/vmlinuz"
    download_files "$installer_url" "initrd.img" "/boot/netboot/initrd.img"
    
    # 构建 Kickstart 配置
    create_kickstart "centos" "$version"
    
    local ks_url="file:///boot/netboot/ks.cfg"
    local append="inst.ks=$ks_url"
    append+=" ip=$IP_ADDR::$GATEWAY:$NETMASK::$INTERFACE:none"
    append+=" nameserver=$DNS1"
    
    setup_grub "/boot/netboot/vmlinuz" "/boot/netboot/initrd.img" "$append"
    
    log_success "CentOS $version 安装准备完成"
}

# 安装 AlmaLinux
install_almalinux() {
    local version=${VERSION_ID:-9}
    
    log_info "准备安装 AlmaLinux $version..."
    
    select_best_mirror "almalinux"
    
    local installer_url=$(get_rhel_url "almalinux" "$version" "$ARCH")
    
    mkdir -p /boot/netboot
    download_files "$installer_url" "vmlinuz" "/boot/netboot/vmlinuz"
    download_files "$installer_url" "initrd.img" "/boot/netboot/initrd.img"
    
    create_kickstart "almalinux" "$version"
    
    local ks_url="file:///boot/netboot/ks.cfg"
    local append="inst.ks=$ks_url"
    append+=" ip=$IP_ADDR::$GATEWAY:$NETMASK::$INTERFACE:none"
    append+=" nameserver=$DNS1"
    
    setup_grub "/boot/netboot/vmlinuz" "/boot/netboot/initrd.img" "$append"
    
    log_success "AlmaLinux $version 安装准备完成"
}

# 安装 RockyLinux
install_rockylinux() {
    local version=${VERSION_ID:-9}
    
    log_info "准备安装 RockyLinux $version..."
    
    select_best_mirror "rockylinux"
    
    local installer_url=$(get_rhel_url "rockylinux" "$version" "$ARCH")
    
    mkdir -p /boot/netboot
    download_files "$installer_url" "vmlinuz" "/boot/netboot/vmlinuz"
    download_files "$installer_url" "initrd.img" "/boot/netboot/initrd.img"
    
    create_kickstart "rockylinux" "$version"
    
    local ks_url="file:///boot/netboot/ks.cfg"
    local append="inst.ks=$ks_url"
    append+=" ip=$IP_ADDR::$GATEWAY:$NETMASK::$INTERFACE:none"
    append+=" nameserver=$DNS1"
    
    setup_grub "/boot/netboot/vmlinuz" "/boot/netboot/initrd.img" "$append"
    
    log_success "RockyLinux $version 安装准备完成"
}

# 安装 Fedora
install_fedora() {
    local version=${VERSION_ID:-40}
    
    log_info "准备安装 Fedora $version..."
    
    select_best_mirror "fedora"
    
    local installer_url=$(get_rhel_url "fedora" "$version" "$ARCH")
    
    mkdir -p /boot/netboot
    download_files "$installer_url" "vmlinuz" "/boot/netboot/vmlinuz"
    download_files "$installer_url" "initrd.img" "/boot/netboot/initrd.img"
    
    create_kickstart "fedora" "$version"
    
    local ks_url="file:///boot/netboot/ks.cfg"
    local append="inst.ks=$ks_url"
    append+=" ip=$IP_ADDR::$GATEWAY:$NETMASK::$INTERFACE:none"
    append+=" nameserver=$DNS1"
    
    setup_grub "/boot/netboot/vmlinuz" "/boot/netboot/initrd.img" "$append"
    
    log_success "Fedora $version 安装准备完成"
}

# 安装 Alpine
install_alpine() {
    local version=${VERSION_ID:-3.20}
    
    log_info "准备安装 Alpine $version..."
    
    select_best_mirror "alpine"
    
    local alpine_url=$(get_alpine_url "$version" "$ARCH")
    local iso_name="alpine-virt-${version}.0-${ARCH}.iso"
    
    mkdir -p /boot/netboot
    
    # 下载 Alpine ISO
    download_files "$alpine_url" "$iso_name" "/boot/netboot/alpine.iso"
    
    # 提取内核和 initramfs
    log_info "提取 Alpine 安装文件..."
    
    mount -o loop /boot/netboot/alpine.iso /mnt
    cp /mnt/boot/vmlinuz-virt /boot/netboot/vmlinuz
    cp /mnt/boot/initramfs-virt /boot/netboot/initrd
    umount /mnt
    
    local append="ip=$IP_ADDR::$GATEWAY:$NETMASK::$INTERFACE:none"
    append+=" alpine_repo=https://${SELECTED_MIRROR}/alpine/v${version}/main"
    
    setup_grub "/boot/netboot/vmlinuz" "/boot/netboot/initrd" "$append"
    
    log_success "Alpine $version 安装准备完成"
}

# 安装 Windows (DD 镜像)
install_windows() {
    if [[ -z "$DD_URL" ]]; then
        log_error "请使用 --dd 参数指定 Windows DD 镜像 URL"
        log_info "示例: bash reinstall.sh windows --dd https://example.com/win10.gz"
        echo ""
        list_dd_sources
        exit 1
    fi
    
    log_info "准备安装 Windows (DD 镜像)..."
    log_info "DD 镜像: $DD_URL"
    
    # 检测 DD 镜像格式
    local dd_ext="${DD_URL##*.}"
    local decompress_cmd=""
    
    case $dd_ext in
        gz|gzip)
            decompress_cmd="gzip -d -c"
            if ! command -v gzip &>/dev/null; then
                install_dependencies
            fi
            ;;
        xz)
            decompress_cmd="xz -d -c"
            if ! command -v xz &>/dev/null; then
                apt-get install -y xz-utils 2>/dev/null || yum install -y xz 2>/dev/null
            fi
            ;;
        zst|zstd)
            decompress_cmd="zstd -d -c"
            if ! command -v zstd &>/dev/null; then
                apt-get install -y zstd 2>/dev/null || yum install -y zstd 2>/dev/null
            fi
            ;;
        raw|img)
            decompress_cmd="cat"
            ;;
        *)
            log_warn "未知压缩格式，尝试直接 DD..."
            decompress_cmd="cat"
            ;;
    esac
    
    log_warn "即将开始 DD 操作，这将清除 $DISK 上的所有数据！"
    
    if [[ "$FORCE_MODE" != true && "$DRY_RUN" != true ]]; then
        echo -e "${RED}"
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║                         ⚠ 警告 ⚠                            ║"
        echo "║                                                               ║"
        echo "║   即将清除 $DISK 上的所有数据并安装 Windows                   ║"
        echo "║   此操作不可逆转！                                            ║"
        echo "║                                                               ║"
        echo "╚══════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        
        read -p "确认继续？输入 YES 继续: " confirm
        if [[ "$confirm" != "YES" ]]; then
            log_info "操作已取消"
            exit 0
        fi
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] 将执行: wget -qO- '$DD_URL' | $decompress_cmd | dd of=$DISK bs=4M status=progress"
        return 0
    fi
    
    log_info "开始下载并写入 DD 镜像..."
    log_info "这可能需要较长时间，请耐心等待..."
    
    # 同步磁盘
    sync
    
    # 执行 DD
    if wget -qO- "$DD_URL" | $decompress_cmd | dd of="$DISK" bs=4M status=progress conv=fsync 2>&1; then
        sync
        log_success "Windows DD 安装完成!"
        log_info "系统将在 10 秒后重启..."
        sleep 10
        reboot
    else
        log_error "DD 操作失败"
        exit 1
    fi
}

# 创建 Kickstart 配置文件
create_kickstart() {
    local distro=$1
    local version=$2
    
    log_info "生成 Kickstart 配置..."
    
    local repo_url=""
    if [[ "$REGION" == "cn" ]]; then
        case $distro in
            centos)
                repo_url="https://${SELECTED_MIRROR}/centos-stream/${version}-stream/BaseOS/${ARCH}/os/"
                ;;
            almalinux)
                repo_url="https://${SELECTED_MIRROR}/almalinux/${version}/BaseOS/${ARCH}/os/"
                ;;
            rockylinux)
                repo_url="https://${SELECTED_MIRROR}/rocky/${version}/BaseOS/${ARCH}/os/"
                ;;
            fedora)
                repo_url="https://${SELECTED_MIRROR}/fedora/releases/${version}/Everything/${ARCH}/os/"
                ;;
        esac
    else
        case $distro in
            centos)
                repo_url="https://mirror.stream.centos.org/${version}-stream/BaseOS/${ARCH}/os/"
                ;;
            almalinux)
                repo_url="https://repo.almalinux.org/almalinux/${version}/BaseOS/${ARCH}/os/"
                ;;
            rockylinux)
                repo_url="https://download.rockylinux.org/pub/rocky/${version}/BaseOS/${ARCH}/os/"
                ;;
            fedora)
                repo_url="https://download.fedoraproject.org/pub/fedora/linux/releases/${version}/Everything/${ARCH}/os/"
                ;;
        esac
    fi
    
    cat > /boot/netboot/ks.cfg << EOF
#version=RHEL9
# System authorization information
authselect --enableshadow --passalgo=sha512

# Use network installation
url --url="$repo_url"

# Use text install
text

# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'

# System language
lang en_US.UTF-8

# Network information
network --bootproto=static --device=$INTERFACE --gateway=$GATEWAY --ip=$IP_ADDR --nameserver=$DNS1,$DNS2 --netmask=$NETMASK --ipv6=auto --activate
network --hostname=localhost.localdomain

# Root password
rootpw --plaintext $PASSWORD

# Firewall configuration
firewall --enabled --ssh

# SELinux configuration
selinux --enforcing

# System services
services --enabled="chronyd,sshd"

# System timezone
timezone Asia/Shanghai --utc

# Bootloader configuration
bootloader --append="crashkernel=auto" --location=mbr

# Partition clearing information
clearpart --all --initlabel

# Disk partitioning information
autopart --type=lvm

# Reboot after installation
reboot

%packages
@^minimal-environment
@standard
chrony
openssh-server
wget
curl
%end

%post --log=/root/ks-post.log
# Enable SSH root login
sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

# Set SSH port
sed -i 's/^#Port.*/Port $SSH_PORT/' /etc/ssh/sshd_config
sed -i 's/^Port.*/Port $SSH_PORT/' /etc/ssh/sshd_config

# Restart SSH
systemctl restart sshd

# SSH public key
if [[ -n "$SSH_KEY" ]]; then
    mkdir -p /root/.ssh
    echo "$SSH_KEY" >> /root/.ssh/authorized_keys
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/authorized_keys
fi
%end
EOF
    
    log_success "Kickstart 配置已生成"
}

# ==================== 主流程 ====================

# 确认安装
confirm_install() {
    echo ""
    echo -e "${BOLD}安装信息确认:${NC}"
    echo "════════════════════════════════════════"
    echo -e "  目标系统:   ${GREEN}$DISTRO $VERSION_ID${NC}"
    echo -e "  CPU 架构:   $ARCH"
    echo -e "  引导模式:   $BOOT_MODE"
    echo -e "  目标磁盘:   $DISK"
    echo -e "  网络接口:   $INTERFACE"
    echo -e "  IP 地址:    $IP_ADDR"
    echo -e "  子网掩码:   $NETMASK"
    echo -e "  网关:       $GATEWAY"
    echo -e "  DNS:        $DNS1, $DNS2"
    echo -e "  SSH 端口:   $SSH_PORT"
    echo -e "  镜像源:     $SELECTED_MIRROR"
    if [[ -n "$DD_URL" ]]; then
        echo -e "  DD 镜像:    $DD_URL"
    fi
    echo "════════════════════════════════════════"
    echo ""
    
    if [[ "$FORCE_MODE" != true && "$DRY_RUN" != true ]]; then
        echo -e "${RED}⚠ 警告: 此操作将清除目标磁盘上的所有数据！${NC}"
        read -p "确认继续？(yes/no): " confirm
        if [[ "$confirm" != "yes" ]]; then
            log_info "操作已取消"
            exit 0
        fi
    fi
}

# 开始安装
start_install() {
    case $DISTRO in
        debian)
            install_debian
            ;;
        ubuntu)
            install_ubuntu
            ;;
        centos)
            install_centos
            ;;
        almalinux)
            install_almalinux
            ;;
        rockylinux)
            install_rockylinux
            ;;
        fedora)
            install_fedora
            ;;
        alpine)
            install_alpine
            ;;
        windows)
            install_windows
            ;;
        *)
            log_error "未知发行版: $DISTRO"
            exit 1
            ;;
    esac
}

# 完成安装
finish_install() {
    if [[ "$DRY_RUN" == true ]]; then
        log_success "[DRY-RUN] 测试完成，未实际执行任何操作"
        return
    fi
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    安装准备完成!                              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Root 密码:${NC} $PASSWORD"
    echo -e "  ${BOLD}SSH 端口:${NC}  $SSH_PORT"
    echo ""
    echo -e "  系统将在 ${YELLOW}10 秒${NC} 后重启并开始安装"
    echo -e "  安装过程可能需要 ${YELLOW}5-20 分钟${NC}"
    echo ""
    echo -e "  ${CYAN}请记住以上信息用于登录新系统!${NC}"
    echo ""
    
    for i in {10..1}; do
        echo -ne "\r  重启倒计时: ${YELLOW}$i${NC} 秒  "
        sleep 1
    done
    
    echo ""
    log_info "正在重启..."
    reboot
}

# 解析参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            debian|ubuntu|centos|almalinux|rockylinux|fedora|alpine|windows)
                DISTRO=$1
                shift
                # 检查下一个参数是否是版本号
                if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
                    VERSION_ID=$1
                    shift
                fi
                ;;
            --password)
                PASSWORD=$2
                shift 2
                ;;
            --ssh-key)
                SSH_KEY=$2
                shift 2
                ;;
            --ssh-port)
                SSH_PORT=$2
                shift 2
                ;;
            --mirror)
                MIRROR=$2
                shift 2
                ;;
            --dd)
                DD_URL=$2
                shift 2
                ;;
            --interface)
                INTERFACE=$2
                shift 2
                ;;
            --ip)
                IP_ADDR=$2
                shift 2
                ;;
            --gateway)
                GATEWAY=$2
                shift 2
                ;;
            --netmask)
                NETMASK=$2
                shift 2
                ;;
            --dns)
                IFS=',' read -r DNS1 DNS2 <<< "$2"
                shift 2
                ;;
            --force)
                FORCE_MODE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --detect-region)
                detect_region
                exit 0
                ;;
            --list-mirrors)
                list_mirrors
                exit 0
                ;;
            --list-dd)
                list_dd_sources
                exit 0
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            -v|--version)
                echo "$SCRIPT_NAME v$VERSION"
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                print_help
                exit 1
                ;;
        esac
    done
}

# 主函数
main() {
    print_logo
    
    # 解析参数
    parse_args "$@"
    
    # 检查发行版
    if [[ -z "$DISTRO" ]]; then
        log_error "请指定要安装的发行版"
        echo ""
        print_help
        exit 1
    fi
    
    # 检查权限
    check_root
    
    # 环境检测
    check_os
    check_arch
    check_boot_mode
    check_virt
    check_memory
    check_disk
    
    # 安装依赖
    install_dependencies
    
    # 检测网络
    check_network
    
    # 地区检测和镜像源选择
    select_best_mirror "$DISTRO"
    
    # 生成密码 (如果未指定)
    if [[ -z "$PASSWORD" ]]; then
        PASSWORD=$(generate_password 12)
        log_info "已生成随机密码: $PASSWORD"
    fi
    
    # 确认安装
    confirm_install
    
    # 开始安装
    start_install
    
    # 完成安装
    finish_install
}

# 运行主函数
main "$@"
