#!/usr/bin/bash

# ==============================================================================
# COLOR DEFINITIONS
# ==============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
# ==============================================================================

# ==============================================================================
# PROMPT FUNCTION: Standardized Yes/No interactive handler
# ==============================================================================
AUTO_ACCEPT_ALL=false

ask_prompt() {
    local prompt_text="$1"

    # If the user previously selected "Accept All" at the master prompt, bypass and return true.
    if [ "$AUTO_ACCEPT_ALL" = true ]; then
        return 0
    fi

    while true; do
        # Use echo -e -n to print colored prompt without a trailing newline,
        # then read the user input on the same line.
        echo -e -n "${YELLOW}${prompt_text} [Y/n]: ${NC}"
        read -r yn
        case $yn in
            [Yy]* | "" ) return 0 ;; # Default to Yes
            [Nn]* ) return 1 ;;      # Deny/Skip
            * ) echo -e "${RED}Please answer yes (Y/y) or no (N/n).${NC}" ;;
        esac
    done
}
# ==============================================================================

# ==============================================================================
# TARGET USER RESOLUTION (For AUR & User Groups)
# ==============================================================================
# Arch Linux strictly forbids running makepkg/paru as root.
# This function dynamically fetches the unprivileged user 'in the midst' of the script.
TARGET_USER=""

# SECURITY FAILSAFE: Set up a secure trap to automatically remove temporary sudoers privileges
# upon exit, abort (Ctrl+C), termination, or hangup. This utilizes a strict sed removal
# to guarantee no trace is left in the sudoers file.
trap 'sudo sed -i "/# CACHYOS_TEMP_NOPASSWD/d" /etc/sudoers 2>/dev/null' EXIT INT TERM HUP

get_target_user() {
    if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
        TARGET_USER="${SUDO_USER:-$USER}"
        if [ "$TARGET_USER" = "root" ]; then
            echo -e "${YELLOW}Notice: AUR installations and group assignments require an unprivileged user.${NC}"
            while true; do
                echo -e -n "${YELLOW}Please enter your primary home username: ${NC}"
                read -r input_user
                if id "$input_user" &>/dev/null; then
                    TARGET_USER="$input_user"
                    break
                else
                    echo -e "${RED}Error: The user '$input_user' does not exist on this system.${NC}"
                fi
            done
        fi

        # TEMPORARY PRIVILEGE ESCALATION FIX (Overrides %wheel):
        # By appending to the absolute end of /etc/sudoers, this bypasses any existing
        # wheel group requirements, ensuring paru can seamlessly execute 'sudo pacman' unattended.
        if ! sudo grep -q "# CACHYOS_TEMP_NOPASSWD" /etc/sudoers; then
            echo -e "${CYAN}Granting temporary passwordless sudo to $TARGET_USER for seamless AUR installations...${NC}"
            echo "$TARGET_USER ALL=(ALL:ALL) NOPASSWD: ALL # CACHYOS_TEMP_NOPASSWD" | sudo tee -a /etc/sudoers > /dev/null
        fi
    fi
}
# ==============================================================================

# Welcome to my semi-automatized ARCH LINUX / CACHYOS Post installation Script:
echo ""
echo -e "${CYAN}===============================================================================================${NC}"
echo -e "${CYAN}   Welcome to my semi-automatized ARCH LINUX / CACHYOS KDE Post installation Script           ${NC}"
echo -e "${CYAN}   This script can be run either as a currently logged in [HOME USER] or ROOT                 ${NC}"
echo -e "${CYAN}   Feel free to Auto-Accept ALL (A), Confirm (Y) or Deny (N) prompting options.               ${NC}"
echo -e "${CYAN}===============================================================================================${NC}"
echo ""
#

# ==============================================================================
# CRITICAL PRE-FLIGHT CHECK: Restore Wheel Group & Clean up Installer Artifacts
# ==============================================================================
# The Calamares installer leaves the main /etc/sudoers commented out and uses a drop-in file.
# We MUST uncomment the standard %wheel group before deleting the drop-in, otherwise the
# user will be permanently locked out of sudo privileges ("user is not in the sudoers file").
echo -e "${GREEN}Verifying system sudoers configuration...${NC}"

# 1. Guarantee %wheel group is uncommented in the main /etc/sudoers file
sudo sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
sudo sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
echo -e "${CYAN}Ensured %wheel group administrative privileges are active in main /etc/sudoers.${NC}"

