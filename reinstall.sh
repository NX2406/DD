#!/bin/bash
#
# DD Reinstall Script - 一键DD重装系统脚本
# 支持交互式菜单选择，自动检测地区，国内使用清华源
#
# GitHub: https://github.com/NX2406/DD
# License: MIT
#

set -e

# ==================== 版本信息 ====================
VERSION="2.0.0"
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
USERNAME="root"     # 用户名
SSH_KEY=""          # SSH 公钥
SSH_PORT="22"       # SSH 端口
DD_URL=""           # DD 镜像 URL (用于 Windows)
INTERFACE=""        # 网络接口
IP_ADDR=""          # IP 地址
GATEWAY=""          # 网关
NETMASK=""          # 子网掩码
DNS1="8.8.8.8"      # DNS 1
DNS2="8.8.4.4"      # DNS 2
DISK=""             # 主磁盘
SELECTED_MIRROR=""  # 选择的镜像源

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

# ==================== 第三方 DD 镜像 ====================
declare -A DD_IMAGES=(
    # Windows 10
    ["win10_ltsc"]="https://api.moeclub.org/GoogleDrive/1cNMTqAvqV7lQDODNbXnfPp9bMCNnLny7"
    ["win10_22h2"]="https://api.moeclub.org/GoogleDrive/1O5gBilNno1JG7Mrg1bRGH7_bviVN3OND"
    # Windows 11
    ["win11_23h2"]="https://api.moeclub.org/GoogleDrive/1RFD4l1MH7OaSy2VZFJtH3Xmn_RNb3EYp"
    # Windows Server
    ["win_server_2022"]="https://api.moeclub.org/GoogleDrive/1DsWVc8nFFN9IOD6wr11M5_sblyoVB8t7"
    ["win_server_2019"]="https://api.moeclub.org/GoogleDrive/1e4Z7_bQq2-aq7rTNEVfZkdMt1lfGdPe6"
)

# ==================== 辅助函数 ====================

# 清屏
clear_screen() {
    clear
}

# 打印 Logo
print_logo() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║   ██████╗ ██████╗     ██████╗ ███████╗██╗███╗   ██╗███████╗  ║"
    echo "║   ██╔══██╗██╔══██╗    ██╔══██╗██╔════╝██║████╗  ██║██╔════╝  ║"
    echo "║   ██║  ██║██║  ██║    ██████╔╝█████╗  ██║██╔██╗ ██║███████╗  ║"
    echo "║   ██║  ██║██║  ██║    ██╔══██╗██╔══╝  ██║██║╚██╗██║╚════██║  ║"
    echo "║   ██████╔╝██████╔╝    ██║  ██║███████╗██║██║ ╚████║███████║  ║"
    echo "║   ╚═════╝ ╚═════╝     ╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝  ║"
    echo "║                                                               ║"
    echo "║              DD Reinstall Script v${VERSION}                     ║"
    echo "║         一键DD重装系统 | Auto Region Detection                ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 打印分隔线
print_line() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
}

# 日志函数
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

# 按任意键继续
press_any_key() {
    echo ""
    read -n 1 -s -r -p "按任意键继续..."
    echo ""
}

# ==================== 检测函数 ====================

# 检测是否为 root 用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本必须以 root 权限运行"
        log_info "请尝试: sudo bash $0"
        exit 1
    fi
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
}

# 检测引导模式
check_boot_mode() {
    if [[ -d /sys/firmware/efi ]]; then
        BOOT_MODE="efi"
    else
        BOOT_MODE="bios"
    fi
}

# 检测虚拟化类型
check_virt() {
    local virt_type=""
    if command -v systemd-detect-virt &>/dev/null; then
        virt_type=$(systemd-detect-virt 2>/dev/null || echo "none")
    fi
    
    case $virt_type in
        openvz|lxc|lxc-libvirt)
            log_error "不支持 OpenVZ/LXC 虚拟化环境"
            exit 1
            ;;
    esac
}

# 检测内存
check_memory() {
    TOTAL_MEM=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
}

# 检测磁盘
check_disk() {
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
}

