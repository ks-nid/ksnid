#!/bin/bash

# Copyright (c) 2009-2011 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Script to update the kernel on a live running ChromiumOS instance.


update_DUT_kernel(){

  echo "Please make sure you have run \"make_dev_ssd.sh --remove_rootfs_verification -f\""
  echo "and reboot before run this script"

local KA_mmc="/dev/mmcblk0p2" 
local KA_nvme="/dev/nvme0n1p2"
local RA_mmc="/dev/mmcblk0p3" 
local RA_nvme="/dev/nvme0n1p3" 
local KB_mmc="/dev/mmcblk0p4" 
local KB_nvme="/dev/nvme0n1p4" 
local RB_mmc="/dev/mmcblk0p5" 
local RB_nvme="/dev/nvme0n1p5"
local backupFileName="a.tar.gz"

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

echo "start"
update_DUT_kernel
exit 1

}

main
