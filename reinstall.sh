#!/bin/bash
#
# DD Reinstall Script - 一键DD重装系统脚本
# 支持交互式菜单选择，自动检测地区，使用最优镜像源
#
# 基于 https://github.com/bin456789/reinstall 改写
# GitHub: https://github.com/NX2406/DD
# License: MIT
#

set -euo pipefail

# ==================== 版本信息 ====================
VERSION="3.0.0"
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
SSH_PORT="22"       # SSH 端口
SSH_KEY=""          # SSH 公钥
DD_URL=""           # DD 镜像 URL
INTERFACE=""        # 网络接口
IP_ADDR=""          # IP 地址
GATEWAY=""          # 网关
NETMASK=""          # 子网掩码
SELECTED_MIRROR=""  # 选择的镜像源
HOLD_MODE=""        # 暂停模式
INSTALLER_MODE=""   # 是否使用 ISO 安装器
CI_MODE=""          # 是否使用云镜像
WINDOWS_LANG="en-us"    # Windows 语言
WINDOWS_IMAGE_NAME=""   # Windows 镜像名称
ALLOW_PING=""       # 允许 ping
RDP_PORT=""         # RDP 端口

# ==================== 支持的系统列表 ====================
# Linux 发行版
declare -A LINUX_DISTROS=(
    # Debian 系列
    ["debian_13"]="Debian 13 (Trixie)"
    ["debian_12"]="Debian 12 (Bookworm) - 推荐"
    ["debian_11"]="Debian 11 (Bullseye)"
    ["debian_10"]="Debian 10 (Buster)"
    
    # Ubuntu 系列
    ["ubuntu_24.04"]="Ubuntu 24.04 LTS (Noble)"
    ["ubuntu_22.04"]="Ubuntu 22.04 LTS (Jammy) - 推荐"
    ["ubuntu_20.04"]="Ubuntu 20.04 LTS (Focal)"
    ["ubuntu_18.04"]="Ubuntu 18.04 LTS (Bionic)"
    
    # Kali
    ["kali"]="Kali Linux 最新版"
    
    # CentOS/RHEL 系列
    ["centos_10"]="CentOS 10 Stream"
    ["centos_9"]="CentOS 9 Stream"
    ["almalinux_9"]="AlmaLinux 9"
    ["almalinux_8"]="AlmaLinux 8"
    ["rocky_9"]="Rocky Linux 9"
    ["rocky_8"]="Rocky Linux 8"
    ["oracle_9"]="Oracle Linux 9"
    ["oracle_8"]="Oracle Linux 8"
    ["fedora_43"]="Fedora 43"
    ["fedora_42"]="Fedora 42"
    
    # 其他
    ["alpine_3.21"]="Alpine 3.21"
    ["alpine_3.20"]="Alpine 3.20"
    ["arch"]="Arch Linux"
    ["gentoo"]="Gentoo"
    ["opensuse_15.6"]="openSUSE 15.6"
    ["nixos"]="NixOS"
    
    # 国产系统
    ["anolis_8"]="Anolis OS 8"
    ["opencloudos_9"]="OpenCloudOS 9"
    ["openeuler_24.03"]="openEuler 24.03"
)

# Windows 版本
declare -A WINDOWS_VERSIONS=(
    ["win11_ltsc_2024"]="Windows 11 Enterprise LTSC 2024"
    ["win11_23h2"]="Windows 11 23H2"
    ["win10_ltsc_2021"]="Windows 10 Enterprise LTSC 2021"
    ["win10_22h2"]="Windows 10 22H2"
    ["server_2025"]="Windows Server 2025"
    ["server_2022"]="Windows Server 2022"
    ["server_2019"]="Windows Server 2019"
    ["server_2016"]="Windows Server 2016"
)

# DD 镜像
declare -A DD_IMAGES=(
    ["tiny10"]="https://dl.lamp.sh/vhd/tiny10_21h2/tiny10_21h2.xz"
    ["tiny11"]="https://dl.lamp.sh/vhd/tiny11_23h2/tiny11_23h2.xz"
)

# ==================== 辅助函数 ====================

clear_screen() {
    clear 2>/dev/null || true
}