# 检测网络配置
check_network() {
    INTERFACE=$(ip route | awk '/default/ {print $5}' | head -1)
    
    if [[ -n "$INTERFACE" ]]; then
        IP_ADDR=$(ip -4 addr show "$INTERFACE" | awk '/inet / {print $2}' | cut -d'/' -f1 | head -1)
        local cidr=$(ip -4 addr show "$INTERFACE" | awk '/inet / {print $2}' | cut -d'/' -f2 | head -1)
        NETMASK=$(cidr_to_netmask "$cidr")
        GATEWAY=$(ip route | awk '/default/ {print $3}' | head -1)
    fi
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

# 检测地区
detect_region() {
    local country=""
    local apis=(
        "https://ipapi.co/country_code"
        "https://ifconfig.co/country-iso"
        "https://ipinfo.io/country"
    )
    
    for api in "${apis[@]}"; do
        if country=$(curl -s --connect-timeout 3 --max-time 5 "$api" 2>/dev/null); then
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

# 测试镜像速度 (返回毫秒)
test_mirror_speed() {
    local mirror=$1
    local test_path=$2
    local url="https://${mirror}${test_path}"
    
    local start_time=$(date +%s%3N 2>/dev/null || echo "0")
    if curl -sI --connect-timeout 3 --max-time 5 "$url" >/dev/null 2>&1; then
        local end_time=$(date +%s%3N 2>/dev/null || echo "0")
        echo $((end_time - start_time))
    else
        echo "9999"
    fi
}

# 选择最快的镜像源
select_fastest_mirror() {
    local mirrors=("$@")
    local test_path="/debian/dists/bookworm/Release"
    local fastest_mirror=""
    local fastest_time=9999
    
    log_info "正在测试镜像源速度..."
    
    for mirror in "${mirrors[@]}"; do
        echo -ne "  测试 ${mirror}... "
        local speed=$(test_mirror_speed "$mirror" "$test_path")
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
        log_success "选择最快镜像: $fastest_mirror (${fastest_time}ms)"
        echo "$fastest_mirror"
    else
        echo ""
    fi
}

# 选择镜像源
select_mirror() {
    if [[ "$REGION" == "cn" ]]; then
        # 国内多镜像源列表
        local cn_mirrors=(
            "mirrors.tuna.tsinghua.edu.cn"
            "mirrors.aliyun.com"
            "mirrors.cloud.tencent.com"
            "repo.huaweicloud.com"
            "mirrors.ustc.edu.cn"
            "mirrors.163.com"
            "mirrors.bfsu.edu.cn"
        )
        
        # 测试并选择最快的镜像
        SELECTED_MIRROR=$(select_fastest_mirror "${cn_mirrors[@]}")
        
        # 如果测试失败，使用默认镜像
        if [[ -z "$SELECTED_MIRROR" ]]; then
            log_warn "镜像测试失败，使用默认清华源"
            SELECTED_MIRROR=$MIRROR_TSINGHUA
        fi
    else
        # 海外多镜像源列表
        local overseas_mirrors=()
        case $DISTRO in
            debian)
                overseas_mirrors=(
                    "deb.debian.org"
                    "ftp.debian.org"
                    "mirrors.kernel.org"
                    "mirror.leaseweb.com"
                )
                ;;
            ubuntu)
                overseas_mirrors=(
                    "archive.ubuntu.com"
                    "mirrors.kernel.org"
                    "mirror.leaseweb.com"
                )
                ;;
            *)
                case $DISTRO in
                    centos) SELECTED_MIRROR=$MIRROR_CENTOS ;;
                    almalinux) SELECTED_MIRROR=$MIRROR_ALMALINUX ;;
                    rockylinux) SELECTED_MIRROR=$MIRROR_ROCKYLINUX ;;
                    fedora) SELECTED_MIRROR=$MIRROR_FEDORA ;;
                    alpine) SELECTED_MIRROR=$MIRROR_ALPINE ;;
                    *) SELECTED_MIRROR=$MIRROR_DEBIAN ;;
                esac
                return
                ;;
        esac
        
        # 测试海外镜像
        if [[ ${#overseas_mirrors[@]} -gt 0 ]]; then
            SELECTED_MIRROR=$(select_fastest_mirror "${overseas_mirrors[@]}")
            if [[ -z "$SELECTED_MIRROR" ]]; then
                log_warn "镜像测试失败，使用默认镜像"
                SELECTED_MIRROR=${overseas_mirrors[0]}
            fi
        fi
    fi
}

# 生成随机密码
generate_password() {
    tr -dc 'A-Za-z0-9!@#$%' </dev/urandom | head -c 16
}

# 安装依赖
install_dependencies() {
    if command -v apt-get &>/dev/null; then
        apt-get update -qq
        apt-get install -y -qq wget curl gawk grep sed >/dev/null 2>&1
    elif command -v yum &>/dev/null; then
        yum install -y -q wget curl gawk grep sed >/dev/null 2>&1
    elif command -v dnf &>/dev/null; then
        dnf install -y -q wget curl gawk grep sed >/dev/null 2>&1
    elif command -v apk &>/dev/null; then
        apk add --quiet wget curl gawk grep sed >/dev/null 2>&1
    fi
}

# ==================== 系统信息显示 ====================

show_system_info() {
    clear_screen
    print_logo
    print_line
    echo -e "${BOLD}  当前系统信息${NC}"
    print_line
    echo ""
    echo -e "  ${CYAN}CPU 架构:${NC}     $ARCH"
    echo -e "  ${CYAN}引导模式:${NC}     $BOOT_MODE"
    echo -e "  ${CYAN}内存大小:${NC}     ${TOTAL_MEM}MB"
    echo -e "  ${CYAN}磁盘设备:${NC}     $DISK (${DISK_SIZE_GB}GB)"
    echo -e "  ${CYAN}网络接口:${NC}     $INTERFACE"
    echo -e "  ${CYAN}IP 地址:${NC}      $IP_ADDR"
    echo -e "  ${CYAN}子网掩码:${NC}     $NETMASK"
    echo -e "  ${CYAN}网关:${NC}         $GATEWAY"
    echo -e "  ${CYAN}服务器位置:${NC}   $([ "$REGION" == "cn" ] && echo "中国大陆" || echo "海外")"
    echo ""
    print_line
}

# ==================== 主菜单 ====================

show_main_menu() {
    clear_screen
    print_logo
    print_line
    echo -e "${BOLD}  请选择要安装的系统${NC}"
    print_line
    echo ""
    echo -e "  ${GREEN}Debian 系列${NC}"
    echo -e "    ${CYAN}1)${NC} Debian 12 (Bookworm)    - 推荐"
    echo -e "    ${CYAN}2)${NC} Debian 11 (Bullseye)"
    echo -e "    ${CYAN}3)${NC} Debian 10 (Buster)"
    echo ""
    echo -e "  ${GREEN}Ubuntu 系列${NC}"
    echo -e "    ${CYAN}4)${NC} Ubuntu 24.04 LTS        - 最新 LTS"
    echo -e "    ${CYAN}5)${NC} Ubuntu 22.04 LTS        - 推荐"
    echo -e "    ${CYAN}6)${NC} Ubuntu 20.04 LTS"
    echo ""
    echo -e "  ${GREEN}RHEL 系列${NC}"
    echo -e "    ${CYAN}7)${NC} CentOS 9 Stream"
    echo -e "    ${CYAN}8)${NC} AlmaLinux 9"
    echo -e "    ${CYAN}9)${NC} RockyLinux 9"
    echo -e "    ${CYAN}10)${NC} Fedora 40"
    echo ""
    echo -e "  ${GREEN}其他系统${NC}"
    echo -e "    ${CYAN}11)${NC} Alpine 3.20             - 轻量级"
    echo ""
    echo -e "  ${GREEN}Windows (DD 镜像)${NC}"
    echo -e "    ${CYAN}20)${NC} Windows 10 LTSC 2021"
    echo -e "    ${CYAN}21)${NC} Windows 10 22H2"
    echo -e "    ${CYAN}22)${NC} Windows 11 23H2"
    echo -e "    ${CYAN}23)${NC} Windows Server 2022"
    echo -e "    ${CYAN}24)${NC} Windows Server 2019"
    echo -e "    ${CYAN}25)${NC} 自定义 DD 镜像 URL"
    echo ""
    print_line
    echo -e "  ${YELLOW}0)${NC} 显示系统信息"
    echo -e "  ${RED}q)${NC} 退出脚本"
    print_line
    echo ""
}

# ==================== 用户配置输入 ====================

input_user_config() {
    clear_screen
    print_logo
    print_line
    echo -e "${BOLD}  用户配置${NC}"
    print_line
    echo ""
    
    # 用户名输入
    echo -e "${CYAN}设置用户名 (默认: root):${NC}"
    read -r -p ">>> " input_username
    if [[ -n "$input_username" ]]; then
        USERNAME=$input_username
    else
        USERNAME="root"
    fi
    echo ""
    
    # 密码输入
    echo -e "${CYAN}设置密码 (留空自动生成):${NC}"
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
    echo -e "${CYAN}设置 SSH 端口 (默认: 22):${NC}"
    read -r -p ">>> " input_ssh_port
    if [[ -n "$input_ssh_port" && "$input_ssh_port" =~ ^[0-9]+$ ]]; then
        SSH_PORT=$input_ssh_port
    else
        SSH_PORT="22"
    fi
    echo ""
    
    # SSH 公钥 (可选)
    echo -e "${CYAN}设置 SSH 公钥 (可选，直接回车跳过):${NC}"
    read -r -p ">>> " input_ssh_key
    if [[ -n "$input_ssh_key" ]]; then
        SSH_KEY=$input_ssh_key
    fi
    echo ""
    
    print_line
}

# ==================== 确认安装 ====================

confirm_installation() {
    clear_screen
    print_logo
    print_line
    echo -e "${BOLD}  安装确认${NC}"
    print_line
    echo ""
    echo -e "  ${CYAN}目标系统:${NC}     ${GREEN}$DISTRO $VERSION_ID${NC}"
    echo -e "  ${CYAN}用户名:${NC}       $USERNAME"
    echo -e "  ${CYAN}密码:${NC}         $PASSWORD"
    echo -e "  ${CYAN}SSH 端口:${NC}     $SSH_PORT"
    echo -e "  ${CYAN}目标磁盘:${NC}     $DISK"
    echo -e "  ${CYAN}镜像源:${NC}       $SELECTED_MIRROR"
    if [[ -n "$DD_URL" ]]; then
        echo -e "  ${CYAN}DD 镜像:${NC}      $DD_URL"
    fi
    echo ""
    print_line
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                        ⚠ 警告 ⚠                           ║${NC}"
    echo -e "${RED}║                                                            ║${NC}"
    echo -e "${RED}║  此操作将清除 ${DISK} 上的所有数据！                       ║${NC}"
    echo -e "${RED}║  操作不可逆转，请确保已备份重要数据！                      ║${NC}"
    echo -e "${RED}║                                                            ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}请输入 ${GREEN}YES${YELLOW} 确认安装，其他任意键取消:${NC}"
    read -r -p ">>> " confirm
    
    # 转换为大写进行比较
    confirm_upper=$(echo "$confirm" | tr '[:lower:]' '[:upper:]')
    if [[ "$confirm_upper" != "YES" ]]; then
        log_info "安装已取消"
        return 1
    fi
    return 0
}

# ==================== 安装函数 ====================

# 下载文件
download_file() {
    local url=$1
    local dest=$2
    
    if ! wget -q --show-progress -O "$dest" "$url"; then
        log_error "下载失败: $url"
        return 1
    fi
    return 0
}

# 配置 GRUB
setup_grub() {
    local kernel=$1
    local initrd=$2
    local append=$3
    
    cat > /boot/grub/custom.cfg << EOF
menuentry "DD Reinstall" {
    linux $kernel $append
    initrd $initrd
}
EOF
    
    if command -v grub2-mkconfig &>/dev/null; then
        grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null
    elif command -v grub-mkconfig &>/dev/null; then
        grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null
    fi
}

# 安装 Debian/Ubuntu
install_debian_ubuntu() {
    log_info "准备安装 $DISTRO $VERSION_ID..."
    
    select_mirror
    
    local base_url=""
    local codename=""
    
    # Debian/Ubuntu 使用 amd64 而不是 x86_64
    local deb_arch="$ARCH"
    if [[ "$ARCH" == "x86_64" ]]; then
        deb_arch="amd64"
    elif [[ "$ARCH" == "aarch64" ]]; then
        deb_arch="arm64"
    fi
    
    if [[ "$DISTRO" == "debian" ]]; then
        case $VERSION_ID in
            10) codename="buster" ;;
            11) codename="bullseye" ;;
            12) codename="bookworm" ;;
            13) codename="trixie" ;;
            *) codename="bookworm" ;;
        esac
        
        if [[ "$REGION" == "cn" ]]; then
            base_url="https://${SELECTED_MIRROR}/debian/dists/${codename}/main/installer-${deb_arch}/current/images/netboot/debian-installer/${deb_arch}"
        else
            base_url="https://deb.debian.org/debian/dists/${codename}/main/installer-${deb_arch}/current/images/netboot/debian-installer/${deb_arch}"
        fi
    else
        # Ubuntu 使用代号而不是版本号
        local ubuntu_codename=""
        case $VERSION_ID in
            "24.04") ubuntu_codename="noble" ;;
            "22.04") ubuntu_codename="jammy" ;;
            "20.04") ubuntu_codename="focal" ;;
            *) ubuntu_codename="jammy" ;;
        esac
        
        if [[ "$REGION" == "cn" ]]; then
            base_url="https://${SELECTED_MIRROR}/ubuntu/dists/${ubuntu_codename}/main/installer-${deb_arch}/current/legacy-images/netboot/ubuntu-installer/${deb_arch}"
        else
            base_url="https://archive.ubuntu.com/ubuntu/dists/${ubuntu_codename}/main/installer-${deb_arch}/current/legacy-images/netboot/ubuntu-installer/${deb_arch}"
        fi
    fi
    
    mkdir -p /boot/netboot
    
    log_info "下载内核..."
    download_file "${base_url}/linux" "/boot/netboot/vmlinuz" || return 1
    
    log_info "下载 initrd..."
    download_file "${base_url}/initrd.gz" "/boot/netboot/initrd.gz" || return 1
    
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
    append+=" passwd/username=$USERNAME"
    
    if [[ "$REGION" == "cn" ]]; then
        append+=" mirror/http/hostname=$SELECTED_MIRROR"
        if [[ "$DISTRO" == "debian" ]]; then
            append+=" mirror/http/directory=/debian"
        else
            append+=" mirror/http/directory=/ubuntu"
        fi
    fi
    
    setup_grub "/boot/netboot/vmlinuz" "/boot/netboot/initrd.gz" "$append"
    
    log_success "$DISTRO $VERSION_ID 安装准备完成"
    return 0
}

