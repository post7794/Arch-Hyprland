# Arch Hyprland 一键部署

基于 [ViegPhunt/Arch-Hyprland](https://github.com/ViegPhunt/Arch-Hyprland) 定制的个人 Hyprland 桌面环境部署方案，主题从 Catppuccin Mocha 调整为 Kanagawa 风格。

## 目录

- [预览](#预览)
- [快捷键](#快捷键)
- [安装](#安装)
- [软件包清单](#软件包清单)
- [与原版的差异](#与原版的差异)
- [Dotfiles 仓库](#dotfiles-仓库)
- [致谢](#致谢)

## 预览

> [!IMPORTANT]
> 本脚本会自动化安装和配置 Arch Hyprland 桌面环境。使用前请确保是最小化安装的 Arch 系统，并提前备份重要数据。

> [!NOTE]
> 本脚本不包含卸载功能，部分软件包可能已在你的系统上存在。

## 快捷键

按 `Super + H`（Windows + H）打开快捷键提示面板。

| 快捷键 | 功能 |
|--------|------|
| `Super + Space` | 打开终端 |
| `Super + E` | 文件管理器 |
| `Super + B` | 浏览器 |
| `Alt + Space` | 应用启动器 |
| `Alt + Shift + Space` | 中文应用启动器 |
| `Super + .` | Emoji 选择器 |
| `Super + V` | 剪贴板管理器 |
| `Super + Shift + V` | 音量控制面板 |
| `Super + W` | 选择壁纸 |
| `Super + Shift + W` | 随机壁纸 |
| `Super + L` | 锁屏 |
| `Super + Q` | 关闭窗口 |
| `Super + Shift + Q` | 强制关闭窗口 |
| `Super + F` | 切换浮动 |
| `Super + D` | 显示桌面 |
| `Super + Shift + D` | 切换隐藏桌面 |
| `Super + Ctrl + D` | 固定隐藏桌面 |
| `Super + Shift + S` | 区域截图 |
| `Super + Alt + S` | 窗口截图 |
| `Super + Ctrl + S` | 全屏截图 |
| `Super + 1-0` | 切换工作区 1-10 |
| `Super + Shift + 1-0` | 移动窗口到工作区 |
| `Super + Shift + 方向键` | 交换窗口位置 |
| `Super + Ctrl + 方向键` | 调整窗口大小 |

## 安装

```bash
git clone --depth=1 https://github.com/post7794/Arch-Hyprland.git
cd Arch-Hyprland
chmod +x install.sh
./install.sh
```

安装脚本会依次执行以下步骤：

1. **系统更新** — `pacman -Syu`
2. **安装基础依赖** — git, stow, base-devel
3. **克隆 Dotfiles** — 从 [post7794/Dotfiles](https://github.com/post7794/Dotfiles) 拉取配置文件
4. **设置脚本权限** — `chmod +x`
5. **下载壁纸** — 从 [ViegPhunt/Wallpaper-Collection](https://github.com/ViegPhunt/Wallpaper-Collection) 下载
6. **安装软件包** — pacman + yay
7. **启用系统服务** — bluetooth, NetworkManager
8. **设置默认终端** — Ghostty 作为 Nemo 默认终端
9. **应用字体与光标主题** — fc-cache + macOS 光标
10. **Stow 部署配置** — 软链接 dotfiles 到 `~/`
11. **应用 GTK 主题** — adw-gtk3-dark + WhiteSur 图标
12. **配置 SDDM** — sddm-astronaut-theme (purple_leaves 配色)
13. **后置配置** — oh-my-posh, zinit, TPM, fcitx5 环境变量, 光标修复

## 软件包清单

### 官方仓库 (pacman)

| 类别 | 包名 |
|------|------|
| Hyprland/WM | hyprland, hyprlock, hypridle, awww, grim, slurp, swaync, waybar, rofi, rofi-emoji, yad, hyprshot, xdg-desktop-portal-hyprland/wlr/gtk |
| 系统 | brightnessctl, network-manager-applet, bluez, bluez-utils, blueman, pipewire, wireplumber, pavucontrol, playerctl |
| 应用 | ghostty, nemo, gvfs, loupe, celluloid, gnome-text-editor, evince, obs-studio, ffmpeg, cava |
| Shell/终端 | tmux, neovim, fzf, zoxide, eza, bat, jq, stow |
| 显示管理 | sddm, qt5ct, qt6ct, qt5-wayland, qt6-wayland |
| 输入法 | fcitx5, fcitx5-gtk, fcitx5-qt, fcitx5-configtool, fcitx5-bamboo |
| 字体 | ttf-jetbrains-mono-nerd, noto-fonts |
| 主题 | nwg-look, adw-gtk-theme, kvantum-qt5 |
| 杂项 | libvips, libheif, openslide, poppler-glib, cliphist, gnome-characters, keepass |

### AUR (yay)

| 类别 | 包名 |
|------|------|
| Hyprland | wlogout |
| 通讯/媒体 | spotify, zen-browser-bin |
| 编辑器 | visual-studio-code-bin |
| 字体/主题 | ttf-segoe-ui-variable, sddm-astronaut-theme, apple_cursor, whitesur-icon-theme, tint |
| 工具 | pokemon-colorscripts-git, lazygit, lazydocker |

## 与原版的差异

| 改动 | 原版 | 本版 |
|------|------|------|
| 壁纸工具 | swww | awww |
| 主题配色 | Catppuccin Mocha | Kanagawa |
| Ghostty 主题 | catppuccin-mocha | Kanagawa Wave |
| 默认浏览器 | brave | firefox |
| 锁屏空闲 | 无 | 5min 锁屏 / 5.5min 关屏 / 10min 休眠 |
| fcitx5 环境变量 | autostart (不生效) | environment.conf + profile.d |
| 窗口布局 | dwindle 默认 | dwindle + force_split=2 |
| 截图 | 仅区域截图 | 区域/窗口/全屏 |
| 隐藏桌面 | 无 | Super+D / Shift+D / Ctrl+D |
| Waybar | 工作区+电源 | 工作区+任务栏+电源 |
| Neovim | 4 个插件 | 20+ 插件 (LSP, 格式化, fzf-lua, oil 等) |
| 安装脚本 | curl\|bash 远程执行 | git clone + 幂等安装 |
| SDDM 配置 | tee -a (可能重复) | tee 覆盖写入 |
| oh-my-posh | AUR (已移除) | 官方脚本安装到 /usr/local/bin |

## Dotfiles 仓库

所有配置文件在 [post7794/Dotfiles](https://github.com/post7794/Dotfiles)，通过 `stow` 管理部署。

## 致谢

- [ViegPhunt/Arch-Hyprland](https://github.com/ViegPhunt/Arch-Hyprland) — 原版安装脚本
- [r/unixporn](https://www.reddit.com/r/unixporn/) — 社区灵感
- [JaKooLit/Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots)
- [Hyde-project/hyde](https://github.com/Hyde-project/hyde)