print_logo() {
    echo -e "${CYAN}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ██████╗ ██████╗     ██████╗ ███████╗██╗███╗   ██╗███████╗  ║
║   ██╔══██╗██╔══██╗    ██╔══██╗██╔════╝██║████╗  ██║██╔════╝  ║
║   ██║  ██║██║  ██║    ██████╔╝█████╗  ██║██╔██╗ ██║███████╗  ║
║   ██║  ██║██║  ██║    ██╔══██╗██╔══╝  ██║██║╚██╗██║╚════██║  ║
║   ██████╔╝██████╔╝    ██║  ██║███████╗██║██║ ╚████║███████║  ║
║   ╚═════╝ ╚═════╝     ╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝  ║
║                                                               ║
EOF
    echo -e "║              DD Reinstall Script v${VERSION}                     ║"
    echo "║         一键DD重装系统 | Auto Region Detection                ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_line() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# ==================== 检测函数 ====================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本必须以 root 权限运行"
        log_info "请尝试: sudo bash $0"
        exit 1
    fi
}

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
}

check_boot_mode() {
    if [[ -d /sys/firmware/efi ]]; then
        BOOT_MODE="efi"
    else
        BOOT_MODE="bios"
    fi
}

check_virt() {
    local virt_type=""
    if command -v systemd-detect-virt &>/dev/null; then
        virt_type=$(systemd-detect-virt 2>/dev/null || echo "none")
    fi
    
    case $virt_type in
        openvz|lxc|lxc-libvirt)
            log_error "不支持 OpenVZ/LXC 虚拟化环境"
            log_info "请使用: https://github.com/LloydAsp/OsMutation"
            exit 1
            ;;
    esac
}

check_network() {
    INTERFACE=$(ip route | awk '/default/ {print $5}' | head -1)
    if [[ -n "$INTERFACE" ]]; then
        IP_ADDR=$(ip -4 addr show "$INTERFACE" | awk '/inet / {print $2}' | cut -d'/' -f1 | head -1)
        GATEWAY=$(ip route | awk '/default/ {print $3}' | head -1)
        NETMASK=$(ip -4 addr show "$INTERFACE" | awk '/inet / {print $2}' | cut -d'/' -f2 | head -1)
    fi
}