# 安装 RHEL 系列
install_rhel() {
    log_info "准备安装 $DISTRO $VERSION_ID..."
    
    select_mirror
    
    local base_url=""
    
    case $DISTRO in
        centos)
            if [[ "$REGION" == "cn" ]]; then
                base_url="https://${SELECTED_MIRROR}/centos-stream/${VERSION_ID}-stream/BaseOS/${ARCH}/os/images/pxeboot"
            else
                base_url="https://mirror.stream.centos.org/${VERSION_ID}-stream/BaseOS/${ARCH}/os/images/pxeboot"
            fi
            ;;
        almalinux)
            if [[ "$REGION" == "cn" ]]; then
                base_url="https://${SELECTED_MIRROR}/almalinux/${VERSION_ID}/BaseOS/${ARCH}/os/images/pxeboot"
            else
                base_url="https://repo.almalinux.org/almalinux/${VERSION_ID}/BaseOS/${ARCH}/os/images/pxeboot"
            fi
            ;;
        rockylinux)
            if [[ "$REGION" == "cn" ]]; then
                base_url="https://${SELECTED_MIRROR}/rocky/${VERSION_ID}/BaseOS/${ARCH}/os/images/pxeboot"
            else
                base_url="https://download.rockylinux.org/pub/rocky/${VERSION_ID}/BaseOS/${ARCH}/os/images/pxeboot"
            fi
            ;;
        fedora)
            if [[ "$REGION" == "cn" ]]; then
                base_url="https://${SELECTED_MIRROR}/fedora/releases/${VERSION_ID}/Everything/${ARCH}/os/images/pxeboot"
            else
                base_url="https://download.fedoraproject.org/pub/fedora/linux/releases/${VERSION_ID}/Everything/${ARCH}/os/images/pxeboot"
            fi
            ;;
    esac
    
    mkdir -p /boot/netboot
    
    log_info "下载内核..."
    download_file "${base_url}/vmlinuz" "/boot/netboot/vmlinuz" || return 1
    
    log_info "下载 initrd..."
    download_file "${base_url}/initrd.img" "/boot/netboot/initrd.img" || return 1
    
    # 创建 Kickstart 配置
    create_kickstart
    
    local append="inst.ks=file:///boot/netboot/ks.cfg"
    append+=" ip=$IP_ADDR::$GATEWAY:$NETMASK::$INTERFACE:none"
    append+=" nameserver=$DNS1"
    
    setup_grub "/boot/netboot/vmlinuz" "/boot/netboot/initrd.img" "$append"
    
    log_success "$DISTRO $VERSION_ID 安装准备完成"
    return 0
}

