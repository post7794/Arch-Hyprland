#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  Arch-Hyprland Setup Script
#  Customized for post7794's personal dotfiles
#  Based on ViegPhunt/Arch-Hyprland with modifications
# ============================================================

# Variables
#----------------------------
start=$(date +%s)

PINK="\e[35m"
WHITE="\e[0m"
YELLOW="\e[33m"
GREEN="\e[32m"
BLUE="\e[34m"
CYAN="\e[36m"

DOTFILES_REPO="https://github.com/post7794/Dotfiles.git"
WALLPAPER_REPO="https://github.com/ViegPhunt/Wallpaper-Collection.git"

clear

# Welcome message
echo -e "${PINK}\e[1m
 ██╗  ██╗ █████╗  ██████╗██╗  ██╗███████╗██████╗
 ██║  ██║██╔══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗
 ███████║███████║██║     █████╔╝ █████╗  ██████╔╝
 ██╔══██║██╔══██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗
 ██║  ██║██║  ██║╚██████╗██║  ██╗███████╗██║  ██║
 ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
${WHITE}"
echo -e "${CYAN} Hyprland setup for Arch Linux — customized by \e[1;4mpost7794${WHITE}"
echo ""
echo -e "${PINK} *********************************************************************
 *                         ⚠️  \e[1;4mWARNING\e[0m${PINK}:                              *
 *               This script will modify your system!                *
 *         It will install Hyprland and several dependencies.        *
 *      Make sure you know what you are doing before continuing.     *
 *********************************************************************
\n"

# Confirm
echo -e "${YELLOW} Do you want to continue? [y/N]: \n"
read -r confirm
case "$confirm" in
    [yY][eE][sS]|[yY])
        echo -e "\n${GREEN}[OK]${CYAN} ==> Starting installation...\n${WHITE}"
        ;;
    *)
        echo -e "${BLUE}[NOTE]${CYAN} ==> Installation cancelled.\n${WHITE}"
        exit 1
        ;;
esac

cd ~

# ============================================================
# [1/13] System update
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[1/13]${PINK} ==> Updating system packages\n---------------------------------------------------------------------\n${WHITE}"
sudo pacman -Syu --noconfirm

# ============================================================
# [2/13] Install base dependencies
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[2/13]${PINK} ==> Installing base dependencies\n---------------------------------------------------------------------\n${WHITE}"
sudo pacman -S --noconfirm --needed git stow base-devel

# ============================================================
# [3/13] Clone dotfiles
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[3/13]${PINK} ==> Cloning dotfiles\n---------------------------------------------------------------------\n${WHITE}"
if [[ -d ~/dotfiles ]]; then
    echo -e "${YELLOW}[NOTE]${CYAN} ==> ~/dotfiles already exists, pulling latest changes...${WHITE}"
    cd ~/dotfiles && git pull && cd ~
else
    git clone --depth 1 "$DOTFILES_REPO" ~/dotfiles
fi