detect_region() {
    local country=""
    local apis=(
        "https://ipapi.co/country_code"
        "https://ifconfig.co/country-iso"
        "https://api.ip.sb/geoip"
    )
    
    for api in "${apis[@]}"; do
        if country=$(curl -s --connect-timeout 3 --max-time 5 "$api" 2>/dev/null); then
            if [[ "$api" == *"ip.sb"* ]]; then
                country=$(echo "$country" | grep -oP '"country_code"\s*:\s*"\K[^"]+' || echo "")
            fi
            if [[ -n "$country" && ${#country} -le 3 ]]; then
                break
            fi
        fi
    done
    
    if [[ "$country" == "CN" ]]; then
        REGION="cn"
    else
        REGION="overseas"
    fi
}

check_memory() {
    local mem_mb
    mem_mb=$(free -m | awk '/Mem:/ {print $2}')
    echo "$mem_mb"
}

check_disk() {
    local disk_gb
    disk_gb=$(df -BG / | awk 'NR==2 {print $2}' | tr -d 'G')
    echo "$disk_gb"
}

generate_password() {
    tr -dc 'A-Za-z0-9!@#$%' </dev/urandom | head -c 16
}

# ==================== 镜像源测试 ====================

test_mirror_speed() {
    local mirror=$1
    local start_time end_time
    
    start_time=$(date +%s%N 2>/dev/null || date +%s)
    if curl -sI --connect-timeout 2 --max-time 3 "https://${mirror}/debian/" >/dev/null 2>&1; then
        end_time=$(date +%s%N 2>/dev/null || date +%s)
        echo $(( (end_time - start_time) / 1000000 ))
    else
        echo "9999"
    fi
}

select_cn_mirror() {
    local mirrors=(
        "mirrors.tuna.tsinghua.edu.cn"
        "mirrors.aliyun.com"
        "mirrors.cloud.tencent.com"
        "mirrors.ustc.edu.cn"
        "mirrors.163.com"
        "mirrors.huaweicloud.com"
        "mirrors.bfsu.edu.cn"
    )
    
    log_info "正在测试国内镜像源速度..."
    local fastest_mirror=""
    local fastest_time=9999
    
    for mirror in "${mirrors[@]}"; do
        echo -ne "  测试 ${mirror}... "
        local speed=$(test_mirror_speed "$mirror")
        if [[ "$speed" -lt 9999 ]]; then
            echo -e "${GREEN}${speed}ms${NC}"
            if [[ "$speed" -lt "$fastest_time" ]]; then
                fastest_time=$speed
                fastest_mirror=$mirror
            fi
        else
            echo -e "${RED}超时${NC}"
        fi
    done
    
    if [[ -n "$fastest_mirror" ]]; then
        SELECTED_MIRROR=$fastest_mirror
        log_success "选择最快镜像: $SELECTED_MIRROR (${fastest_time}ms)"
    else
        SELECTED_MIRROR="mirrors.tuna.tsinghua.edu.cn"
        log_warn "使用默认镜像: $SELECTED_MIRROR"
    fi
}

# ==================== 菜单函数 ====================

show_main_menu() {
    clear_screen
    print_logo
    print_line
    echo -e "${BOLD}  请选择操作${NC}"
    print_line
    echo ""
    echo -e "  ${GREEN}📦 系统安装${NC}"
    echo -e "    ${CYAN}1)${NC} 安装 Linux 系统"
    echo -e "    ${CYAN}2)${NC} 安装 Windows 系统 (官方 ISO)"
    echo -e "    ${CYAN}3)${NC} DD RAW 镜像到硬盘"
    echo ""
    echo -e "  ${GREEN}🔧 高级功能${NC}"
    echo -e "    ${CYAN}4)${NC} 重启到 Alpine Live OS (内存系统)"
    echo -e "    ${CYAN}5)${NC} 重启到 netboot.xyz"
    echo ""
    echo -e "  ${GREEN}📊 系统信息${NC}"
    echo -e "    ${CYAN}i)${NC} 查看当前系统信息"
    echo ""
    print_line
    echo -e "  ${RED}q)${NC} 退出脚本"
    print_line
    echo ""
}

show_linux_menu() {
    clear_screen
    print_logo
    print_line
    echo -e "${BOLD}  选择 Linux 发行版${NC}"
    print_line
    echo ""
    echo -e "  ${GREEN}Debian 系列${NC}"
    echo -e "    ${CYAN}1)${NC} Debian 13 (Trixie)"
    echo -e "    ${CYAN}2)${NC} Debian 12 (Bookworm)      ${YELLOW}推荐${NC}"
    echo -e "    ${CYAN}3)${NC} Debian 11 (Bullseye)"
    echo -e "    ${CYAN}4)${NC} Debian 10 (Buster)"
    echo ""
    echo -e "  ${GREEN}Ubuntu 系列${NC}"
    echo -e "    ${CYAN}5)${NC} Ubuntu 24.04 LTS          ${YELLOW}最新 LTS${NC}"
    echo -e "    ${CYAN}6)${NC} Ubuntu 22.04 LTS          ${YELLOW}推荐${NC}"
    echo -e "    ${CYAN}7)${NC} Ubuntu 20.04 LTS"
    echo -e "    ${CYAN}8)${NC} Ubuntu 18.04 LTS"
    echo ""
    echo -e "  ${GREEN}RHEL 系列${NC}"
    echo -e "    ${CYAN}10)${NC} CentOS 10 Stream"
    echo -e "    ${CYAN}11)${NC} CentOS 9 Stream"
    echo -e "    ${CYAN}12)${NC} AlmaLinux 9"
    echo -e "    ${CYAN}13)${NC} Rocky Linux 9"
    echo -e "    ${CYAN}14)${NC} Fedora 43"
    echo -e "    ${CYAN}15)${NC} Oracle Linux 9"
    echo ""
    echo -e "  ${GREEN}其他发行版${NC}"
    echo -e "    ${CYAN}20)${NC} Alpine 3.21               ${YELLOW}轻量级${NC}"
    echo -e "    ${CYAN}21)${NC} Arch Linux"
    echo -e "    ${CYAN}22)${NC} openSUSE 15.6"
    echo -e "    ${CYAN}23)${NC} Kali Linux"
    echo -e "    ${CYAN}24)${NC} NixOS"
    echo -e "    ${CYAN}25)${NC} Gentoo"
    echo ""
    echo -e "  ${GREEN}国产系统${NC}"
    echo -e "    ${CYAN}30)${NC} Anolis OS 8"
    echo -e "    ${CYAN}31)${NC} OpenCloudOS 9"
    echo -e "    ${CYAN}32)${NC} openEuler 24.03"
    echo ""
    print_line
    echo -e "  ${RED}0)${NC} 返回上级菜单"
    print_line
    echo ""
}

show_windows_menu() {
    clear_screen
    print_logo
    print_line
    echo -e "${BOLD}  选择 Windows 版本${NC}"
    print_line
    echo ""
    echo -e "  ${GREEN}Windows 11${NC}"
    echo -e "    ${CYAN}1)${NC} Windows 11 Enterprise LTSC 2024   ${YELLOW}推荐${NC}"
    echo -e "    ${CYAN}2)${NC} Windows 11 23H2"
    echo ""
    echo -e "  ${GREEN}Windows 10${NC}"
    echo -e "    ${CYAN}3)${NC} Windows 10 Enterprise LTSC 2021   ${YELLOW}推荐${NC}"
    echo -e "    ${CYAN}4)${NC} Windows 10 22H2"
    echo ""
    echo -e "  ${GREEN}Windows Server${NC}"
    echo -e "    ${CYAN}10)${NC} Windows Server 2025"
    echo -e "    ${CYAN}11)${NC} Windows Server 2022"
    echo -e "    ${CYAN}12)${NC} Windows Server 2019"
    echo -e "    ${CYAN}13)${NC} Windows Server 2016"
    echo ""
    echo -e "  ${GREEN}自定义${NC}"
    echo -e "    ${CYAN}20)${NC} 指定 ISO URL"
    echo ""
    print_line
    echo -e "  ${RED}0)${NC} 返回上级菜单"
    print_line
    echo ""
}

show_dd_menu() {
    clear_screen
    print_logo
    print_line
    echo -e "${BOLD}  DD RAW 镜像${NC}"
    print_line
    echo ""
    echo -e "  ${GREEN}精简版 Windows (第三方镜像)${NC}"
    echo -e "    ${CYAN}1)${NC} Tiny10 (Windows 10 精简版)"
    echo -e "    ${CYAN}2)${NC} Tiny11 (Windows 11 精简版)"
    echo ""
    echo -e "  ${GREEN}自定义${NC}"
    echo -e "    ${CYAN}10)${NC} 输入自定义 DD 镜像 URL"
    echo ""
    echo -e "  ${YELLOW}支持格式: raw, vhd${NC}"
    echo -e "  ${YELLOW}支持压缩: .gz, .xz, .zst, .tar${NC}"
    echo ""
    print_line
    echo -e "  ${RED}0)${NC} 返回上级菜单"
    print_line
    echo ""
}

show_system_info() {
    clear_screen
    print_logo
    print_line
    echo -e "${BOLD}  系统信息${NC}"
    print_line
    echo ""
    echo -e "  ${CYAN}地区:${NC}         $([ "$REGION" == "cn" ] && echo "中国大陆" || echo "海外")"
    echo -e "  ${CYAN}架构:${NC}         $ARCH"
    echo -e "  ${CYAN}引导模式:${NC}     $BOOT_MODE"
    echo -e "  ${CYAN}内存:${NC}         $(check_memory) MB"
    echo -e "  ${CYAN}磁盘:${NC}         $(check_disk) GB"
    echo ""
    echo -e "  ${CYAN}网络接口:${NC}     $INTERFACE"
    echo -e "  ${CYAN}IP 地址:${NC}      $IP_ADDR"
    echo -e "  ${CYAN}网关:${NC}         $GATEWAY"
    if [[ -n "$SELECTED_MIRROR" ]]; then
        echo -e "  ${CYAN}镜像源:${NC}       $SELECTED_MIRROR"
    fi
    echo ""
    print_line
    echo ""
    echo -e "按任意键返回..."
    read -r -n 1
}

# ==================== 处理菜单选择 ====================

handle_linux_choice() {
    local choice=$1
    
    case $choice in
        1) DISTRO="debian"; VERSION_ID="13" ;;
        2) DISTRO="debian"; VERSION_ID="12" ;;
        3) DISTRO="debian"; VERSION_ID="11" ;;
        4) DISTRO="debian"; VERSION_ID="10" ;;
        5) DISTRO="ubuntu"; VERSION_ID="24.04" ;;
        6) DISTRO="ubuntu"; VERSION_ID="22.04" ;;
        7) DISTRO="ubuntu"; VERSION_ID="20.04" ;;
        8) DISTRO="ubuntu"; VERSION_ID="18.04" ;;
        10) DISTRO="centos"; VERSION_ID="10" ;;
        11) DISTRO="centos"; VERSION_ID="9" ;;
        12) DISTRO="almalinux"; VERSION_ID="9" ;;
        13) DISTRO="rocky"; VERSION_ID="9" ;;
        14) DISTRO="fedora"; VERSION_ID="43" ;;
        15) DISTRO="oracle"; VERSION_ID="9" ;;
        20) DISTRO="alpine"; VERSION_ID="3.21" ;;
        21) DISTRO="arch"; VERSION_ID="" ;;
        22) DISTRO="opensuse"; VERSION_ID="15.6" ;;
        23) DISTRO="kali"; VERSION_ID="" ;;
        24) DISTRO="nixos"; VERSION_ID="" ;;
        25) DISTRO="gentoo"; VERSION_ID="" ;;
        30) DISTRO="anolis"; VERSION_ID="8" ;;
        31) DISTRO="opencloudos"; VERSION_ID="9" ;;
        32) DISTRO="openeuler"; VERSION_ID="24.03" ;;
        0) return 1 ;;
        *) log_error "无效选项"; sleep 1; return 1 ;;
    esac
    return 0
}

