#!/bin/bash

systemctl stop system-manager.service
mv /usr/local/bin/system-manager/sys-man /usr/local/bin/system-manager/sys-man.bak
curl -O /usr/local/bin/system-manager/sys-man https://raw.githubusercontent.com/vmo64/archpower-linux-installer-360/refs/heads/main/sys-man.sh
exit;