# 创建 Kickstart 配置
create_kickstart() {
    local repo_url=""
    
    if [[ "$REGION" == "cn" ]]; then
        case $DISTRO in
            centos) repo_url="https://${SELECTED_MIRROR}/centos-stream/${VERSION_ID}-stream/BaseOS/${ARCH}/os/" ;;
            almalinux) repo_url="https://${SELECTED_MIRROR}/almalinux/${VERSION_ID}/BaseOS/${ARCH}/os/" ;;
            rockylinux) repo_url="https://${SELECTED_MIRROR}/rocky/${VERSION_ID}/BaseOS/${ARCH}/os/" ;;
            fedora) repo_url="https://${SELECTED_MIRROR}/fedora/releases/${VERSION_ID}/Everything/${ARCH}/os/" ;;
        esac
    else
        case $DISTRO in
            centos) repo_url="https://mirror.stream.centos.org/${VERSION_ID}-stream/BaseOS/${ARCH}/os/" ;;
            almalinux) repo_url="https://repo.almalinux.org/almalinux/${VERSION_ID}/BaseOS/${ARCH}/os/" ;;
            rockylinux) repo_url="https://download.rockylinux.org/pub/rocky/${VERSION_ID}/BaseOS/${ARCH}/os/" ;;
            fedora) repo_url="https://download.fedoraproject.org/pub/fedora/linux/releases/${VERSION_ID}/Everything/${ARCH}/os/" ;;
        esac
    fi
    
    cat > /boot/netboot/ks.cfg << EOF