# 2. Safely remove the 10-installer artifact to prevent timestamp/yo-yo conflicts
if [ -f "/etc/sudoers.d/10-installer" ]; then
    echo -e "${YELLOW}Removing leftover CachyOS installer sudoers file (/etc/sudoers.d/10-installer)...${NC}"
    sudo rm -f "/etc/sudoers.d/10-installer"

    # Force sudo to drop cached privileges, ensuring the next prompt registers our cleaned environment
    sudo -k
    echo -e "${CYAN}Successfully removed installer artifact and reset sudo timestamp.${NC}"
fi
echo ""
#

# ==============================================================================
# GLOBAL AUTO-ACCEPT PROMPT (Top of hierarchy)
# ==============================================================================
echo -e "${CYAN}==========================================================================================${NC}"
echo -e "${YELLOW}Would you like to ENABLE AUTO-ACCEPT ALL, including REBOOT for the rest of this installation?   ${NC}"
echo -e "${YELLOW} - YES (A): Skips all individual prompts and installs EVERYTHING automatically. ${NC}"
echo -e "${YELLOW} - NO (N): Prompts you individually for each software category (Default).     ${NC}"
echo -e "${CYAN}==========================================================================================${NC}"
while true; do
    echo -e -n "${YELLOW}Enable Auto-Accept All? [a/N]: ${NC}"
    read -r auto_yn
    case $auto_yn in
        [Aa]* | [Yy]* )
            AUTO_ACCEPT_ALL=true
            echo -e "${GREEN}Global 'Auto Accept All' enabled. The script will now run unattended.${NC}"
            break
            ;;
        [Nn]* | "" )
            AUTO_ACCEPT_ALL=false
            echo -e "${BLUE}Individual prompting retained. You will be asked for each step.${NC}"
            break
            ;;
        * )
            echo -e "${RED}Please answer Accept All (A/a) or No (N/n). Default is No (N).${NC}"
            ;;
    esac
done
echo ""
#

# Change/modify the password prompt timeout for the [sudo] command:
if ask_prompt "Disable sudo password prompt timeout (Defaults timestamp_timeout=-1)?"; then
    echo -e "${GREEN}Modifying sudo password prompt timeout (-1) to last until logout/reboot:${NC}"
    echo "Defaults timestamp_timeout=-1" | sudo tee "/etc/sudoers.d/99-disable-timeout" > /dev/null
    sudo chmod -v 0440 "/etc/sudoers.d/99-disable-timeout"
    echo -e "${CYAN}Wrote configuration options into: [/etc/sudoers.d/99-disable-timeout] file.${NC}"
else
    echo -e "${RED}Skipped modifying sudo password prompt timeout.${NC}"
fi
echo ""
#

# Optimize Pacman Configuration:
if ask_prompt "Optimize Pacman Configuration (ParallelDownloads=10, ILoveCandy, Color)?"; then
    echo -e "${GREEN}Optimizing /etc/pacman.conf...${NC}"
    sudo sed -i 's/^#Color/Color\nILoveCandy/' /etc/pacman.conf
    sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf
    sudo sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
    echo -e "${CYAN}Enabled Color, ILoveCandy, VerbosePkgLists, and ParallelDownloads = 10.${NC}"
else
    echo -e "${RED}Skipped Pacman optimizations.${NC}"
fi
echo ""
#

# Enable Multilib Repository (Required for 32-bit Gaming/WINE):
if ask_prompt "Enable [multilib] repository (Essential for Steam/WINE/Proton)?"; then
    echo -e "${GREEN}Enabling [multilib] in /etc/pacman.conf...${NC}"

    # Conditional inclusion to preserve existing repository configurations
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        sudo sed -i '/^#\[multilib\]/{N;s/#//g}' /etc/pacman.conf
        echo -e "${CYAN}Enabled 32-bit Multilib repository.${NC}"
    else
        echo -e "${YELLOW}[multilib] is already enabled in /etc/pacman.conf. Preserving existing entry.${NC}"
    fi
else
    echo -e "${RED}Skipped [multilib] enablement.${NC}"
fi
echo ""
#