handle_windows_choice() {
    local choice=$1
    
    case $choice in
        1)
            WINDOWS_IMAGE_NAME="Windows 11 Enterprise LTSC 2024"
            WINDOWS_LANG="zh-cn"
            ;;
        2)
            WINDOWS_IMAGE_NAME="Windows 11 Pro"
            WINDOWS_LANG="zh-cn"
            ;;
        3)
            WINDOWS_IMAGE_NAME="Windows 10 Enterprise LTSC 2021"
            WINDOWS_LANG="zh-cn"
            ;;
        4)
            WINDOWS_IMAGE_NAME="Windows 10 Pro"
            WINDOWS_LANG="zh-cn"
            ;;
        10)
            WINDOWS_IMAGE_NAME="Windows Server 2025 SERVERDATACENTER"
            WINDOWS_LANG="zh-cn"
            ;;
        11)
            WINDOWS_IMAGE_NAME="Windows Server 2022 SERVERDATACENTER"
            WINDOWS_LANG="zh-cn"
            ;;
        12)
            WINDOWS_IMAGE_NAME="Windows Server 2019 SERVERDATACENTER"
            WINDOWS_LANG="zh-cn"
            ;;
        13)
            WINDOWS_IMAGE_NAME="Windows Server 2016 SERVERDATACENTER"
            WINDOWS_LANG="zh-cn"
            ;;
        20)
            echo -e "${CYAN}请输入 Windows ISO URL:${NC}"
            read -r -p ">>> " iso_url
            echo -e "${CYAN}请输入镜像名称 (如 'Windows 11 Pro'):${NC}"
            read -r -p ">>> " WINDOWS_IMAGE_NAME
            DD_URL=$iso_url
            ;;
        0) return 1 ;;
        *) log_error "无效选项"; sleep 1; return 1 ;;
    esac
    return 0
}