# ============================================================
# [4/13] Make scripts executable
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[4/13]${PINK} ==> Making scripts executable\n---------------------------------------------------------------------\n${WHITE}"
chmod +x ~/dotfiles/.config/viegphunt/*

# ============================================================
# [5/13] Download wallpapers
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[5/13]${PINK} ==> Downloading wallpapers\n---------------------------------------------------------------------\n${WHITE}"
mkdir -p ~/Pictures/Wallpapers
if [[ -z "$(ls -A ~/Pictures/Wallpapers 2>/dev/null)" ]]; then
    git clone --depth 1 "$WALLPAPER_REPO" ~/Wallpaper-Collection
    mv ~/Wallpaper-Collection/Wallpapers/* ~/Pictures/Wallpapers/
    rm -rf ~/Wallpaper-Collection
else
    echo -e "${YELLOW}[NOTE]${CYAN} ==> Wallpapers directory already has files, skipping download.${WHITE}"
fi

# ============================================================
# [6/13] Install packages
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[6/13]${PINK} ==> Installing packages\n---------------------------------------------------------------------\n${WHITE}"
sleep 0.5
~/dotfiles/.config/viegphunt/install_archpkg.sh

# ============================================================
# [7/13] Enable services
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[7/13]${PINK} ==> Enabling system services\n---------------------------------------------------------------------\n${WHITE}"
sleep 0.5
sudo systemctl enable --now bluetooth
sudo systemctl enable --now NetworkManager

# ============================================================
# [8/13] Set default terminal for Nemo
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[8/13]${PINK} ==> Setting Ghostty as default terminal for Nemo\n---------------------------------------------------------------------\n${WHITE}"
gsettings set org.cinnamon.desktop.default-applications.terminal exec ghostty

# ============================================================
# [9/13] Apply fonts & cursor
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[9/13]${PINK} ==> Applying fonts and cursor theme\n---------------------------------------------------------------------\n${WHITE}"
fc-cache -fv
~/dotfiles/.config/viegphunt/setcursor.sh

# ============================================================
# [10/13] Stow dotfiles
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[10/13]${PINK} ==> Stowing dotfiles\n---------------------------------------------------------------------\n${WHITE}"
cd ~/dotfiles
stow -t ~ .
cd ~

# ============================================================
# [11/13] Apply GTK themes
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[11/13]${PINK} ==> Applying GTK themes\n---------------------------------------------------------------------\n${WHITE}"
~/.config/viegphunt/gtkthemes.sh

# ============================================================
# [12/13] Configure display manager (SDDM)
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[12/13]${PINK} ==> Configuring display manager\n---------------------------------------------------------------------\n${WHITE}"
if [[ ! -e /etc/systemd/system/display-manager.service ]]; then
    sudo systemctl enable sddm
    # Write SDDM config (use > not >> to avoid duplicates)
    echo -e "[Theme]\nCurrent=sddm-astronaut-theme" | sudo tee /etc/sddm.conf > /dev/null
    sudo sed -i 's|astronaut.conf|purple_leaves.conf|' /usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop
    echo -e "\n${GREEN}[OK]${CYAN} ==> SDDM enabled with astronaut-theme (purple_leaves).${WHITE}"
else
    echo -e "${YELLOW}[NOTE]${CYAN} ==> Display manager already configured, skipping SDDM setup.${WHITE}"
fi

# ============================================================
# [13/13] Post-install setup
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[13/13]${PINK} ==> Post-install setup\n---------------------------------------------------------------------\n${WHITE}"

# Install oh-my-posh if not present
if ! command -v oh-my-posh &>/dev/null; then
    echo -e "${CYAN}  Installing oh-my-posh...${WHITE}"
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d /usr/local/bin
fi

# Install zinit for zsh
ZINIT_HOME="${ZDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
    echo -e "${CYAN}  Installing zinit...${WHITE}"
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Install tmux plugin manager
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
    echo -e "${CYAN}  Installing tmux plugin manager (TPM)...${WHITE}"
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Setup fcitx5 environment (write to profile.d so it's available for all sessions)
if [[ ! -f /etc/profile.d/fcitx5.sh ]]; then
    echo -e "${CYAN}  Writing fcitx5 environment to /etc/profile.d/fcitx5.sh...${WHITE}"
    echo 'export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS=@im=fcitx5
export INPUT_METHOD=fcitx5
export SDL_IM_MODULE=fcitx5' | sudo tee /etc/profile.d/fcitx5.sh > /dev/null
fi

# Fix cursor index.theme if not pointing to macOS
if [[ -f /usr/share/icons/default/index.theme ]]; then
    if ! grep -q "Inherits=macOS" /usr/share/icons/default/index.theme; then
        echo -e "${CYAN}  Fixing cursor theme...${WHITE}"
        mkdir -p ~/.icons/default/
        echo -e "[icon theme]\nInherits=macOS" > ~/.icons/default/index.theme
        sudo rm -f /usr/share/icons/default/index.theme
        sudo cp ~/.icons/default/index.theme /usr/share/icons/default/
    fi
fi

echo -e "${GREEN}[OK]${CYAN} ==> Post-install setup complete.${WHITE}"

# ============================================================
# Done
# ============================================================
sleep 0.7
clear

end=$(date +%s)
duration=$((end - start))
hours=$((duration / 3600))
minutes=$(((duration % 3600) / 60))
seconds=$((duration % 60))
printf -v minutes "%02d" "$minutes"
printf -v seconds "%02d" "$seconds"

echo -e "\n
 *********************************************************************
 *                    Hyprland setup is complete!                    *
 *                                                                   *
 *             Duration : $hours hours, $minutes minutes, $seconds seconds            *
 *                                                                   *
 *   It is recommended to \e[1;4mREBOOT\e[0m your system to apply all changes.   *
 *                                                                   *
 *                 \e[4mHave a great time with Hyprland!!${WHITE}                 *
 *********************************************************************
 \n
"