# Refresh Pacman Keyring & Database:
if ask_prompt "Refresh Pacman Keyring & Database (pacman-key --init/populate)?"; then
    echo -e "${GREEN}Refreshing Pacman Keyring & Database...${NC}"
    sudo pacman-key --init
    sudo pacman-key --populate archlinux
    # Dynamically populate CachyOS keyring if executing on CachyOS
    if grep -qi "cachyos" /etc/os-release 2>/dev/null; then
        sudo pacman-key --populate cachyos
    fi
    sudo pacman -Sy archlinux-keyring --noconfirm
    echo -e "${CYAN}Pacman Keyring initialized and refreshed successfully.${NC}"
else
    echo -e "${RED}Skipped Pacman Keyring refresh.${NC}"
fi
echo ""
#

# Integrate Chaotic AUR Repository & Rate Mirrors:
if ask_prompt "Integrate Chaotic AUR Repository & Optimize Mirrors (rate-mirrors)?"; then
    echo -e "${GREEN}Integrating Chaotic AUR (aur.chaotic.cx)...${NC}"

    # Conditional inclusion to preserve existing repository configurations
    if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
        sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
        sudo pacman-key --lsign-key 3056513887B78AEB
        sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
        sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

        sudo tee -a /etc/pacman.conf <<EOF >/dev/null

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF
        echo -e "${CYAN}Successfully appended [chaotic-aur] to /etc/pacman.conf.${NC}"
    else
        echo -e "${YELLOW}[chaotic-aur] is already present in /etc/pacman.conf. Preserving existing entry.${NC}"
    fi

    echo -e "${GREEN}Installing 'rate-mirrors' to optimize Chaotic AUR...${NC}"
    get_target_user
    sudo -u "$TARGET_USER" paru -S --noconfirm --needed rate-mirrors

    echo -e "${GREEN}Rating and updating Chaotic AUR mirrors...${NC}"
    # Rate Chaotic AUR mirrors and write directly to the mirrorlist
    sudo rate-mirrors --allow-root --protocol https chaotic-aur | sudo tee /etc/pacman.d/chaotic-mirrorlist > /dev/null
    echo -e "${CYAN}Chaotic AUR mirrors optimized.${NC}"
else
    echo -e "${RED}Skipped Chaotic AUR integration and mirror optimization.${NC}"
fi
echo ""
#

# Refresh and Upgrade System Databases:
if ask_prompt "Refresh all repositories and execute full system upgrade (pacman -Syyu)?"; then
    echo -e "${GREEN}Refreshing repositories and upgrading system...${NC}"
    sudo pacman -Syyu --noconfirm
else
    echo -e "${RED}Skipped system upgrade.${NC}"
fi
echo ""
#

# Install Essential Package Managers (Paru & Pamac):
if ask_prompt "Install PARU (AUR Helper) and PAMAC (GUI Package Manager)?"; then
    echo -e "${GREEN}Installing Paru and Pamac...${NC}"

    # Detect Operating System to choose appropriate Pamac package architecture
    if grep -qi "cachyos" /etc/os-release 2>/dev/null; then
        PAMAC_PKG="pamac-aur"
        echo -e "${BLUE}Detected CachyOS: Selecting '${PAMAC_PKG}' from default repositories.${NC}"
    else
        PAMAC_PKG="pamac"
        echo -e "${BLUE}Detected Arch/Manjaro: Selecting '${PAMAC_PKG}' from Chaotic-AUR/Manjaro repositories.${NC}"
    fi

    # Bootstrap Paru if not installed
    sudo pacman -S --noconfirm --needed base-devel git
    if ! command -v paru &> /dev/null; then
        echo -e "${CYAN}Bootstrapping paru...${NC}"
        get_target_user
        sudo pacman -S --noconfirm paru || sudo -u "$TARGET_USER" bash -c "cd /tmp && git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si --noconfirm"
    fi
    get_target_user

    echo -e "${CYAN}Resolving Pamac provider conflicts...${NC}"
    # Pre-emptively remove any existing permutations of Pamac to ensure a clean slate and avoid '--noconfirm' abortion blocks.
    sudo pacman -Rdd --noconfirm pamac-all pamac-aur pamac libpamac-full libpamac-aur 2>/dev/null || true

    # Explicitly install the dynamically selected Pamac package
    sudo -u "$TARGET_USER" paru -S --noconfirm --needed "$PAMAC_PKG"
else
    echo -e "${RED}Skipped Paru & Pamac installation.${NC}"
fi
echo ""
#

