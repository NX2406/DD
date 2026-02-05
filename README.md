# DD Reinstall Script

一键 DD 重装系统脚本，支持多种 Linux 发行版和 Windows，自动检测地区选择最优镜像源。

[![GitHub license](https://img.shields.io/github/license/NX2406/DD)](https://github.com/NX2406/DD/blob/main/LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/NX2406/DD)](https://github.com/NX2406/DD/stargazers)

## ✨ 功能特性

- 🌍 **自动地区检测**: 智能识别服务器位置，自动选择最优镜像源
- 🚀 **多系统支持**: Debian, Ubuntu, CentOS, AlmaLinux, RockyLinux, Fedora, Alpine, Windows
- 🔧 **全架构支持**: x86_64 和 aarch64 (ARM64)
- 💾 **双引导支持**: BIOS 和 EFI
- 🪞 **多镜像源**: 清华、阿里云、腾讯云、华为云、中科大
- 🪟 **Windows DD**: 支持第三方 DD 镜像安装 Windows

## 📋 系统要求

| 项目 | 要求 |
|------|------|
| 内存 | ≥ 256MB (Alpine), ≥ 512MB (其他) |
| 磁盘 | ≥ 5GB |
| 网络 | 可访问互联网 |
| 虚拟化 | ❌ 不支持 OpenVZ/LXC |

## 🚀 快速开始

### 下载脚本

**海外服务器:**
```bash
curl -O https://raw.githubusercontent.com/NX2406/DD/main/reinstall.sh && chmod +x reinstall.sh
```

**国内服务器:**
```bash
curl -O https://ghproxy.com/https://raw.githubusercontent.com/NX2406/DD/main/reinstall.sh && chmod +x reinstall.sh
```

### 安装 Linux

```bash
# Debian 12
bash reinstall.sh debian 12

# Ubuntu 22.04
bash reinstall.sh ubuntu 22.04

# CentOS 9
bash reinstall.sh centos 9

# AlmaLinux 9
bash reinstall.sh almalinux 9

# RockyLinux 9
bash reinstall.sh rockylinux 9

# Fedora 40
bash reinstall.sh fedora 40

# Alpine 3.20 (轻量级)
bash reinstall.sh alpine 3.20
```

### 安装 Windows (DD 镜像)

```bash
# 使用第三方 DD 镜像
bash reinstall.sh windows --dd https://dd.1024.vip/windows/lite/win10-ltsc-2021.gz

# 查看可用 DD 镜像源
bash reinstall.sh --list-dd
```

## 📖 参数说明

| 参数 | 说明 | 示例 |
|------|------|------|
| `--password` | 设置 root 密码 | `--password mypassword` |
| `--ssh-key` | 设置 SSH 公钥 | `--ssh-key "ssh-rsa AAAA..."` |
| `--ssh-port` | 设置 SSH 端口 | `--ssh-port 2222` |
| `--mirror` | 指定镜像源 | `--mirror cn` 或 `--mirror overseas` |
| `--dd` | DD 镜像 URL | `--dd https://example.com/win.gz` |
| `--force` | 跳过确认 | `--force` |
| `--dry-run` | 测试模式 | `--dry-run` |

## 🪞 镜像源

### 国内镜像源 (自动优选)

| 镜像源 | 域名 |
|--------|------|
| 清华大学 | mirrors.tuna.tsinghua.edu.cn |
| 阿里云 | mirrors.aliyun.com |
| 腾讯云 | mirrors.cloud.tencent.com |
| 华为云 | repo.huaweicloud.com |
| 中科大 | mirrors.ustc.edu.cn |

### 第三方 DD 镜像源

| 镜像源 | 说明 |
|--------|------|
| https://dd.1024.vip | Windows 精简版/原版 |
| https://a.disk.re | 多版本 Windows |
| https://dd.ci | Windows DD 镜像合集 |

## ⚠️ 注意事项

> **警告**: 此脚本会清除目标磁盘上的**所有数据**！请确保已备份重要文件。

- 安装前请确保 SSH 连接稳定，建议使用 screen/tmux
- 如安装失败，可能需要通过 VNC 控制台修复
- Windows DD 需要较长时间下载镜像，请耐心等待

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE)

## 🙏 致谢

- [leitbogioro/Tools](https://github.com/leitbogioro/Tools)
- [bin456789/reinstall](https://github.com/bin456789/reinstall)
- 清华大学开源软件镜像站

