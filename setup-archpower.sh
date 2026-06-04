#!/bin/sh
clear
echo "##### RUNNING SETUP #####"

# Check if /dev/sda
if [ ! -b "/dev/sda" ]; then
    echo -e "[\e[33mWARN\e[0m] /dev/sda does not exist. Internal HDD installation mode is [\e[31mDISABLED\e[0m!"
    # exit 1
else
    echo -e "[\e[32m OK \e[0m] /dev/sda detected. You can install to the Internal HDD."
fi

if ping -c 1 -W 2 google.com > /dev/null 2>&1; then
    echo -e "[\e[32m OK \e[0m] Network (eth0) is UP, continuing."
else
    echo -e "[\e[31mERROR\e[0m] No internet connection, configuring internet connection."
    
    # network configuration TODO
fi

install() {
    clear
    echo " "
    echo "###################################################"
    echo "Where do you want to install Linux?"
    echo "###################################################"
    echo " "
    echo "Options:"
    if [[ ! -b "/dev/sda" ]]; then
        echo "1 - Internal Xbox 360 Storage (/dev/sda) (DISABLED, refer to DOCS)"
    else
        echo "1 - Internal Xbox 360 Storage (/dev/sda)"
    fi
    echo "2 - External Drive"
    echo "3 - Go back to main menu"
    echo " "
    read -p "Please enter the desired option: " PART_METHOD
    echo " "

    case "$PART_METHOD" in
        3) main_menu; return ;;
        ""|[^12]*) install; return ;;
    esac

    # Filesystem selection
    echo "###################################################"
    echo "Root filesystem:"
    echo "1 - ext4 (recommended)"
    echo "2 - ext3"
    echo "3 - btrfs"
    echo "###################################################"
    read -p "Choice: " FS_CHOICE
    case "$FS_CHOICE" in
        2) ROOT_FS="ext3" ;;
        3) ROOT_FS="btrfs" ;;
        *) ROOT_FS="ext4" ;;
    esac

    # Method 1: Internal
    if [[ "$PART_METHOD" == "1" ]]; then
        if [[ ! -b "/dev/sda" ]]; then
            install; return
        fi

        clear
        echo "###################################################"
        echo "Installing ArchPOWER to internal HDD medium"
        echo "Note: You cannot dualboot XboxOS and Linux on the internal hdd."
        echo "###################################################"
        echo "Partition layout:"
        echo "  /boot  ->  64MiB   ext2"
        echo "  /      ->  rest    $ROOT_FS"
        echo "###################################################"
        echo -e "Warning: This will \e[31mPERMANENTLY DELETE\e[0m all data on /dev/sda!"
        echo "Starting in 5 seconds, press CTRL+C to abort!"
        echo "###################################################"
        sleep 5

        parted -s /dev/sda \
            mklabel msdos \
            mkpart primary ext2 1MiB 64MiB \
            mkpart primary "$ROOT_FS" 64MiB 100%

        mapfile -t P < <(lsblk -lnpo NAME /dev/sda | tail -n +2)
        PART1="${P[0]}"; PART2="${P[1]}"

        echo "Formatting partitions..."
        mkfs.ext2 -L boot "$PART1"
        if [[ "$ROOT_FS" == "btrfs" ]]; then # mkfs.btrfs requires -f flag to reformat an existing partition, mkfs.extX doesn't require nor support said flag
            mkfs."$ROOT_FS" -f "$PART2"
        else
            mkfs."$ROOT_FS" -L root "$PART2"
        fi

        echo "Mounting volumes..."
        mount "$PART2" /mnt
        mkdir -p /mnt/boot
        mount "$PART1" /mnt/boot

        PART_UUID=$(blkid -s PARTUUID -o value "$PART2")
    fi

    # Method 2: External
    if [[ "$PART_METHOD" == "2" ]]; then

        echo "###################################################"
        echo "Available drives:"
        echo "###################################################"
        lsblk -dpno NAME,SIZE,MODEL | grep -v "sda\|loop\|sr"
        echo " "
        while true; do
            read -p "Enter disk to use (/dev/sdX): " DISK
            if [[ ! -b "$DISK" ]]; then
                echo "ERROR: '$DISK' is not a valid block device, try again."
            elif [[ "$DISK" == "/dev/sda" ]]; then
                echo "ERROR: Use option 1 for internal storage."
            else
                break
            fi
        done

        echo " "
        echo "###################################################"
        echo "Enter root size in GiB, or 100% to fill the disk."
        echo "###################################################"
        read -p "Root size: " ROOT_SIZE
        if [[ "$ROOT_SIZE" != *"%" && "$ROOT_SIZE" != *"iB" ]]; then
            ROOT_SIZE="${ROOT_SIZE}GiB"
        fi

        clear
        echo "###################################################"
        echo "Partition plan for $DISK:"
        echo "###################################################"
        echo "  /boot  ->  64MiB      ext2"
        echo "  /      ->  $ROOT_SIZE   $ROOT_FS"
        echo "###################################################"
        echo -e "Warning: This will \e[31mPERMANENTLY DELETE\e[0m all data on $DISK!"
        echo "Starting in 5 seconds, press CTRL+C to abort!"
        echo "###################################################"
        sleep 5

        parted -s "$DISK" \
            mklabel msdos \
            mkpart primary ext2 1MiB 64MiB \
            mkpart primary "$ROOT_FS" 64MiB "$ROOT_SIZE"

        mapfile -t P < <(lsblk -lnpo NAME "$DISK" | tail -n +2)
        PART1="${P[0]}"; PART2="${P[1]}"

        echo "Formatting partitions..."
        mkfs.ext2 -L boot "$PART1"
        if [[ "$ROOT_FS" == "btrfs" ]]; then # mkfs.btrfs requires -f flag to reformat an existing partition, mkfs.extX doesn't require nor support said flag
            mkfs."$ROOT_FS" -f "$PART2"
        else
            mkfs."$ROOT_FS" -L root "$PART2"
        fi

        echo "Mounting volumes..."
        mount "$PART2" /mnt
        mkdir -p /mnt/boot
        mount "$PART1" /mnt/boot

        PART_UUID=$(blkid -s PARTUUID -o value "$PART2")
    fi

    # Shared error check
    if [[ -z "$PART_UUID" ]]; then
        echo "###################################################"
        echo -e "[\e[31mERROR\e[0m] Install Failed!"
        echo "###################################################"
        echo "Something went wrong when creating the partitions."
        echo "Reason: Could not get PARTUUID (partition may not exist)"
        echo "Partition: $PART2"
        echo " "
        echo "Exiting to shell. Run 'bash .automated_script.sh' to re-run."
        exit 1
    fi

    
        clear
        echo " "
        echo " "
        echo " "
        echo "###################################################"
        echo "Installing Linux"
        echo "###################################################"
        echo " "
        echo "Mountpoint partition: "$PART2
        echo "###################################################"
        echo " "
        sleep 3;
        echo " "
        read -p "Please enter your desired username: " USER_NAME
        echo " ";
        read -p "Please enter the desired root user password: " -s USER_ROOT_PASS
        echo " "

        clear
        echo " "
        echo " "
        echo "###################################################"
        echo "Installing Linux"
        echo "###################################################"
        echo " "
        echo "Creating SWAP Space (512MiB)"
        echo " "

        if [[ "$ROOT_FS" == "btrfs" ]]; then # Classic swap doesn't want to mount with BTRFS, using PS3VRAM instead
            echo "Not making SWAP, no hw swap on 360... To be fixed later."
        else
            dd if=/dev/zero of=/mnt/swapfile bs=1M count=512
            chmod 0600 /mnt/swapfile
            mkswap /mnt/swapfile
            swapon -p 10 /mnt/swapfile
        fi

        sleep 1;

        clear
        echo " "
        echo " "
        echo "###################################################"
        echo "Installing Linux"
        echo "###################################################"
        echo " "
        echo "Create vconsole.conf"
        echo " "

        mkdir -p /mnt/etc && echo -e "KEYMAP=us\nFONT=lat9w-16" > /mnt/etc/vconsole.conf
        sleep 1;
        
        clear
        echo " "
        echo " "
        echo "###################################################"
        echo "Installing Linux"
        echo "###################################################"
        echo " "
        echo "Installing ArchPOWER packages"
        echo " "
        sleep 2;

        sed -i 's/^SigLevel\s*=\s*Required DatabaseOptional$/SigLevel    = Never/' /etc/pacman.conf # Disable GPG Check in Pacman as root key is invalid
        sudo sed -i '/^\[options\]/a DisableSandbox' /etc/pacman.conf # Fix sandbox bug
        
        pacman-key --recv-keys D201F92AE42528456537C3F9B96775F34689694C
        echo 'D201F92AE42528456537C3F9B96775F34689694C:4:' >>/usr/share/pacman/keyrings/archpower-trusted
        pacman-key --populate archpower
        pacman -Sy archpower-keyring

        pacstrap -K /mnt base linux-xenon linux-xenon-headers wget nano vim openssh iputils iproute2 dhclient net-tools htop neofetch sudo git autoconf automake libtool base-devel libnewt zram-generator #networkmanager
        
        genfstab -U /mnt >> /mnt/etc/fstab

        PART_UUID=$(blkid -s PARTUUID -o value $PART2)

        clear
        echo " "
        echo " "
        echo "###################################################"
        echo "Installing Linux"
        echo "###################################################"
        echo " "
        echo "Creating KBOOT bootloader entry"
        echo " "

        #printf 'timeout=100\ndefault=ArchPower\nArchPower="/vmlinuz-linux-ps3 arch=ppc64 quiet loglevel=N video=ps3fb:mode:131 root=PARTUUID=%s initrd=/initramfs-linux-ps3.img"\n' "$PART_UUID" > /mnt/boot/kboot.conf # Configure Kboot/PetitBoot Entry
        #printf 'timeout=5\ndefault=ArchPower\nArchPower="/vmlinuz-linux-xenon arch=ppc loglevel=N root=%s initrd=/initramfs-linux-xenon.img"\n' "$PART2" > /mnt/boot/kboot.conf # Configure Kboot/PetitBoot Entry (FIX FOR THE TIME BEING WHILE KERNEL IS BEING PATCHED AGAIN)
        printf 'timeout=5\ndefault=ArchPower\nArchPower="/vmlinuz-linux-xenon arch=ppc loglevel=N root=%s initrd=/initramfs-linux-xenon.img"\n' "$PART2" > /mnt/boot/kboot.conf # better entry (FIX FOR THE TIME BEING WHILE KERNEL IS BEING PATCHED AGAIN)
        sleep 1;
        #printf '[main]\ndhcp=dhclient\n' > /mnt/etc/NetworkManager/conf.d/dhcp-client.conf # Autoconfigure network on boot


        echo " "
        echo "Configuring and installing system-manager service"
        echo " "

        mkdir /mnt/usr/local/bin/system-manager
        curl -o /mnt/usr/local/bin/system-manager/sys-man https://raw.githubusercontent.com/vmo64/archpower-linux-installer-360/refs/heads/main/sys-man.sh # Download latest system-manager script
        curl -o /mnt/usr/local/bin/system-manager/stage2-install.sh https://raw.githubusercontent.com/vmo64/archpower-linux-installer-360/refs/heads/main/stage2-install.sh # Download latest stage2-install script
        curl -o /mnt/usr/local/bin/system-manager/updater.sh https://raw.githubusercontent.com/vmo64/archpower-linux-installer-360/refs/heads/main/updater.sh # Download latest system-manager updater script
        arch-chroot /mnt /bin/bash -c "chmod +x /usr/local/bin/system-manager/stage2-install.sh"
        arch-chroot /mnt /bin/bash -c "chmod +x /usr/local/bin/system-manager/sys-man"
        arch-chroot /mnt /bin/bash -c "chmod +x /usr/local/bin/system-manager/updater.sh"
        echo -e '[Unit]\nAfter=sysinit.target\n\n[Service]\nType=oneshot\nExecStart=/usr/local/bin/system-manager/sys-man autostart\n\n[Install]\nWantedBy=multi-user.target' > /mnt/etc/systemd/system/system-manager.service #Install the system-manager service
        arch-chroot /mnt /bin/bash -c "ln -sf ../system-manager.service /etc/systemd/system/multi-user.target.wants/"
        arch-chroot /mnt /bin/bash -c "ln -sf ../systemd-timesyncd.service /etc/systemd/system/multi-user.target.wants/"

        echo " "
        echo "Setting up user accounts"
        echo " "
        
        arch-chroot /mnt /bin/bash -c "useradd -m -G wheel -s /bin/bash $USER_NAME"
        arch-chroot /mnt /bin/bash -c "sed -i 's/^#\s*PermitRootLogin\s\+prohibit-password\s*$/PermitRootLogin yes/;s/^#\s*PermitRootLogin\s\+without-password\s*$/PermitRootLogin yes/' /etc/ssh/sshd_config" # Enable root user login via SSH
        arch-chroot /mnt sh -c "mkdir -p /etc/systemd/system/getty@tty1.service.d && echo -e '[Service]\nExecStart=\nExecStart=-/usr/bin/agetty --autologin root --noclear %I $TERM' | tee /etc/systemd/system/getty@tty1.service.d/override.conf > /dev/null" # Enable autologin for first time
        arch-chroot /mnt sh -c "echo $USER_NAME':'$USER_ROOT_PASS | chpasswd" # Change ROOT user password
        arch-chroot /mnt sh -c "echo 'root:'$USER_ROOT_PASS | chpasswd" # Change ROOT user password
        arch-chroot /mnt sh -c "sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers" # Enable SUDO for users
        
        echo " "
        echo "Configuring stage2 installer"
        echo " "
        
        arch-chroot /mnt sh -c "echo -e '/usr/local/bin/system-manager/stage2-install.sh' > /root/.bash_profile" # Add the stage2 installer to autorun

        echo " "
        echo " "
        echo " "
        echo "###################################################"
        echo "Stage1 Install Completed!"
        echo "###################################################"
        echo "System is rebooting into the second installation stage."
        echo "The install will continue once you log into the system."
        echo "###################################################"
        echo " "
        echo "###################################################"
        echo -e "\e[31mPlease remove your installation media after the system restarts.\e[0m"
        echo "System is rebooting in 5 seconds."
        echo "###################################################"
        echo " "
        sleep 5; 
        reboot





}


# Script main menu
menu () {

    echo " "
    echo "###################################################"
    echo -e "\e[96mArchPOWER\e[0m Xbox 360 Linux Installer by ajww, gypsy & vmo64"
    echo "Version: 03.06.2026."
    echo "###################################################"
    sleep 1;
    echo " "
    echo "###################################################"
    echo " "
    echo "What do you want to do:"
    echo "1 - Install ArchPOWER Linux Xbox 360"
    echo "2 - Exit to shell"
    echo "3 - Reboot"
    echo " "
    echo "Enter the option you want to run below (eg. 1), if the script quits then you have entered an invalid option."
    echo "###################################################"
    echo " "
    read -p "Please enter the desired option: " MAINSELECTION
    echo " "


    if [[ $MAINSELECTION = "1" ]]
    then
        install
    fi

    if [[ $MAINSELECTION = "2" ]]
    then
        exit
    fi

    if [[ $MAINSELECTION = "3" ]]
    then
        reboot
    fi
}


menu