# Install Hardware Accelerated Codecs & Drivers (AMD/INTEL/NVIDIA - Multilib included):
if ask_prompt "Install Hardware Accelerated Codecs & Drivers (Mesa/Vulkan/Nvidia 64+32bit)?"; then
    echo -e "${GREEN}Installing Hardware Accelerated Codecs & Drivers...${NC}"
    get_target_user
    sudo -u "$TARGET_USER" paru -S --noconfirm --needed \
        mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon \
        intel-media-driver vulkan-intel lib32-vulkan-intel \
        libva-nvidia-driver \
        libva libva-utils lib32-libva
else
    echo -e "${RED}Skipped hardware accelerated codecs installation.${NC}"
fi
echo ""
#

# Install, configure and activate VirtualBox:
if ask_prompt "Install, configure and activate VirtualBox?"; then
    echo -e "${GREEN}Installing VirtualBox...${NC}"
    get_target_user
    sudo -u "$TARGET_USER" paru -S --noconfirm --needed virtualbox virtualbox-host-dkms virtualbox-guest-iso
    echo ""
    echo -e "${CYAN}Reloading systemd modules and enabling vboxdrv...${NC}"
    sudo modprobe vboxdrv
    echo ""

    if [ -n "$TARGET_USER" ]; then
        if ask_prompt "Add target user ($TARGET_USER) to VirtualBox group (vboxusers)?"; then
            echo -e "${GREEN}Adding $TARGET_USER to vboxusers...${NC}"
            sudo usermod -a -G vboxusers "$TARGET_USER"
            echo -e "${CYAN}Successfully added $TARGET_USER to VirtualBox groups.${NC}"
        else
            echo -e "${RED}Skipped adding $TARGET_USER to VirtualBox groups.${NC}"
        fi
    fi
else
    echo -e "${RED}Skipped VirtualBox installation.${NC}"
fi
echo ""
#

# Add FlatHub repository for Flatpak:
if ask_prompt "Install Flatpak and add FlatHub repository?"; then
    echo -e "${GREEN}Installing Flatpak and adding FlatHub repository...${NC}"
    get_target_user
    sudo -u "$TARGET_USER" paru -S --noconfirm --needed flatpak
    sudo flatpak remote-add --if-not-exists "flathub" "https://dl.flathub.org/repo/flathub.flatpakrepo"
else
    echo -e "${RED}Skipped FlatHub repository addition.${NC}"
fi
echo ""
#

# ==============================================================================
# MASS PACKAGE INSTALLATION (CATEGORIZED AND ALPHABETIZED)
# ==============================================================================
echo -e "${CYAN}Initiating recommended packages installation phase. All installations routed via PARU.${NC}"
echo ""

# Development & Build Tools:
if ask_prompt "Install Development & Build Tools (LSPs, formatters, headers)?"; then
    echo -e "${GREEN}Installing Development & Build Tools:${NC}"
    get_target_user
    sudo -u "$TARGET_USER" paru -S --noconfirm --needed \
        bash-language-server github-cli linux-headers shfmt
else
    echo -e "${RED}Skipped Development & Build Tools.${NC}"
fi
echo ""
#

# Gaming & Controller Utilities (Manjaro Gaming Meta + Arch Optimization):
if ask_prompt "Install Gaming & Controller Utilities (Steam, Lutris, Bottles, Gamescope, MangoHud, DXVK, Proton)?"; then
    echo -e "${GREEN}Installing Gaming & Controller Utilities (Meta Group):${NC}"
    get_target_user
    sudo -u "$TARGET_USER" paru -S --noconfirm --needed \
        bottles corectrl dualsensectl dxvk-bin egl-wayland gamemode \
        gamescope glfw-wayland goverlay heroic-games-launcher \
        lib32-gamemode lib32-mangohud lib32-vkd3d lutris \
        mangohud minigalaxy proton-ge-custom steam vkd3d \
        wine-staging winetricks
else
    echo -e "${RED}Skipped Gaming & Controller Utilities.${NC}"
fi
echo ""
#

# KDE Desktop Utilities + Extras & Science:
if ask_prompt "Install KDE Desktop Utilities + Extras & Science (Kate, Kleopatra, Okular, Stellarium)?"; then
    echo -e "${GREEN}Installing KDE Desktop Utilities + Extras & Science:${NC}"
    get_target_user
    sudo -u "$TARGET_USER" paru -S --noconfirm --needed \
        dolphin-plugins kate kgpg kleopatra koi okular stellarium
else
    echo -e "${RED}Skipped KDE Desktop Utilities + Extras & Science.${NC}"