#version=RHEL9
text
url --url="$repo_url"

keyboard --vckeymap=us --xlayouts='us'
lang en_US.UTF-8

network --bootproto=static --device=$INTERFACE --gateway=$GATEWAY --ip=$IP_ADDR --nameserver=$DNS1,$DNS2 --netmask=$NETMASK --activate
network --hostname=localhost.localdomain

rootpw --plaintext $PASSWORD
$(if [[ "$USERNAME" != "root" ]]; then echo "user --name=$USERNAME --password=$PASSWORD --plaintext --groups=wheel"; fi)

firewall --enabled --ssh
selinux --enforcing
services --enabled="chronyd,sshd"
timezone Asia/Shanghai --utc

bootloader --append="crashkernel=auto" --location=mbr
clearpart --all --initlabel
autopart --type=lvm

reboot

%packages
@^minimal-environment
@standard
chrony
openssh-server
wget
curl
sudo
%end

%post --log=/root/ks-post.log
sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i "s/^#Port.*/Port $SSH_PORT/" /etc/ssh/sshd_config
sed -i "s/^Port.*/Port $SSH_PORT/" /etc/ssh/sshd_config
systemctl restart sshd

$(if [[ -n "$SSH_KEY" ]]; then
cat << 'SSHKEY'
mkdir -p /root/.ssh
echo "$SSH_KEY" >> /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys
SSHKEY
fi)
%end
EOF
}

