# DD Reinstall Script

一键 DD 重装系统脚本，支持交互式菜单选择，自动检测地区选择最优镜像源。

[![GitHub license](https://img.shields.io/github/license/NX2406/DD)](https://github.com/NX2406/DD/blob/main/LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/NX2406/DD)](https://github.com/NX2406/DD/stargazers)

## ✨ 功能特性

- 🎯 **交互式菜单**: 无需记忆参数，菜单选择即可安装
- 🔐 **自定义账户**: 支持自定义用户名、密码、SSH 端口
- 🌍 **自动地区检测**: 智能识别位置，自动选择最优镜像源
- 🚀 **多系统支持**: Debian, Ubuntu, CentOS, AlmaLinux, RockyLinux, Fedora, Alpine, Windows
- 🪞 **多镜像源**: 清华、阿里云、腾讯云、华为云、中科大

## 📋 支持的系统

| 系列 | 版本 |
|------|------|
| Debian | 10, 11, 12, 13 |
| Ubuntu | 20.04, 22.04, 24.04 LTS |
| CentOS | 9 Stream |
| AlmaLinux | 9 |
| RockyLinux | 9 |
| Fedora | 40 |
| Alpine | 3.20 |
| Windows | 10 LTSC, 10 22H2, 11 23H2, Server 2019/2022 |

## 🚀 快速开始

### 一键安装（推荐）

**海外服务器:**
```bash
bash <(curl -sL https://raw.githubusercontent.com/NX2406/DD/main/reinstall.sh)
```

**国内服务器:**
```bash
bash <(curl -sL https://ghproxy.com/https://raw.githubusercontent.com/NX2406/DD/main/reinstall.sh)
```

运行后将立即显示交互式菜单，选择数字即可安装对应系统。

## ⚙️ 自定义配置示例

```
设置用户名 (默认: root):
>>> admin

设置密码 (留空自动生成):
>>> ********

设置 SSH 端口 (默认: 22):
>>> 2222

设置 SSH 公钥 (可选，直接回车跳过):
>>> ssh-rsa AAAA...
```

## ⚠️ 注意事项

> **警告**: 此脚本会清除目标磁盘上的**所有数据**！请确保已备份重要文件。

- 脚本会在安装前显示确认提示，输入 `YES` 确认
- 安装前请确保 SSH 连接稳定，建议使用 screen/tmux
- Windows DD 需要较长时间下载镜像，请耐心等待

## 🪞 镜像源

脚本会自动检测服务器位置并选择最优镜像源：

| 位置 | 镜像源 |
|------|--------|
| 中国大陆 | 清华大学 (mirrors.tuna.tsinghua.edu.cn) |
| 海外 | 官方镜像源 |

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE)

## 🙏 致谢

- [leitbogioro/Tools](https://github.com/leitbogioro/Tools)
- [bin456789/reinstall](https://github.com/bin456789/reinstall)
- 清华大学开源软件镜像站