fi
echo ""
#

# Multimedia Codecs, Fonts & Media Players:
if ask_prompt "Install specific Multimedia Codecs (FFmpeg, GStreamer 64/32bit), Fonts & Players (VLC)?"; then
    echo -e "${GREEN}Installing Multimedia Codecs (x264, x265, GStreamer), Fonts & Media Players (VLC):${NC}"
    # NOTE: 32-bit (lib32) GStreamer plugins are MANDATORY for WINE/Proton to render video cutscenes in legacy games.
    get_target_user
    sudo -u "$TARGET_USER" paru -S --noconfirm --needed \
        ffmpeg vlc x264 x265 \
        gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav \
        lib32-gst-plugins-base lib32-gst-plugins-good
else
    echo -e "${RED}Skipped specific Multimedia Codecs & Players.${NC}"
fi
echo ""
#

# System Fonts, Extra Fonts & Asian Language Support:
if ask_prompt "Install System Fonts, Extra Fonts & Asian Language Support (Inter, Roboto, Hack Nerd, CJK)?"; then
    echo -e "${GREEN}Installing System Fonts & Asian Language Support:${NC}"
    get_target_user
    sudo -u "$TARGET_USER" paru -S --noconfirm --needed \
        noto-fonts-cjk noto-fonts-emoji ttf-roboto ttf-hack-nerd \
        ttf-liberation inter-font ttf-vlgothic wqy-microhei wqy-zenhei
else
    echo -e "${RED}Skipped System Fonts, Extra Fonts & Asian Language Support.${NC}"
fi
echo ""
#

# Dedicated VPN Tools:
echo -e "${GREEN}Dedicated VPN Tools Installation:${NC}"
while true; do
    echo -e "${CYAN}==============================================================================${NC}"
    echo -e "${YELLOW}Please specify your preferred VPN Tool (Exception to Auto-Accept All):${NC}"
    echo -e "  ${BLUE}[N]${NC} = NetBird"
    echo -e "  ${BLUE}[T]${NC} = Tailscale"
    echo -e "  ${BLUE}[Z]${NC} = ZeroTier (zerotier-one)"
    echo -e "  ${BLUE}[A]${NC} = ALL of them"
    echo -e "${CYAN}==============================================================================${NC}"
    echo -e -n "${YELLOW}Your choice [N/T/Z/A] (Leave blank/Enter to SKIP): ${NC}"
    read -r vpn_input

    if [ -z "$vpn_input" ]; then
        vpn_choice="skip"
        break
    fi

    formatted_vpn="${vpn_input,,}"
    case "$formatted_vpn" in
        n|netbird)   vpn_choice="netbird" ; break ;;
        t|tailscale) vpn_choice="tailscale" ; break ;;
        z|zerotier)  vpn_choice="zerotier" ; break ;;
        a|all)       vpn_choice="all" ; break ;;
        *) echo -e "${RED}Invalid selection. Please type N, T, Z, A, or press [Enter] to skip.${NC}" ;;
    esac
done

if [ "$vpn_choice" = "skip" ]; then
    echo -e "${RED}Skipped Dedicated VPN Tools installation.${NC}"
else
    if [[ "$vpn_choice" == "netbird" || "$vpn_choice" == "all" ]]; then
        echo -e "${GREEN}Installing NetBird (+ UI)...${NC}"
        get_target_user
        sudo -u "$TARGET_USER" paru -S --noconfirm --needed netbird netbird-ui
        sudo systemctl enable netbird
    fi
    if [[ "$vpn_choice" == "tailscale" || "$vpn_choice" == "all" ]]; then
        echo -e "${GREEN}Installing Tailscale...${NC}"
        get_target_user
        sudo -u "$TARGET_USER" paru -S --noconfirm --needed tailscale
        sudo systemctl enable tailscaled
    fi
    if [[ "$vpn_choice" == "zerotier" || "$vpn_choice" == "all" ]]; then
        echo -e "${GREEN}Installing ZeroTier...${NC}"
        get_target_user
        sudo -u "$TARGET_USER" paru -S --noconfirm --needed zerotier-one
        sudo systemctl enable zerotier-one
    fi
fi
echo ""
#

