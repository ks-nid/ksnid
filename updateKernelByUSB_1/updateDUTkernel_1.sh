#!/bin/bash

# Copyright (c) 2009-2011 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Script to update the kernel on a live running ChromiumOS instance.
YELLOW_COLOR='\E[1;33m'
GREEN_COLOR='\E[1;32m' 
RED_COLOR='\E[1;31m'
RES='\E[0m'

fun1() {
echo -e "${YELLOW_COLOR} Please make sure you have run \"make_dev_ssd.sh --remove_rootfs_verification -f\""
echo -e "and reboot before run this script(y/n)? ${RES}"
read c
case $c in
y)
	rm -rf /tmp/config_save.txt.2
	(/usr/share/vboot/bin/make_dev_ssd.sh --save_config /tmp/config_save.txt --partition 2)
	grep -e "rootwait rw" /tmp/config_save.txt.2
	if [ "$?" -eq "0" ];then
	update_DUT_kernel
	else
	echo -e "${RED_COLOR} System is using verity: First remove rootfs verification using  !!!  ${RES}"
	echo -e "${RED_COLOR} Excute command:/usr/share/vboot/bin/make_dev_ssd.sh --remove_rootfs_verification -f    ${RES}"
	fi
;;
*)
echo "This script has stopped running."
;;
esac
}



update_DUT_kernel(){

local KA_mmc="/dev/mmcblk0p2" 
local KA_nvme="/dev/nvme0n1p2"
local RA_mmc="/dev/mmcblk0p3" 
local RA_nvme="/dev/nvme0n1p3" 
local KB_mmc="/dev/mmcblk0p4" 
local KB_nvme="/dev/nvme0n1p4" 
local RB_mmc="/dev/mmcblk0p5" 
local RB_nvme="/dev/nvme0n1p5"
local a=$(find | grep .tar.gz)
local b=${a:2} 
local backupFileName="${b}"


if [ -d /tmp/RA ]; then
echo "do umount/rm /tmp/RA"
umount /tmp/RA
rm -rf /tmp/RA
fi

if [ -d /tmp/RB ]; then
echo "do umount/rm /tmp/RB"
umount /tmp/RB
rm -rf /tmp/RB
fi 

rm -rf /tmp/mnt

mkdir /tmp/RA
mkdir /tmp/RB
mkdir /tmp/mnt


  if [ -f ${backupFileName} ]; then
    cp -a ./${backupFileName} /tmp/mnt
    tar -zxvf /tmp/mnt/${backupFileName} -C /tmp/mnt > ./log.txt
  else
    echo "no tar file!!!"
    exit 1
  fi

  if [ -b ${KA_mmc} ]; then
   dd if=/tmp/mnt/tmp1234/new_kern.bin of=${KA_mmc}
  elif [ -b ${KA_nvme} ]; then
   dd if=/tmp/mnt/tmp1234/new_kern.bin of=${KA_nvme}
  else
    echo "kernel-A not found"
  fi
	
  if [ -b ${KB_mmc} ]; then
   dd if=/tmp/mnt/tmp1234/new_kern.bin of=${KA_mmc}
  elif [ -b ${KB_nvme} ]; then
   dd if=/tmp/mnt/tmp1234/new_kern.bin of=${KB_nvme}
  else
    echo "kernel-B not found"
  fi

  if [ -b ${RA_mmc} ]; then
   mount ${RA_mmc} /tmp/RA 
  elif [ -b ${RA_nvme} ]; then
   mount ${RA_nvme} /tmp/RA
  else
    echo "Root-A not found"
  fi

  if [ -b ${RB_mmc} ]; then
   mount ${RB_mmc} /tmp/RB 
  elif [ -b ${RB_nvme} ]; then
   mount ${RB_nvme} /tmp/RB
  else
    echo "Root-B not found"
  fi

 rm -rf /tmp/RA/lib/modules/4.1*
 cp -a /tmp/mnt/tmp1234/modules/4.1* /tmp/RA/lib/modules
 rm -rf /tmp/RB/lib/modules/4.1*
 cp -a /tmp/mnt/tmp1234/modules/4.1* /tmp/RB/lib/modules
 sync

 umount /tmp/RA
 umount /tmp/RB

 rm -rf /tmp/mnt
 rm -rf /tmp/RA
 rm -rf /tmp/RB
 sync

 echo "done"
}


main() {
if [  ! -n "$1" ] ;then
 echo "start"
 fun1
 exit 1
else
  if [ "$1" = "-h" -o "--help" ]
  then
  echo -e "${GREEN_COLOR} ########################################################################################## ${RES}"
  echo -e "${GREEN_COLOR} #                                                                                        # ${RES}"
  echo -e "${GREEN_COLOR} #System is using verity: First remove rootfs verification using                          # ${RES}"
  echo -e "${GREEN_COLOR} #Excute command:/usr/share/vboot/bin/make_dev_ssd.sh --remove_rootfs_verification -f     # ${RES}"
  echo -e "${GREEN_COLOR} #                                                                                        # ${RES}"
  echo -e "${GREEN_COLOR} ########################################################################################## ${RES}"
  exit 0
  fi
fi
exit 1

}

main "$@"