handle_dd_choice() {
    local choice=$1
    
    case $choice in
        1) DD_URL="${DD_IMAGES[tiny10]}" ;;
        2) DD_URL="${DD_IMAGES[tiny11]}" ;;
        10)
            echo -e "${CYAN}请输入 DD 镜像 URL:${NC}"
            read -r -p ">>> " DD_URL
            if [[ -z "$DD_URL" ]]; then
                log_error "URL 不能为空"
                return 1
            fi
            ;;
        0) return 1 ;;
        *) log_error "无效选项"; sleep 1; return 1 ;;
    esac
    return 0
}

# ==================== 用户配置 ====================

input_linux_config() {
    clear_screen
    print_logo
    print_line
    echo -e "${BOLD}  Linux 安装配置${NC}"
    print_line
    echo ""
    
    # 密码
    echo -e "${CYAN}设置 root 密码 (留空自动生成):${NC}"
    read -r -s -p ">>> " input_password
    echo ""
    if [[ -n "$input_password" ]]; then
        PASSWORD=$input_password
    else
        PASSWORD=$(generate_password)
        echo -e "${YELLOW}已生成随机密码: ${GREEN}$PASSWORD${NC}"
    fi
    echo ""
    
    # SSH 端口
    echo -e "${CYAN}SSH 端口 (默认: 22):${NC}"
    read -r -p ">>> " input_ssh_port
    if [[ -n "$input_ssh_port" && "$input_ssh_port" =~ ^[0-9]+$ ]]; then
        SSH_PORT=$input_ssh_port
    fi
    echo ""
    
    # SSH 公钥
    echo -e "${CYAN}SSH 公钥 (可选, 留空跳过):${NC}"
    read -r -p ">>> " SSH_KEY
    echo ""
    
    # 云镜像模式 (仅 Debian)
    if [[ "$DISTRO" == "debian" ]]; then
        echo -e "${CYAN}使用云镜像安装? (适合 CPU 较慢的机器) [y/N]:${NC}"
        read -r -p ">>> " use_ci
        if [[ "$use_ci" =~ ^[Yy]$ ]]; then
            CI_MODE="--ci"
        fi
    fi
    
    print_line
}