# Network & Internet Tools:
if ask_prompt "Install Network & Internet Tools (Web Browsers, Messaging, Torrent, Remote)?"; then
    echo -e "${GREEN}Installing Network & Internet Tools:${NC}"
    get_target_user
    sudo -u "$TARGET_USER" paru -S --noconfirm --needed \
        bftpd discord filezilla google-chrome opera opera-ffmpeg-codecs \
        qbittorrent telegram-desktop winbox
else
    echo -e "${RED}Skipped Network & Internet Tools.${NC}"
fi
echo ""
#

# System Utilities & CLI + Packaging Tools:
if ask_prompt "Install System Utilities & CLI Tools (Htop, Fish, etc.)?"; then
    echo -e "${GREEN}Installing System Utilities & CLI Tools:${NC}"
    get_target_user
    sudo -u "$TARGET_USER" paru -S --noconfirm --needed \
        atop bat btop cowsay fish fortune-mod fuse3 htop inxi mc micro xclip xsel
else
    echo -e "${RED}Skipped System Utilities & CLI Tools.${NC}"
fi
echo ""
#

# Direct AUR / Pacman Security & Utility Replacements (Formerly Third-Party RPMs):
if ask_prompt "Install Security & Utilities (Bitwarden, Proton tools, Etcher) via AUR/Pacman?"; then
    echo -e "${GREEN}Installing Security & Utilities:${NC}"
    get_target_user
    sudo -u "$TARGET_USER" paru -S --noconfirm --needed \
        balena-etcher bitwarden protonmail-desktop proton-pass proton-authenticator
else
    echo -e "${RED}Skipped Security & Utilities.${NC}"
fi
echo ""
#

# Install and Update additional Flatpak Applications:
if ask_prompt "Install specific Flatpak Applications (ZapZap/WhatsApp, Termius SSH, YouTube Music, ProtonUp-Qt, VacuumTube)?"; then
    echo -e "${GREEN}Installing Flatpak Applications:${NC}"
    sudo flatpak update -y
    sudo flatpak install -y flathub \
        app.ytmdesktop.ytmdesktop com.rtosta.zapzap com.termius.Termius net.davidotek.pupgui2 rocks.shy.VacuumTube
else
    echo -e "${RED}Skipped Flatpak Applications.${NC}"
fi
echo ""
#

# Add [sufido] command alias for Fish shell:
if ask_prompt "Add 'sufido' command alias for Fish shell?"; then
    sudo mkdir -p /etc/fish/functions/
    sudo tee "/etc/fish/functions/sufido.fish" <<EOF >/dev/null
function sufido --description "Start a root Fish shell with: [su] and change directory to: [/]"
sudo su --shell /usr/bin/fish -c "cd '/' ; exec fish"
end
EOF
    echo -e "${CYAN}Added [sufido.fish] function file into [/etc/fish/functions/] directory.${NC}"
else
    echo -e "${RED}Skipped adding 'sufido' Fish shell alias.${NC}"
fi
echo ""
#

# Configure precise sub-word deletion (Alt+Backspace / Ctrl+W) for Fish shell:
if ask_prompt "Configure precise word deletion (Alt+Backspace / Ctrl+W) for Fish shell?"; then
    echo -e "${GREEN}Configuring precise sub-word deletion for Fish shell...${NC}"
    sudo mkdir -p /etc/fish/functions/ /etc/fish/conf.d/

    # 1. Create the custom deletion function
    # By restricting the word characters to strictly alphanumeric values, we force Fish
    # to treat all punctuation (including /-._*=@) as hard boundaries/separators.
    sudo tee "/etc/fish/functions/backward-kill-subword.fish" <<EOF >/dev/null
function backward-kill-subword
    set -l fish_word_selection_characters "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    commandline -f backward-kill-word
end
EOF

    # 2. Bind the function to keyboard shortcuts globally
    sudo tee "/etc/fish/conf.d/99-custom-word-deletion.fish" <<EOF >/dev/null
# Override CachyOS defaults to map standard deletion shortcuts to our custom sub-word logic.
if status is-interactive
    bind \e\x7f backward-kill-subword
    bind \cw backward-kill-subword
end
EOF
    echo -e "${CYAN}Added [backward-kill-subword.fish] and global keybindings into Fish configuration.${NC}"
else
    echo -e "${RED}Skipped Fish word deletion configuration.${NC}"
fi
echo ""
#

