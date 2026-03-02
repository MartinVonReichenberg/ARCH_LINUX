# **Arch Linux / Cachy OS / Manjaro KDE - Advanced Comprehensive Convenient Semi-Automatic ALL-IN-ONE Post-Installation Script**
___
### **Welcome to my ARCH LINUX / CACHY OS / MANJARO KDE ALL-IN-ONE Semi-Automatic Bash Script!**
___
A robust, semi-automated post-installation and provisioning script designed specifically for **Arch Linux, CachyOS, and Manjaro** systems utilizing the **KDE Plasma** desktop environment.

This script transforms a fresh installation into a fully optimized, codec-complete, and gaming-ready workstation with zero manual intervention required for the heavy lifting.

## **✨ Features & 🚀 Capabilities**
___
* **Intelligent Privilege Escalation *("Privilege Yo-Yo" Fix)*:** Dynamically provisions temporary, secure passwordless `sudo` rights for unprivileged users to allow `paru` to seamlessly install AUR packages in an unattended state without hanging on password prompts.  
* **Distro-Aware Package Selection:** Automatically parses /etc/os-release to dynamically select the correct branch of tools *(e.g., choosing pamac-aur for CachyOS vs. pamac for Vanilla Arch/Manjaro)*.  
* **Pacman Optimization & Keyring Auto-Healing:** Enables ParallelDownloads, ILoveCandy, and comprehensively re-initializes and populates Arch/CachyOS keyrings to prevent cryptographic signature failures.  
* **Chaotic-AUR & Rate-Mirrors Integration:** Injects the Chaotic-AUR repository for pre-compiled binaries and utilizes rate-mirrors to automatically map you to the fastest available CDN *(mirror/s)*.  
* **Arch Gaming Meta Stack:** Deploys a highly comprehensive, Linux gaming ecosystem mirroring Arch's / Cachy OS' / Manjaro's dedicated gaming tier *(Lutris, Bottles, Steam, Gamescope, MangoHud, DXVK, and Proton-GE).*  
* **Automated Fish Shell Keybindings:** Fixes Arch's / Cachy OS' / Manjaro's default "bigword" deletion overreach by explicitly binding ALT+BACKSPACE and CTRL+W to precise, sub-word alphanumeric boundaries.  
* ***For GRUB Bootloader Users Only:*** ENABLES `os-prober` so the GRUB Bootloader Menu offers users choice when MULTI-BOOTING other installed operating system.  

## **🛠 Supported Distributions**

* **CachyOS** *(Primary Target & Highly Optimized)*
* **Arch Linux** *(Vanilla)*
* **Manjaro Linux**

## **📦 Included Software Categories**

During execution, the script will prompt you *(or automatically install if Auto-Accept All is selected)* the following categories:

* **System & Package Managers:** paru, pamac / pamac-aur  
* **Hardware Accelerated Codecs:** mesa, vulkan-radeon, intel-media-driver, libva-nvidia-driver, and comprehensive lib32-\* variants.  
* **Gaming & Emulation:** steam, lutris, bottles, heroic-games-launcher, dxvk-bin, proton-ge-custom, gamemode, mangohud, gamescope, goverlay, corectrl, and dualsensectl.  
* **Development & Build Tools:** github-cli, bash-language-server, shfmt, linux-headers.  
* **KDE & Desktop Utilities:** kate, dolphin-plugins, kleopatra, koi, stellarium.  
* **Multimedia & Codecs:** ffmpeg, vlc, x264, x265, and complete GStreamer plugin arrays *(including 32-bit plugins for legacy WINE video cutscene rendering)*.  
* **System Fonts:** Noto CJK, Hack Nerd Fonts, Roboto, Inter, VLGothic, and WQY Asian Language fonts.  
* **Networking & VPN:** Interactive choice between NetBird, Tailscale, ZeroTier, or *All*.  
* **Internet & Communication:** Google Chrome, Opera, Telegram, Discord, FileZilla, qBittorrent, WinBox.  
* **System CLI Tools:** htop, btop, fish, bat, micro, cowsay, fortune-mod.  
* **Security & Utilities:** Bitwarden, ProtonMail Desktop, Proton Pass, Balena Etcher.  
* **Flatpak Applications:** YouTube Music Desktop, ZapZap *(WhatsApp)*, Termius SSH, ProtonUp-Qt.  


## **💻 Usage Instructions**
___
### **1. Download the Script:**

Download the script to your local machine *(e.g., your Downloads directory)*.

```
  git clone 'https://github.com/MartinVonReichenberg/ARCH_LINUX.git'
  cd './ARCH_LINUX/Development/Scripts/Desktops/KDE/'
```

### **2. Make it Executable *(optional):***

Assign execution privileges to the script.

```
  chmod +x ./ARCH_LINUX-KDE-DESKTOP--Post_Installation_Script.sh
```

### **3. Execute the Script:**

The script natively supports execution from either your standard home user *(utilizing* `sudo`*)* or directly from a root shell *(*`su -`*)*.

```
  ./ARCH_LINUX-KDE-DESKTOP--Post_Installation_Script.sh
```

### **4. Interaction**

Upon launch, you will be greeted by the **Global Auto-Accept Prompt**.

* **Selecting** `[A]` ***(Auto Accept All)*:** The script will run completely unattended. It will resolve your user, generate the necessary security configurations, install the entire software stack, and reboot your machine automatically upon completion.  
* **Selecting** `[N]` ***(No)*:** You will be prompted step-by-step to Confirm *(Y)* or Deny *(N)* each specific configuration phase and software category.  


## **🔒 Security Architecture Note**
___
Arch Linux strictly prohibits ***AUR helpers*** *(*`paru`*,* `makepkg`*)* from being executed as the ***root*** user.

To facilitate true unattended installations without manual password entry bottlenecks, this script dynamically utilizes trap logic and temporary `/etc/sudoers` drop-in tags.

It explicitly grants the identified `$TARGET_USER` momentary `NOPASSWD` execution rights for the duration of the installation phase. Upon completion, failure, or manual abortion *(via* `Ctrl+C`*)*, the kernel-level trap guarantees the instant and permanent deletion of these temporary rights, restoring your system to its default security posture.


## **⚖️ Disclaimer & License**
___
*Feel free to modify, re-edit, share, redistribute/reproduce and provide feedback to this Bash script according to your needs and/or wishes.*

*This script is not subjected to any license or to any form of restrictions; anything is allowed . . .*

*Disclaimer:* 
*This script significantly alters system-level configurations, repositories, and packages. While it is rigorously structured with extensive fail-safes, user-validation checks, and conditional logic, it is provided **"as is" without warranty of any kind***.

*Always ensure you understand the commands being executed, particularly regarding to [Pacman-to-Paru/Paru-to-Pacman - Root(sudo)-to-User/User-to-Root(sudo)] transitions, repository syncing, and firewall management. Review the code to ensure it meets your specific security and administrative requirements before deployment.*  

Have a lot of fun !
