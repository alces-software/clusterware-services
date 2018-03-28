#!/bin/bash

_configure_home_volume() {
    local dev
    dev=$1
    echo "Configuring home volume (${dev})"
    mkfs.ext4 -m0 -L home ${dev}
    mount ${dev} /mnt
    mv /home/* /mnt
    umount /mnt
    mount ${dev} /home
    echo "${dev} /home ext4 defaults 0 0" >> /etc/fstab
}

_configure_apps_volume() {
    local dev
    dev=$1
    echo "Configuring apps volume (${dev})"
    mkfs.ext4 -m0 -L applications ${dev}
    files_load_config --optional gridware
    cw_GRIDWARE_root="${cw_GRIDWARE_root:-/opt/gridware}"
    mkdir -p "${cw_GRIDWARE_root}"
    mount ${dev} /opt/gridware
    if [ -d /opt/apps ]; then
        mkdir /opt/gridware/.apps
        mv /opt/apps/* /opt/gridware/.apps
        mount -o bind /opt/gridware/.apps /opt/apps
    fi
    echo "${dev} ${cw_GRIDWARE_root} ext4 defaults 0 0" >> /etc/fstab
    echo "${cw_GRIDWARE_root}/.apps /opt/apps none defaults,bind 0 0" >> /etc/fstab
}

main() {
    if [ -b /dev/xvdp ]; then
        umount /dev/xvdp* &>/dev/null
        _configure_home_volume /dev/xvdp
    elif [ -b /dev/sdp ]; then
        umount /dev/sdp* &>/dev/null
        _configure_home_volume /dev/sdp
    else
        echo "Neither /dev/xvdp nor /dev/sdp found, not configuring home volume."
    fi

    if [ -b /dev/xvdq ]; then
        umount /dev/xvdq* &>/dev/null
        _configure_apps_volume /dev/xvdq
    elif [ -b /dev/sdq ]; then
        umount /dev/sdq* &>/dev/null
        _configure_apps_volume /dev/sdq
    else
        echo "Neither /dev/xvdq nor /dev/sdq found, not configuring apps volume."
    fi
}

require files

main
