#!/bin/sh
if ping -c 1 -W 2 google.com > /dev/null 2>&1; then
    echo -e "[\e[32m OK \e[0m] Network (eth0) is UP, continuing."
else
    echo -e "[\e[31mERROR\e[0m] No internet connection, configuring internet connection."
    dhclient
    sleep 1;
    # network configuration TODO
fi

install_lxde () {
    echo " "
    echo "###################################################"
    echo "Setting up LXDE"
    echo "###################################################"

    pacman -Sy --noconfirm --disable-sandbox lxde xf86-video-fbdev lxde-icon-theme xorg-server xorg-xinit xterm noto-fonts ttf-dejavu lxde-common lxappearance xorg-xclock # Works but also doesn't?? Icons and backgrounds are broken, WIP..
    echo -e 'exec startlxde' > /etc/X11/xinit/xinitrc
    rm -rf /root/.bash_profile
    printf '%s\n' '#!/bin/bash' '' 'SESSION_TYPE=$(loginctl show-session $XDG_SESSION_ID -p Type --value)' 'echo ""' 'echo -e "Welcome to \e[96mArchPOWER Xbox 360 Linux\e[0m, $(whoami)!"' 'echo ""' 'echo -e "System load:\e[32m $(cat /proc/loadavg | cut -d" " -f1-3)\e[0m"' 'echo -e "IP address:\e[32m $(ip -4 -o addr show scope global | awk '\''{print $4}'\'' | cut -d/ -f1 | head -1 || echo "Not connected")\e[0m"' 'echo -e "Free system storage:\e[32m $(df -h / | awk '\''NR==2 {print $4}'\'')\e[0m"' 'echo ""' 'if [ "$SESSION_TYPE" == "tty" ]; then' '    if pgrep -x "Xorg" >/dev/null || pgrep -x "X" >/dev/null; then' '        echo "Xorg is running"' '    else' '        echo ""' '        echo -e "\e[33mStarting X in 5 seconds...\e[0m"' '        echo -e "\e[33mPress CTRL+C to continue in CLI.\e[0m"' '        echo ""' '        sleep 5' '        echo "Starting Xorg server with LXDE..."' '        exec startx' '    fi' 'fi' > /etc/profile.d/bash_profile.sh
}

install_lxqt () {
    echo " "
    echo "###################################################"
    echo "Setting up LXQt"
    echo "###################################################"

    pacman -Sy --noconfirm --disable-sandbox lxqt xf86-video-fbdev xorg-server xorg-xinit xterm noto-fonts ttf-dejavu xorg-xclock breeze-icons # Works
    echo -e 'exec startlxqt' > /etc/X11/xinit/xinitrc
    rm -rf /root/.bash_profile
    printf '%s\n' '#!/bin/bash' '' 'SESSION_TYPE=$(loginctl show-session $XDG_SESSION_ID -p Type --value)' 'echo ""' 'echo -e "Welcome to \e[96mArchPOWER Xbox 360 Linux\e[0m, $(whoami)!"' 'echo ""' 'echo -e "System load:\e[32m $(cat /proc/loadavg | cut -d" " -f1-3)\e[0m"' 'echo -e "IP address:\e[32m $(ip -4 -o addr show scope global | awk '\''{print $4}'\'' | cut -d/ -f1 | head -1 || echo "Not connected")\e[0m"' 'echo -e "Free system storage:\e[32m $(df -h / | awk '\''NR==2 {print $4}'\'')\e[0m"' 'echo ""' 'if [ "$SESSION_TYPE" == "tty" ]; then' '    if pgrep -x "Xorg" >/dev/null || pgrep -x "X" >/dev/null; then' '        echo "Xorg is running"' '    else' '        echo ""' '        echo -e "\e[33mStarting X in 5 seconds...\e[0m"' '        echo -e "\e[33mPress CTRL+C to continue in CLI.\e[0m"' '        echo ""' '        sleep 5' '        echo "Starting Xorg server with LXQt..."' '        exec startx' '    fi' 'fi' > /etc/profile.d/bash_profile.sh
}


echo " "
echo "###################################################"
echo "Arch POWER Xbox 360 Interactive Installer STAGE2 by ajww, gypsy & vmo64 (NGX)"
echo "Starting..."
echo "###################################################"
sleep 1;

systemctl restart systemd-timesyncd

whiptail --title "ArchPOWER Installer" --msgbox "=== Welcome to Stage 2 Setup ===\n\nThe system will now configure user settings.\n\nThe following utilities will be set up:\n - Xbox 360-utils\n - system-manager\n\nNote: The system-manager service runs on startup to set up the necessary system services/tools to save resources. One of its operations include pinging home the developer server to retrieve performance updates & patches (no data is submitted to the server). We DO NOT recommend disabling this service but if you wish to do so, run \"systemctl disable system-manager.service\" (disabling this service may cause system instabilities and WILL break Xbox 360-utils, networking and hi-speed VRAM based swap). The source code of the utility is available on our GitHub repo." 22 78

# Try IP detection
IP_TZ=""
if command -v curl &>/dev/null; then
    IP_TZ=$(curl -s --max-time 3 https://ipapi.co/timezone 2>/dev/null || curl -s --max-time 3 http://ip-api.com/line?fields=timezone 2>/dev/null)
fi

if [ -n "$IP_TZ" ] && whiptail --title "Timezone Detection" --yesno "Detected timezone: $IP_TZ\n\nUse detected timezone?" 12 50; then
    timedatectl set-timezone "$IP_TZ"
    TZ_SET="$IP_TZ"
else
    # Manual selection
    TZ_SET=$(timedatectl list-timezones | whiptail --title "Manual Timezone Selection" --menu "Select your timezone:" 20 60 13 $(awk '{print NR " " $0}') 3>&1 1>&2 2>&3)
    [ -n "$TZ_SET" ] && timedatectl set-timezone "$TZ_SET"
fi

# Keyboard selection
KB=$(whiptail --title "Keyboard Layout" --menu "Select your keyboard layout:" 35 65 24 \
    "al" "Albanian" \
    "ar" "Arabic" \
    "bg" "Bulgarian" \
    "bs" "Bosnian" \
    "by" "Belarusian" \
    "ca" "Canadian French" \
    "ch" "Swiss" \
    "cn" "Chinese" \
    "cz" "Czech" \
    "de" "German" \
    "dk" "Danish" \
    "ee" "Estonian" \
    "es" "Spanish" \
    "fi" "Finnish" \
    "fr" "French" \
    "gr" "Greek" \
    "he" "Hebrew" \
    "hr" "Croatian" \
    "hu" "Hungarian" \
    "ie" "Irish" \
    "in" "Indian" \
    "is" "Icelandic" \
    "it" "Italian" \
    "jp" "Japanese" \
    "kr" "Korean" \
    "lt" "Lithuanian" \
    "lv" "Latvian" \
    "mk" "Macedonian" \
    "mt" "Maltese" \
    "nl" "Dutch" \
    "no" "Norwegian" \
    "pl" "Polish" \
    "pt" "Portuguese" \
    "ro" "Romanian" \
    "rs" "Serbian" \
    "ru" "Russian" \
    "se" "Swedish" \
    "si" "Slovenian" \
    "sk" "Slovak" \
    "tr" "Turkish" \
    "ua" "Ukrainian" \
    "uk" "UK English" \
    "us" "US English" 3>&1 1>&2 2>&3)

[ -n "$KB" ] && localectl set-keymap "$KB"

GUI_SELECT=$(whiptail --title "GUI Installation" --menu "Install Desktop Environment?" 12 65 2 \
    "1" "Yes, install LXQt (recommended)" \
    "2" "Yes, install LXDE" \
    "3" "No, skip GUI installation" 3>&1 1>&2 2>&3)

export GUI_SELECT

video_mode_menu() {
    while true; do
        CATEGORY=$(whiptail --title "Video Mode" --menu "Select category:" 17 60 8 \
            "auto" "Auto Detect (0) USE THIS ONLY!" \
            "60hz" "60 Hz Broadcast (1-5)" \
            "50hz" "50 Hz Broadcast (6-10)" \
            "vesa" "VESA Modes (11-13)" \
            "full60" "60 Hz Full Screen (129-133)" \
            "full50" "50 Hz Full Screen (134-138)" \
            "back" "Go Back" 3>&1 1>&2 2>&3)
        
        [[ "$CATEGORY" == "back" ]] && return 1
        
        case $CATEGORY in
            "auto")
                VIDEO_MODE="0"
                export VIDEO_MODE
                return 0
                ;;
            "60hz")
                MODE=$(whiptail --title "60 Hz Modes" --menu "Select:" 12 50 6 \
                    "1" "480i (576x384)" \
                    "2" "480p (576x384)" \
                    "3" "720p (1124x644)" \
                    "4" "1080i (1688x964)" \
                    "5" "1080p (1688x964)" \
                    "back" "Back" 3>&1 1>&2 2>&3)
                ;;
            "50hz")
                MODE=$(whiptail --title "50 Hz Modes" --menu "Select:" 12 50 6 \
                    "6" "576i (576x460)" \
                    "7" "576p (576x460)" \
                    "8" "720p (1124x644)" \
                    "9" "1080i (1688x964)" \
                    "10" "1080p (1688x964)" \
                    "back" "Back" 3>&1 1>&2 2>&3)
                ;;
            "vesa")
                MODE=$(whiptail --title "VESA Modes" --menu "Select:" 10 50 4 \
                    "11" "wxga (1280x768)" \
                    "12" "sxga (1280x1024)" \
                    "13" "wuxga (1920x1200)" \
                    "back" "Back" 3>&1 1>&2 2>&3)
                ;;
            "full60")
                MODE=$(whiptail --title "60 Hz Full Screen" --menu "Select:" 12 50 6 \
                    "129" "480if (720x480)" \
                    "130" "480pf (720x480)" \
                    "131" "720pf (1280x720)" \
                    "132" "1080if (1920x1080)" \
                    "133" "1080pf (1920x1080)" \
                    "back" "Back" 3>&1 1>&2 2>&3)
                ;;
            "full50")
                MODE=$(whiptail --title "50 Hz Full Screen" --menu "Select:" 12 50 6 \
                    "134" "576if (720x576)" \
                    "135" "576pf (720x576)" \
                    "136" "720pf (1280x720)" \
                    "137" "1080if (1920x1080)" \
                    "138" "1080pf (1920x1080)" \
                    "back" "Back" 3>&1 1>&2 2>&3)
                ;;
        esac
        
        [[ "$MODE" == "back" ]] && continue
        [[ -n "$MODE" ]] && export VIDEO_MODE="$MODE" && return 0
    done
}

video_mode_menu

if [[ $? -eq 0 ]]; then
    echo "Video mode selected: $VIDEO_MODE"
else
    echo "User cancelled or went back"
fi


mkdir /etc/system-manager
echo $VIDEO_MODE > /etc/system-manager/video-mode.conf

# Summary
#whiptail --title "System Configuration Complete" --msgbox "Configuration finished!\n\n• Timezone: ${TZ_SET:-Not set}\n• Keyboard: ${KB:-Not set}\n• Video Mode: ${VIDEO_MODE:-Not set}\n• GUI: $([ "$GUI_SELECT" = "1" ] && echo "LXQt" || $([ "$GUI_SELECT" = "2" ] && echo "LXDE" || echo "None")" 15 60
whiptail --title "System Configuration Complete" --msgbox "Configuration finished!\n\n• Timezone: ${TZ_SET:-Not set}\n• Keyboard: ${KB:-Not set}\n• Video Mode: ${VIDEO_MODE:-Not set}\n• GUI: $([ "$GUI_SELECT" = "1" ] && echo "LXDE" || ([ "$GUI_SELECT" = "2" ] && echo "LXQt" || echo "None"))" 15 60

clear
echo " "
echo "###################################################"
echo "Setting up ZRAM"
echo "###################################################"
echo " "

echo -e '[zram0]\nzram-size = ram\nswap-priority = 100\ncompression-algorithm = zstd' | tee /etc/systemd/zram-generator.conf > /dev/null
systemctl daemon-reload
systemctl start dev-zram0.swap


# Update system-manager service
systemctl stop system-manager
mv /usr/local/bin/system-manager/sys-man /usr/local/bin/system-manager/sys-man.bak
curl -o /usr/local/bin/system-manager/sys-man https://raw.githubusercontent.com/vmo64/archpower-linux-installer-360/refs/heads/main/sys-man.sh
curl -o /usr/local/bin/system-manager/updater.sh https://raw.githubusercontent.com/vmo64/archpower-linux-installer-360/refs/heads/main/updater.sh
chmod +x /usr/local/bin/system-manager/sys-man
chmod +x /usr/local/bin/system-manager/updater.sh


if [[ $GUI_SELECT = "1" ]]
then
    install_lxqt
fi

if [[ $GUI_SELECT = "2" ]]
then
    install_lxde
fi

if [[ $GUI_SELECT = "3" ]]
then
    rm -rf /root/.bash_profile
    printf '%s\n' '#!/bin/bash' '' 'echo ""' 'echo -e "Welcome to \e[96mArchPOWER Xbox 360 Linux\e[0m, $(whoami)!"' 'echo ""' 'echo -e "System load:\e[32m $(cat /proc/loadavg | cut -d" " -f1-3)\e[0m"' 'echo -e "IP address:\e[32m $(ip -4 -o addr show scope global | awk '\''{print $4}'\'' | cut -d/ -f1 | head -1 || echo "Not connected")\e[0m"' 'echo -e "Free system storage:\e[32m $(df -h / | awk '\''NR==2 {print $4}'\'')\e[0m"' 'echo ""' > /etc/profile.d/bash_profile.sh
fi

rm -rf /etc/systemd/system/getty@tty1.service.d/override.conf

whiptail --title "Install Completed" --msgbox "=== ArchPOWER Xbox 360 Install completed ===\n\nThe system will now restart. " 10 50
sleep 1;
reboot