input_windows_config() {
    clear_screen
    print_logo
    print_line
    echo -e "${BOLD}  Windows 安装配置${NC}"
    print_line
    echo ""
    
    # 密码
    echo -e "${CYAN}设置 Administrator 密码 (留空自动生成):${NC}"
    read -r -s -p ">>> " input_password
    echo ""
    if [[ -n "$input_password" ]]; then
        PASSWORD=$input_password
    else
        PASSWORD=$(generate_password)
        echo -e "${YELLOW}已生成随机密码: ${GREEN}$PASSWORD${NC}"
    fi
    echo ""
    
    # 语言
    echo -e "${CYAN}选择语言:${NC}"
    echo -e "  ${CYAN}1)${NC} 中文 (zh-cn)"
    echo -e "  ${CYAN}2)${NC} 英文 (en-us)"
    read -r -p ">>> " lang_choice
    case $lang_choice in
        1) WINDOWS_LANG="zh-cn" ;;
        2) WINDOWS_LANG="en-us" ;;
        *) WINDOWS_LANG="zh-cn" ;;
    esac
    echo ""
    
    # 允许 Ping
    echo -e "${CYAN}允许被 Ping? [Y/n]:${NC}"
    read -r -p ">>> " allow_ping
    if [[ ! "$allow_ping" =~ ^[Nn]$ ]]; then
        ALLOW_PING="--allow-ping"
    fi
    echo ""
    
    # RDP 端口
    echo -e "${CYAN}RDP 端口 (默认: 3389):${NC}"
    read -r -p ">>> " input_rdp_port
    if [[ -n "$input_rdp_port" && "$input_rdp_port" =~ ^[0-9]+$ ]]; then
        RDP_PORT="--rdp-port $input_rdp_port"
    fi
    
    print_line
}

# ==================== 确认安装 ====================

