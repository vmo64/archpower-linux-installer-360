#!/bin/bash

# System manager script for Arch Power Xbox 360 Linux
# Built by ajww, gypsy & vmo64 (NGX)
# Disabling this script will cause system instability!

# Version 03.06.2026.



if [ "$1" == "autostart" ]; then
    # Configure network
    if ping -c 1 -W 2 google.com > /dev/null 2>&1; then
        echo -e "[\e[32m OK \e[0m] Network (eth0) is UP."
    else
        dhclient 
    fi

    # Crude way to fix out-of-sync time on boot
    systemctl restart systemd-timesyncd

    # Enable RSX VRAM to be used as high-speed SWAP (360 RAM is shared, not needed!)
    #mkswap /dev/ps3vram
    #sudo swapon -p 50 /dev/ps3vram

    # Create symlinks to reroute ps3-util names to traditional names (Will be redone with 360 specific stuff if needed)
    #ln -sf /dev/ps3vflashf /dev/ps3flash
    #ln -sf /dev/ps3strgmngr /dev/ps3stormgr
    #ln -sf /dev/ps3lv1 /dev/ps3hvcall

    # Video mode config (not supported on 360)
    #VIDEO_MODE=$(cat "/etc/system-manager/video-mode.conf")
    #ps3-video-mode -m $VIDEO_MODE

    # Make agresssive swap scheme
    sysctl vm.swappiness=60
    sysctl vm.vfs_cache_pressure=100
    sysctl vm.min_free_kbytes=8192 # Do not fill the last 8MiB of RAM
    sysctl vm.watermark_scale_factor=10

    # Run the updater script after initializing system (check for updates)
    nohup /usr/local/bin/system-manager/updater.sh &
fi
