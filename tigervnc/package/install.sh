#!/bin/bash
require files
files_load_config distro

if [[ "$cw_DIST" == "el6" || "$cw_DIST" == "el7" ]]; then
  yum install -y -e0 mesa-libGL libXdmcp pixman xorg-x11-fonts-misc
  yum -e0 -y install uuid netpbm-progs iproute xauth xkeyboard-config xorg-x11-xkb-utils xorg-x11-apps xorg-x11-server-utils xterm
elif [[ "$cw_DIST" == "ubuntu1604" ]]; then
  apt-get install -y libgl1-mesa-glx libglapi-mesa libxdmcp6 libpixman-1-0 xfonts-base x11-xserver-utils libjpeg8
  apt-get install -y uuid netpbm iproute xauth xkb-data x11-xkb-utils x11-apps x11-utils xterm software-properties-common
fi

cp -R data/* "${cw_ROOT}"