confirm_installation() {
    local install_type=$1
    
    clear_screen
    print_logo
    print_line
    echo -e "${BOLD}  安装确认${NC}"
    print_line
    echo ""
    
    case $install_type in
        linux)
            echo -e "  ${CYAN}目标系统:${NC}     ${GREEN}$DISTRO $VERSION_ID${NC}"
            echo -e "  ${CYAN}密码:${NC}         ${GREEN}$PASSWORD${NC}"
            echo -e "  ${CYAN}SSH 端口:${NC}     ${GREEN}$SSH_PORT${NC}"
            if [[ -n "$SSH_KEY" ]]; then
                echo -e "  ${CYAN}SSH 公钥:${NC}     ${GREEN}已设置${NC}"
            fi
            if [[ -n "$CI_MODE" ]]; then
                echo -e "  ${CYAN}安装模式:${NC}     ${GREEN}云镜像${NC}"
            fi
            ;;
        windows)
            echo -e "  ${CYAN}目标系统:${NC}     ${GREEN}$WINDOWS_IMAGE_NAME${NC}"
            echo -e "  ${CYAN}语言:${NC}         ${GREEN}$WINDOWS_LANG${NC}"
            echo -e "  ${CYAN}密码:${NC}         ${GREEN}$PASSWORD${NC}"
            ;;
        dd)
            echo -e "  ${CYAN}DD 镜像:${NC}      ${GREEN}$DD_URL${NC}"
            ;;
    esac
    
    if [[ "$REGION" == "cn" && -n "$SELECTED_MIRROR" ]]; then
        echo -e "  ${CYAN}镜像源:${NC}       ${GREEN}$SELECTED_MIRROR${NC}"
    fi
    echo ""
    print_line
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                         ⚠ 警告 ⚠                          ║${NC}"
    echo -e "${RED}║                                                            ║${NC}"
    echo -e "${RED}║   此操作将清除整个硬盘的全部数据（包含其它分区）！         ║${NC}"
    echo -e "${RED}║   数据无价，请三思而后行！                                 ║${NC}"
    echo -e "${RED}║                                                            ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}请输入 ${GREEN}YES${YELLOW} 确认安装，其他任意键取消:${NC}"
    read -r -p ">>> " confirm
    
    confirm_upper=$(echo "$confirm" | tr '[:lower:]' '[:upper:]')
    if [[ "$confirm_upper" != "YES" ]]; then
        log_info "安装已取消"
        return 1
    fi
    return 0
}

# ==================== 执行安装 ====================

download_reinstall_script() {
    log_info "正在下载安装脚本..."
    
    local script_url="https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh"
    if [[ "$REGION" == "cn" ]]; then
        script_url="https://cnb.cool/bin456789/reinstall/-/git/raw/main/reinstall.sh"
    fi
    
    if curl -sL "$script_url" -o /tmp/reinstall.sh 2>/dev/null || \
       wget -qO /tmp/reinstall.sh "$script_url" 2>/dev/null; then
        chmod +x /tmp/reinstall.sh
        log_success "脚本下载完成"
        return 0
    else
        log_error "无法下载安装脚本"
        return 1
    fi
}

execute_linux_install() {
    if ! download_reinstall_script; then
        return 1
    fi
    
    local args="$DISTRO"
    if [[ -n "$VERSION_ID" ]]; then
        args="$args $VERSION_ID"
    fi
    
    # 添加参数
    args="$args --password \"$PASSWORD\""
    args="$args --ssh-port $SSH_PORT"
    
    if [[ -n "$SSH_KEY" ]]; then
        args="$args --ssh-key \"$SSH_KEY\""
    fi
    
    if [[ -n "$CI_MODE" ]]; then
        args="$args $CI_MODE"
    fi
    
    show_install_info
    
    eval "bash /tmp/reinstall.sh $args"
}

execute_windows_install() {
    if ! download_reinstall_script; then
        return 1
    fi
    
    local args="windows"
    args="$args --image-name \"$WINDOWS_IMAGE_NAME\""
    args="$args --lang $WINDOWS_LANG"
    args="$args --password \"$PASSWORD\""
    
    if [[ -n "$ALLOW_PING" ]]; then
        args="$args $ALLOW_PING"
    fi
    
    if [[ -n "$RDP_PORT" ]]; then
        args="$args $RDP_PORT"
    fi
    
    if [[ -n "$DD_URL" ]]; then
        args="$args --iso \"$DD_URL\""
    fi
    
    show_install_info
    
    eval "bash /tmp/reinstall.sh $args"
}

