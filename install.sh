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
WALLPAPER_REPO="https://github.com/post7794/Wallpaper-Collection.git"

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
# [1/15] System update
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[1/15]${PINK} ==> Updating system packages\n---------------------------------------------------------------------\n${WHITE}"
sudo pacman -Syu --noconfirm

# ============================================================
# [2/15] Detect GPU and configure NVIDIA
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[2/15]${PINK} ==> Detecting GPU and configuring NVIDIA\n---------------------------------------------------------------------\n${WHITE}"
if lspci -k | grep -A3 VGA | grep -qi "nvidia"; then
    echo -e "${GREEN}[OK]${CYAN} ==> NVIDIA GPU detected, installing drivers...${WHITE}"

    # Detect kernel to choose the right nvidia package
    if [[ "$(uname -r)" == *"-zen"* ]]; then
        NVIDIA_PKG="nvidia-open-dkms"
        echo -e "${CYAN}  Detected linux-zen kernel, using ${NVIDIA_PKG}.${WHITE}"
    else
        NVIDIA_PKG="nvidia-open"
        echo -e "${CYAN}  Detected standard kernel, using ${NVIDIA_PKG}.${WHITE}"
    fi

    # Install NVIDIA packages
    sudo pacman -S --noconfirm --needed "${NVIDIA_PKG}" nvidia-utils nvidia-settings

    # Install kernel headers for DKMS (needed by nvidia-open-dkms)
    if [[ "${NVIDIA_PKG}" == "nvidia-open-dkms" ]]; then
        sudo pacman -S --noconfirm --needed linux-zen-headers
        sudo dkms autoinstall 2>/dev/null || true
    fi

    # Add nvidia modules to mkinitcpio
    if ! grep -q "nvidia" /etc/mkinitcpio.conf 2>/dev/null; then
        echo -e "${CYAN}  Adding NVIDIA modules to mkinitcpio...${WHITE}"
        sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm/' /etc/mkinitcpio.conf
    fi

    # Add nvidia-drm.modeset=1 to kernel parameters
    if [[ -f /etc/kernel/cmdline ]]; then
        # UKI (systemd-boot) method
        if ! grep -q "nvidia-drm.modeset=1" /etc/kernel/cmdline; then
            echo -e "${CYAN}  Adding nvidia-drm.modeset=1 to /etc/kernel/cmdline...${WHITE}"
            echo " $(cat /etc/kernel/cmdline) nvidia-drm.modeset=1" | sudo tee /etc/kernel/cmdline > /dev/null
        fi
    elif [[ -d /boot/loader/entries ]]; then
        # systemd-boot (non-UKI) method
        if ! grep -q "nvidia-drm.modeset=1" /boot/loader/entries/*.conf 2>/dev/null; then
            echo -e "${CYAN}  Adding nvidia-drm.modeset=1 to systemd-boot entries...${WHITE}"
            sudo sed -i 's/rw$/rw nvidia-drm.modeset=1/' /boot/loader/entries/*.conf
        fi
    elif [[ -f /etc/default/grub ]]; then
        # GRUB method
        if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
            echo -e "${CYAN}  Adding nvidia-drm.modeset=1 to GRUB...${WHITE}"
            sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1 /' /etc/default/grub
            sudo grub-mkconfig -o /boot/grub/grub.cfg
        fi
    else
        echo -e "${YELLOW}[NOTE]${CYAN} ==> Could not detect bootloader. Please manually add nvidia-drm.modeset=1 to your kernel parameters.${WHITE}"
    fi

    # Rebuild initramfs / UKI
    echo -e "${CYAN}  Rebuilding initramfs...${WHITE}"
    sudo mkinitcpio -P 2>/dev/null || sudo mkinitcpio -p linux-zen 2>/dev/null || true

    echo -e "${GREEN}[OK]${CYAN} ==> NVIDIA driver configured.${WHITE}"
else
    echo -e "${YELLOW}[NOTE]${CYAN} ==> No NVIDIA GPU detected, skipping NVIDIA setup.${WHITE}"
fi

# ============================================================
# [3/15] Setting locale
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[3/15]${PINK} ==> Setting locale\n---------------------------------------------------------------------\n${WHITE}"
sudo sed -i '/^#en_US.UTF-8 UTF-8/s/^#//' /etc/locale.gen
sudo locale-gen
# localectl may fail without D-Bus, fall back to writing locale.conf directly
if ! sudo localectl set-locale LANG=en_US.UTF-8 2>/dev/null; then
    echo "LANG=en_US.UTF-8" | sudo tee /etc/locale.conf > /dev/null
    echo -e "${YELLOW}[NOTE]${CYAN} ==> localectl unavailable, wrote /etc/locale.conf directly.${WHITE}"
fi

# ============================================================
# [4/15] Install base dependencies and yay
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[4/15]${PINK} ==> Installing base dependencies and yay\n---------------------------------------------------------------------\n${WHITE}"
sudo pacman -S --noconfirm --needed base-devel git stow
if ! command -v yay &>/dev/null; then
    echo -e "${CYAN}  Installing yay-bin from AUR...${WHITE}"
    # Ensure sudo is configured for current user (needed by makepkg)
    if ! sudo -n true 2>/dev/null; then
        echo -e "${YELLOW}[NOTE]${CYAN} ==> makepkg requires sudo without password for pacman.${WHITE}"
        echo -e "${YELLOW}  If prompted, enter your password.${WHITE}"
    fi
    git clone --depth=1 https://aur.archlinux.org/yay-bin.git ~/yay-bin
    cd ~/yay-bin && makepkg -si --noconfirm && cd ~ && rm -rf ~/yay-bin
else
    echo -e "${YELLOW}[NOTE]${CYAN} ==> yay is already installed, skipping.${WHITE}"
fi

# ============================================================
# [5/15] Clone dotfiles
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[5/15]${PINK} ==> Cloning dotfiles\n---------------------------------------------------------------------\n${WHITE}"
if [[ -d ~/dotfiles ]]; then
    echo -e "${YELLOW}[NOTE]${CYAN} ==> ~/dotfiles already exists, pulling latest changes...${WHITE}"
    cd ~/dotfiles && git pull && cd ~
else
    git clone --depth=1 "$DOTFILES_REPO" ~/dotfiles
fi

# ============================================================
# [6/15] Make scripts executable
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[6/15]${PINK} ==> Making scripts executable\n---------------------------------------------------------------------\n${WHITE}"
chmod +x ~/dotfiles/.config/viegphunt/*

# ============================================================
# [7/15] Download wallpapers
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[7/15]${PINK} ==> Downloading wallpapers\n---------------------------------------------------------------------\n${WHITE}"
mkdir -p ~/Pictures/Wallpapers
if [[ -z "$(ls -A ~/Pictures/Wallpapers 2>/dev/null)" ]]; then
    git clone --depth=1 "$WALLPAPER_REPO" ~/Wallpaper-Collection
    mv ~/Wallpaper-Collection/Wallpapers/* ~/Pictures/Wallpapers/
    rm -rf ~/Wallpaper-Collection
else
    echo -e "${YELLOW}[NOTE]${CYAN} ==> Wallpapers directory already has files, skipping download.${WHITE}"
fi

# ============================================================
# [8/15] Install packages
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[8/15]${PINK} ==> Installing packages\n---------------------------------------------------------------------\n${WHITE}"
sleep 0.5
~/dotfiles/.config/viegphunt/install_archpkg.sh

# ============================================================
# [9/15] Enable services
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[9/15]${PINK} ==> Enabling system services\n---------------------------------------------------------------------\n${WHITE}"
sleep 0.5
sudo systemctl enable --now bluetooth
sudo systemctl enable --now NetworkManager

# ============================================================
# [10/15] Set default terminal for Nemo
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[10/15]${PINK} ==> Setting Ghostty as default terminal for Nemo\n---------------------------------------------------------------------\n${WHITE}"
# gsettings may fail without D-Bus session bus (e.g. from pure TTY)
if ! gsettings set org.cinnamon.desktop.default-applications.terminal exec ghostty 2>/dev/null; then
    echo -e "${YELLOW}[NOTE]${CYAN} ==> gsettings failed (no D-Bus session). This will be set on first Hyprland login via gtkthemes.sh.${WHITE}"
fi

# ============================================================
# [11/15] Apply fonts & cursor
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[11/15]${PINK} ==> Applying fonts and cursor theme\n---------------------------------------------------------------------\n${WHITE}"
fc-cache -fv
~/dotfiles/.config/viegphunt/setcursor.sh

# ============================================================
# [12/15] Stow dotfiles
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[12/15]${PINK} ==> Stowing dotfiles\n---------------------------------------------------------------------\n${WHITE}"
# Backup existing configs before stowing
if [[ -f ~/dotfiles/.config/viegphunt/backup_config.sh ]]; then
    cd ~/dotfiles && ./.config/viegphunt/backup_config.sh && cd ~
fi
cd ~/dotfiles
stow -t ~ .
cd ~

# ============================================================
# [13/15] Apply GTK themes
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[13/15]${PINK} ==> Applying GTK themes\n---------------------------------------------------------------------\n${WHITE}"
# gtkthemes.sh uses gsettings which needs D-Bus; it will run again on first Hyprland login via autostart
if ! ~/.config/viegphunt/gtkthemes.sh 2>/dev/null; then
    echo -e "${YELLOW}[NOTE]${CYAN} ==> gsettings failed (no D-Bus session). Themes will be applied on first Hyprland login via autostart.${WHITE}"
fi

# ============================================================
# [14/15] Configure display manager (SDDM)
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[14/15]${PINK} ==> Configuring display manager\n---------------------------------------------------------------------\n${WHITE}"
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
# [15/15] Post-install setup
# ============================================================
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[15/15]${PINK} ==> Post-install setup\n---------------------------------------------------------------------\n${WHITE}"

# Change default shell to zsh
if [[ "$SHELL" != *"zsh"* ]]; then
    echo -e "${CYAN}  Changing default shell to zsh...${WHITE}"
    ZSH_PATH="$(command -v zsh)"
    grep -qxF "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
    chsh -s "$ZSH_PATH"
else
    echo -e "${YELLOW}[NOTE]${CYAN} ==> zsh is already the default shell.${WHITE}"
fi

# Install zinit for zsh
ZINIT_HOME="${ZDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
    echo -e "${CYAN}  Installing zinit...${WHITE}"
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
else
    echo -e "${YELLOW}[NOTE]${CYAN} ==> zinit is already installed.${WHITE}"
fi

# Install tmux plugin manager
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
    echo -e "${CYAN}  Installing tmux plugin manager (TPM)...${WHITE}"
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
    echo -e "${YELLOW}[NOTE]${CYAN} ==> TPM is already installed.${WHITE}"
fi

# Setup fcitx5 environment (write to profile.d so it's available for all sessions)
if [[ ! -f /etc/profile.d/fcitx5.sh ]]; then
    echo -e "${CYAN}  Writing fcitx5 environment to /etc/profile.d/fcitx5.sh...${WHITE}"
    echo 'export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export INPUT_METHOD=fcitx5
export SDL_IM_MODULE=fcitx5' | sudo tee /etc/profile.d/fcitx5.sh > /dev/null
else
    echo -e "${YELLOW}[NOTE]${CYAN} ==> fcitx5 environment already configured.${WHITE}"
fi

# Set fcitx5 theme to FluentDark-solid (solid version for non-KWin compositors like Hyprland)
if [[ -d /usr/share/fcitx5/themes/FluentDark-solid ]] || [[ -d ~/.local/share/fcitx5/themes/FluentDark-solid ]]; then
    mkdir -p ~/.config/fcitx5/conf
    if ! grep -q "FluentDark-solid" ~/.config/fcitx5/conf/classicui.conf 2>/dev/null; then
        echo -e "${CYAN}  Setting fcitx5 theme to FluentDark-solid...${WHITE}"
        if [[ -f ~/.config/fcitx5/conf/classicui.conf ]]; then
            sed -i 's/^Theme=.*/Theme=FluentDark-solid/' ~/.config/fcitx5/conf/classicui.conf
        else
            echo -e 'Vertical Candidate List=False\nPerScreenDPI=True\nFont="PingFang SC 13"\nTheme=FluentDark-solid' > ~/.config/fcitx5/conf/classicui.conf
        fi
    fi
else
    echo -e "${YELLOW}[NOTE]${CYAN} ==> FluentDark-solid theme not found yet, will use dotfiles config after stow.${WHITE}"
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