# Disable Firewall SystemD Service (UFW / Firewalld if installed):
if ask_prompt "Disable Firewall SystemD Service (ufw / firewalld)?"; then
    echo -e "${GREEN}Disabling Firewall SystemD Services:${NC}"
    sudo systemctl disable --now firewalld 2>/dev/null
    sudo systemctl disable --now ufw 2>/dev/null
    echo -e "${CYAN}Disabled any running firewall services.${NC}"
else
    echo -e "${RED}Skipped Firewall disablement.${NC}"
fi
echo ""
#

# Enable OS-Prober for GRUB bootloader (Multi-boot detection):
if command -v grub-mkconfig &> /dev/null && [ -f "/etc/default/grub" ]; then
    if ask_prompt "Enable OS-Prober for GRUB bootloader (Detect other OSes for multi-boot)?"; then
        echo -e "${GREEN}Enabling OS-Prober in /etc/default/grub...${NC}"

        # Ensure os-prober is installed first
        get_target_user
        sudo -u "$TARGET_USER" paru -S --noconfirm --needed os-prober

        # Safely modify the /etc/default/grub configuration file
        if grep -q "^#GRUB_DISABLE_OS_PROBER=" "/etc/default/grub"; then
            sudo sed -i 's/^#GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' "/etc/default/grub"
        elif grep -q "^GRUB_DISABLE_OS_PROBER=true" "/etc/default/grub"; then
            sudo sed -i 's/^GRUB_DISABLE_OS_PROBER=true/GRUB_DISABLE_OS_PROBER=false/' "/etc/default/grub"
        elif ! grep -q "^GRUB_DISABLE_OS_PROBER=false" "/etc/default/grub"; then
            # If the parameter is missing entirely, append it safely
            echo "GRUB_DISABLE_OS_PROBER=false" | sudo tee -a "/etc/default/grub" > /dev/null
        fi

        echo -e "${CYAN}Regenerating GRUB configuration globally...${NC}"
        sudo grub-mkconfig -o /boot/grub/grub.cfg
        echo -e "${CYAN}Successfully enabled OS-Prober and updated the GRUB bootloader menu.${NC}"
    else
        echo -e "${RED}Skipped OS-Prober enablement.${NC}"
    fi
    echo ""
fi
#

# Autoremove orphaned and unused packages & Clean Cache:
if ask_prompt "Autoremove orphaned/unused packages and clean Cache (pacman -Rns / paru -Sc)?"; then
    echo -e "${GREEN}Removing orphaned and unused packages...${NC}"
    # Pacman will throw an error if Qtdq returns nothing, so we check first
    ORPHANS=$(sudo pacman -Qtdq)
    if [ -n "$ORPHANS" ]; then
        sudo pacman -Rns "$ORPHANS" --noconfirm
    else
        echo -e "${CYAN}No orphaned packages found.${NC}"
    fi
    echo -e "${GREEN}Cleaning Paru/Pacman Cache...${NC}"
    get_target_user
    sudo -u "$TARGET_USER" paru -Sc --noconfirm
else
    echo -e "${RED}Skipped Autoremove and Cache cleaning.${NC}"
fi
echo ""
#

# Update available firmware for your current hardware - if there is any; only for UEFI:
if ask_prompt "Check and update hardware firmware via fwupdmgr (UEFI only)?"; then
    echo -e "${GREEN}Update available firmware for your current hardware - if there is any; only for UEFI:${NC}"
    # Ensure fwupd is installed
    get_target_user
    sudo -u "$TARGET_USER" paru -S --noconfirm --needed fwupd
    sudo fwupdmgr refresh --force
    sudo fwupdmgr get-remotes
    sudo fwupdmgr get-devices
    sudo fwupdmgr get-updates
    sudo fwupdmgr update --force
else
    echo -e "${RED}Skipped firmware updates.${NC}"
fi
echo ""
#

# Update SMART DRIVE DATABASE:
if ask_prompt "Update SMART Drive Database (update-smart-drivedb)?"; then
    echo -e "${GREEN}Updating SMART DRIVE DATABASE...${NC}"
    get_target_user
    sudo -u "$TARGET_USER" paru -S --noconfirm --needed smartmontools
    sudo update-smart-drivedb
else
    echo -e "${RED}Skipped SMART Drive Database update.${NC}"
fi
echo ""
#

# Update P-LOCATE DATABASE:
if ask_prompt "Update P-LOCATE Database (updatedb)?"; then
    get_target_user
    sudo -u "$TARGET_USER" paru -S --noconfirm --needed plocate
    sudo updatedb
    echo -e "${GREEN}Updated P-LOCATE DATABASE [updatedb] ...${NC}"
