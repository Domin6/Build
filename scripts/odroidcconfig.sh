#!/bin/bash

# This script will be run in chroot under qemu.

echo "Creating \"fstab\""
echo "# OdroidC fstab" > /etc/fstab
echo "" >> /etc/fstab
echo "proc            /proc           proc    defaults        0       0
/dev/mmcblk0p1  /boot           vfat    defaults,utf8,user,rw,umask=111,dmask=000        0       1
tmpfs   /var/log                tmpfs   size=20M,nodev,uid=1000,mode=0777,gid=4, 0 0 
tmpfs   /var/cache/apt/archives tmpfs   defaults,noexec,nosuid,nodev,mode=0755 0 0
tmpfs   /var/spool/cups         tmpfs   defaults,noatime,mode=0755 0 0
tmpfs   /var/spool/cups/tmp     tmpfs   defaults,noatime,mode=0755 0 0
tmpfs   /tmp                    tmpfs   defaults,noatime,mode=0755 0 0
" > /etc/fstab

echo "Prevent services starting during install, running under chroot" 
echo "(avoids unnecessary errors)"
cat > /usr/sbin/policy-rc.d << EOF
exit 101
EOF
chmod +x /usr/sbin/policy-rc.d

echo "Adding volumio-remote-updater"
wget -P /usr/local/sbin/ http://repo.volumio.org/Volumio2/Binaries/volumio-remote-updater

echo "Installing additonal packages"
apt-get update
apt-get -y install busybox parted u-boot-tools liblircclient0 lirc 

echo "Adding volumio-remote-updater"
wget -P /usr/local/bin/ http://updates.volumio.org/jx
#wget -P /usr/local/sbin/ http://repo.volumio.org/Volumio2/Binaries/volumio-remote-updater.jx
wget -P /usr/local/sbin/ http://updates.volumio.org/volumio-remote-updater.jx
chmod +x /usr/local/sbin/volumio-remote-updater.jx /usr/local/bin/jx

echo "Cleaning APT Cache and remove policy file"
rm -f /var/lib/apt/lists/*archive*
apt-get clean
rm /usr/sbin/policy-rc.d

echo "Adding custom module squashfs"
echo "squashfs" >> /etc/initramfs-tools/modules
echo "Adding custom module nls_cp437" 
echo "(needed to mount usb /dev/sda1 during initramfs"
echo "nls_cp437" >> /etc/initramfs-tools/modules

echo "Copying volumio initramfs updater"
cd /root/
mv volumio-init-updater /usr/local/sbin

echo "Changing to 'modules=dep'"
echo "(otherwise Odroid won't boot due to uInird 4MB limit)"
sed -i "s/MODULES=most/MODULES=dep/g" /etc/initramfs-tools/initramfs.conf

echo "Creating initramfs 'volumio.initrd'"
mkinitramfs-custom.sh -o /tmp/initramfs-tmp

echo "Creating uImage from 'volumio.initrd'"
mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n uInitrd -d /boot/volumio.initrd /boot/uInitrd

echo "Removing unnecessary /boot files"
rm /boot/volumio.inird
rm /boot/cmdline.txt
rm /boot/config.txt