# 安装 Alpine
install_alpine() {
    log_info "准备安装 Alpine $VERSION_ID..."
    
    select_mirror
    
    local base_url=""
    if [[ "$REGION" == "cn" ]]; then
        base_url="https://${SELECTED_MIRROR}/alpine/v${VERSION_ID}/releases/${ARCH}"
    else
        base_url="https://dl-cdn.alpinelinux.org/alpine/v${VERSION_ID}/releases/${ARCH}"
    fi
    
    local iso_name="alpine-virt-${VERSION_ID}.0-${ARCH}.iso"
    
    mkdir -p /boot/netboot
    
    log_info "下载 Alpine ISO..."
    download_file "${base_url}/${iso_name}" "/boot/netboot/alpine.iso" || return 1
    
    log_info "提取安装文件..."
    mkdir -p /mnt/alpine
    mount -o loop /boot/netboot/alpine.iso /mnt/alpine
    cp /mnt/alpine/boot/vmlinuz-virt /boot/netboot/vmlinuz
    cp /mnt/alpine/boot/initramfs-virt /boot/netboot/initrd
    umount /mnt/alpine
    rmdir /mnt/alpine
    
    local append="ip=$IP_ADDR::$GATEWAY:$NETMASK::$INTERFACE:none"
    append+=" alpine_repo=https://${SELECTED_MIRROR}/alpine/v${VERSION_ID}/main"
    
    setup_grub "/boot/netboot/vmlinuz" "/boot/netboot/initrd" "$append"
    
    log_success "Alpine $VERSION_ID 安装准备完成"
    return 0
}