execute_dd_install() {
    if ! download_reinstall_script; then
        return 1
    fi
    
    local args="dd --img \"$DD_URL\""
    
    if [[ -n "$ALLOW_PING" ]]; then
        args="$args $ALLOW_PING"
    fi
    
    show_install_info
    
    eval "bash /tmp/reinstall.sh $args"
}

execute_alpine_live() {
    if ! download_reinstall_script; then
        return 1
    fi
    
    log_info "正在准备 Alpine Live OS..."
    log_warn "此功能不会删除数据，重启后可回到原系统"
    
    bash /tmp/reinstall.sh alpine --hold 1
}

execute_netboot() {
    if ! download_reinstall_script; then
        return 1
    fi
    
    log_info "正在准备 netboot.xyz..."
    log_warn "此功能不会删除数据，重启后可回到原系统"
    
    bash /tmp/reinstall.sh netboot.xyz
}

show_install_info() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    开始安装...                             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}请记住以下信息:${NC}"
    echo ""
    echo -e "    ${CYAN}密码:${NC}     ${GREEN}$PASSWORD${NC}"
    echo -e "    ${CYAN}SSH 端口:${NC} ${GREEN}$SSH_PORT${NC}"
    echo ""
    echo -e "  ${YELLOW}安装完成后请使用上述信息登录${NC}"
    echo -e "  ${YELLOW}可通过 SSH、HTTP 80 端口、VNC 查看安装进度${NC}"
    echo ""
    sleep 3
}

# ==================== 主函数 ====================

main() {
    # 检查环境
    check_root
    check_arch
    check_boot_mode
    check_virt
    check_network
    detect_region
    
    # 显示地区信息
    if [[ "$REGION" == "cn" ]]; then
        log_success "检测到中国大陆服务器"
        select_cn_mirror
    else
        log_success "检测到海外服务器"
    fi
    
    sleep 1
    
    # 主菜单循环
    while true; do
        show_main_menu
        echo -e "${CYAN}请输入选项:${NC}"
        read -r -p ">>> " main_choice
        
        case $main_choice in
            1)  # Linux 安装
                while true; do
                    show_linux_menu
                    echo -e "${CYAN}请输入选项:${NC}"
                    read -r -p ">>> " linux_choice
                    
                    if handle_linux_choice "$linux_choice"; then
                        input_linux_config
                        if confirm_installation "linux"; then
                            execute_linux_install
                            exit 0
                        fi
                    else
                        break
                    fi
                done
                ;;
            2)  # Windows 安装
                while true; do
                    show_windows_menu
                    echo -e "${CYAN}请输入选项:${NC}"
                    read -r -p ">>> " windows_choice
                    
                    if handle_windows_choice "$windows_choice"; then
                        input_windows_config
                        if confirm_installation "windows"; then
                            execute_windows_install
                            exit 0
                        fi
                    else
                        break
                    fi
                done
                ;;
            3)  # DD 镜像
                while true; do
                    show_dd_menu
                    echo -e "${CYAN}请输入选项:${NC}"
                    read -r -p ">>> " dd_choice
                    
                    if handle_dd_choice "$dd_choice"; then
                        if confirm_installation "dd"; then
                            execute_dd_install
                            exit 0
                        fi
                    else
                        break
                    fi
                done
                ;;
            4)  # Alpine Live
                echo -e "${CYAN}设置临时 root 密码 (留空自动生成):${NC}"
                read -r -s -p ">>> " input_password
                echo ""
                if [[ -n "$input_password" ]]; then
                    PASSWORD=$input_password
                else
                    PASSWORD=$(generate_password)
                    echo -e "${YELLOW}临时密码: ${GREEN}$PASSWORD${NC}"
                fi
                execute_alpine_live
                exit 0
                ;;
            5)  # netboot.xyz
                execute_netboot
                exit 0
                ;;
            i|I)
                show_system_info
                ;;
            q|Q)
                log_info "退出脚本"
                exit 0
                ;;
            *)
                log_error "无效选项: $main_choice"
                sleep 1
                ;;
        esac
    done
}

# 运行主函数
main "$@"