else
    echo -e "${RED}Skipped P-LOCATE Database update.${NC}"
fi
echo ""
#

# Create 'nogroup' system group for cross-distribution compatibility:
if ask_prompt "Create 'nogroup' system group (GID 65534) for cross-distribution compatibility?"; then
    echo -e "${GREEN}Creating 'nogroup' system group with ID 65534...${NC}"
    # The -o flag is utilized to permit non-unique GIDs, as 65534 is already assigned to the 'nobody' group in Arch Linux / CachyOS / Manjaro.
    sudo groupadd -o -g 65534 nogroup 2>/dev/null
    echo -e "${CYAN}Successfully ensured 'nogroup' (GID 65534) exists for SUSE/Debian/Ubuntu compatibility.${NC}"
else
    echo -e "${RED}Skipped 'nogroup' system group creation.${NC}"
fi
echo ""
#

# ==============================================================================
# Add target user (HOME USER) to recommended groups
# ==============================================================================
get_target_user
if [ -n "$TARGET_USER" ]; then
    if ask_prompt "Add target user ($TARGET_USER) to recommended groups (audio, games, gamemode, users, video, wheel)?"; then
        echo -e "${GREEN}Adding $TARGET_USER to recommended groups...${NC}"
        # Ensure groups exist before adding to prevent usermod failures
        for grp in audio games gamemode users video wheel; do
            sudo groupadd -f "$grp"
        done
        sudo usermod -a -G 'audio,games,gamemode,users,video,wheel' "$TARGET_USER"
        echo -e "${CYAN}Successfully added $TARGET_USER to groups.${NC}"
    else
        echo -e "${RED}Skipped adding $TARGET_USER to recommended groups.${NC}"
    fi
else
    echo -e "${RED}Skipped user group configuration phase due to invalid target user.${NC}"
fi
echo ""
#

# ==============================================================================
# PRE-REBOOT MANUAL INTERVENTION PAUSE
# ==============================================================================
if [ "$AUTO_ACCEPT_ALL" = false ]; then
    echo -e "${CYAN}==============================================================================${NC}"
    echo -e "${CYAN}   All automated deployment tasks have concluded.                             ${NC}"
    echo -e "${YELLOW}   If you need to execute any manual commands in another terminal tab,        ${NC}"
    echo -e "${YELLOW}   please do so now before proceeding to the final system reboot phase.       ${NC}"
    echo -e "${CYAN}==============================================================================${NC}"
    echo -e -n "${YELLOW}Press [Enter] when you are ready to proceed... ${NC}"
    read -r _dummy
    echo ""
fi
#

# ==============================================================================
# FINAL REBOOT SEQUENCE
# ==============================================================================
# Final Cleanup of Temporary Privileges before Reboot Block
sudo sed -i "/# CACHYOS_TEMP_NOPASSWD/d" /etc/sudoers 2>/dev/null

if [ "$AUTO_ACCEPT_ALL" = true ]; then
    echo -e "${CYAN}==============================================================================${NC}"
    echo -e "${YELLOW}   All automated deployment tasks have concluded.${NC}"
    echo -e "${CYAN}==============================================================================${NC}"

    reboot_cancelled=false
    for i in {20..1}; do
        echo -e -n "\r\033[K${CYAN}Rebooting the system in ${YELLOW}${i}${CYAN} seconds... Press '${RED}N${CYAN}' to cancel, or [Enter] to reboot now: ${NC}"
        if read -r -t 1 -n 1 user_input; then
            if [[ "$user_input" == [Nn] ]]; then
                reboot_cancelled=true
                break
            else
                break
            fi
        fi
    done

    echo ""

    if [ "$reboot_cancelled" = true ]; then
        echo -e "${YELLOW}Reboot cancelled by user. Please remember to reboot later to apply all changes.${NC}"
    else
        echo -e "${GREEN}Rebooting the system...${NC}"
        sudo reboot
    fi

else
    if ask_prompt "Would you like to reboot your operating system right now?"; then
        echo -e "${GREEN}Rebooting the system...${NC}"
        sudo reboot
    else
        echo ""
        echo -e "${YELLOW}Reboot postponed. Please remember to reboot later to apply all changes.${NC}"
    fi
fi
#

#EOF
echo ""
echo -e "${CYAN}EOF${NC}"
echo ""
#