# 安装 Windows (DD)
install_windows() {
    log_info "准备安装 Windows (DD 镜像)..."
    log_info "DD 镜像: $DD_URL"
    
    local dd_ext="${DD_URL##*.}"
    local decompress_cmd=""
    
    case $dd_ext in
        gz|gzip) decompress_cmd="gzip -d -c" ;;
        xz) decompress_cmd="xz -d -c" ;;
        zst|zstd) decompress_cmd="zstd -d -c" ;;
        *) decompress_cmd="cat" ;;
    esac
    
    # 确保有解压工具
    case $dd_ext in
        xz)
            apt-get install -y xz-utils 2>/dev/null || yum install -y xz 2>/dev/null || true
            ;;
        zst|zstd)
            apt-get install -y zstd 2>/dev/null || yum install -y zstd 2>/dev/null || true
            ;;
    esac
    
    log_info "开始下载并写入 DD 镜像..."
    log_info "这可能需要 10-30 分钟，请耐心等待..."
    echo ""
    
    sync
    
    if wget -qO- "$DD_URL" | $decompress_cmd | dd of="$DISK" bs=4M status=progress conv=fsync 2>&1; then
        sync
        log_success "Windows DD 安装完成!"
        echo ""
        echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                    安装完成!                                 ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${CYAN}Windows 默认账户:${NC}"
        echo -e "    用户名: ${GREEN}Administrator${NC}"
        echo -e "    密码:   ${GREEN}Teddysun.com${NC} 或 ${GREEN}cxthhhhh.com${NC}"
        echo ""
        echo -e "  ${YELLOW}系统将在 10 秒后重启...${NC}"
        sleep 10
        reboot
    else
        log_error "DD 操作失败"
        return 1
    fi
}

# ==================== 完成安装 ====================

finish_installation() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    安装准备完成!                             ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}请记住以下信息:${NC}"
    echo ""
    echo -e "    ${CYAN}用户名:${NC}   ${GREEN}$USERNAME${NC}"
    echo -e "    ${CYAN}密码:${NC}     ${GREEN}$PASSWORD${NC}"
    echo -e "    ${CYAN}SSH 端口:${NC} ${GREEN}$SSH_PORT${NC}"
    echo ""
    echo -e "  ${YELLOW}系统将在 10 秒后重启并开始安装${NC}"
    echo -e "  ${YELLOW}安装过程可能需要 5-20 分钟${NC}"
    echo ""
    
    for i in {10..1}; do
        echo -ne "\r  重启倒计时: ${YELLOW}$i${NC} 秒  "
        sleep 1
    done
    
    echo ""
    log_info "正在重启..."
    reboot
}

# ==================== 主菜单处理 ====================

handle_menu_choice() {
    local choice=$1
    
    case $choice in
        1) DISTRO="debian"; VERSION_ID="12" ;;
        2) DISTRO="debian"; VERSION_ID="11" ;;
        3) DISTRO="debian"; VERSION_ID="10" ;;
        4) DISTRO="ubuntu"; VERSION_ID="24.04" ;;
        5) DISTRO="ubuntu"; VERSION_ID="22.04" ;;
        6) DISTRO="ubuntu"; VERSION_ID="20.04" ;;
        7) DISTRO="centos"; VERSION_ID="9" ;;
        8) DISTRO="almalinux"; VERSION_ID="9" ;;
        9) DISTRO="rockylinux"; VERSION_ID="9" ;;
        10) DISTRO="fedora"; VERSION_ID="40" ;;
        11) DISTRO="alpine"; VERSION_ID="3.20" ;;
        20) DISTRO="windows"; DD_URL="${DD_IMAGES[win10_ltsc]}" ;;
        21) DISTRO="windows"; DD_URL="${DD_IMAGES[win10_22h2]}" ;;
        22) DISTRO="windows"; DD_URL="${DD_IMAGES[win11_23h2]}" ;;
        23) DISTRO="windows"; DD_URL="${DD_IMAGES[win_server_2022]}" ;;
        24) DISTRO="windows"; DD_URL="${DD_IMAGES[win_server_2019]}" ;;
        25)
            DISTRO="windows"
            echo -e "${CYAN}请输入自定义 DD 镜像 URL:${NC}"
            read -r -p ">>> " DD_URL
            if [[ -z "$DD_URL" ]]; then
                log_error "DD 镜像 URL 不能为空"
                return 1
            fi
            ;;
        0)
            show_system_info
            press_any_key
            return 1
            ;;
        q|Q)
            log_info "退出脚本"
            exit 0
            ;;
        *)
            log_error "无效选项: $choice"
            sleep 1
            return 1
            ;;
    esac
    
    return 0
}

# ==================== 主函数 ====================

main() {
    # 检查权限
    check_root
    
    # 环境检测
    check_arch
    check_boot_mode
    check_virt
    check_memory
    check_disk
    check_network
    detect_region
    
    # 安装依赖
    install_dependencies
    
    # 主循环
    while true; do
        show_main_menu
        echo -e "${CYAN}请输入选项:${NC}"
        read -r -p ">>> " menu_choice
        
        if ! handle_menu_choice "$menu_choice"; then
            continue
        fi
        
        # Windows 不需要配置用户名密码
        if [[ "$DISTRO" != "windows" ]]; then
            input_user_config
        fi
        
        if ! confirm_installation; then
            continue
        fi
        
        # 执行安装
        case $DISTRO in
            debian|ubuntu)
                if install_debian_ubuntu; then
                    finish_installation
                fi
                ;;
            centos|almalinux|rockylinux|fedora)
                if install_rhel; then
                    finish_installation
                fi
                ;;
            alpine)
                if install_alpine; then
                    finish_installation
                fi
                ;;
            windows)
                install_windows
                ;;
        esac
        
        press_any_key
    done
}

# 运行主函数
main "$@"
