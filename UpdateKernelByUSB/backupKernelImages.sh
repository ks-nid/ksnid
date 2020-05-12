#!/bin/bash

# Copyright (c) 2009-2011 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Script to update the kernel on a live running ChromiumOS instance.

SCRIPT_ROOT=$(dirname $(readlink -f "$0"))
. "${SCRIPT_ROOT}/common.sh" || exit 1
. "${SCRIPT_ROOT}/remote_access.sh" || exit 1

# Script must be run inside the chroot.
restart_in_chroot_if_needed "$@"

ORIG_ARGS=("$@")

# Parse command line.
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"

# Only now can we die on error.  shflags functions leak non-zero error codes,
# so will die prematurely if 'switch_to_strict_mode' is specified before now.
switch_to_strict_mode


learn_arch() {
  [ -n "${FLAGS_arch}" ] && return
  FLAGS_arch=$(sed -n -E 's/^CONFIG_(ARM|ARM64|X86)=y/\1/p' \
               /build/"${BOARD}"/boot/config-* | \
               uniq | awk '{print tolower($0)}')
  if [ -z "${FLAGS_arch}" ]; then
    error "Arch required"
    exit 1
  fi
  info "Target reports arch is ${FLAGS_arch}"
}


make_local_kernelimage() {
  local bootloader_path
  local kernel_image
  local config_path="${SRC_ROOT}/build/images/${BOARD}/latest/config.txt"

  if [[ "${FLAGS_arch}" == "arm" || "${FLAGS_arch}" == "arm64" ]]; then
    name="bootloader.bin"
    bootloader_path="${SRC_ROOT}/build/images/${BOARD}/latest/${name}"
    # If there is no local bootloader stub, create a dummy file.  This matches
    # build_kernel_image.sh.  If we wanted to be super paranoid, we could copy
    # and extract it from the remote image, if it had one.
    if [[ ! -e "${bootloader_path}" ]]; then
      warn "Bootloader does not exist; creating a stub"
      bootloader_path="${TMP}/${name}"
      truncate -s 512 "${bootloader_path}"
    fi
    kernel_image="/build/${BOARD}/boot/vmlinux.uimg"
  else
    bootloader_path="/lib64/bootstub/bootstub.efi"
    kernel_image="/build/${BOARD}/boot/vmlinuz"
  fi

 if [ -d "${BOARD}/$1" ];then
  error "Directory ${BOARD}/$1 exists, files no backup succefully"
  exit 1
 else
  mkdir -p ${BOARD}/${now}
 fi

  vbutil_kernel --pack ./${BOARD}/$1/new_kern.bin \
    --keyblock /usr/share/vboot/devkeys/kernel.keyblock \
    --signprivate /usr/share/vboot/devkeys/kernel_data_key.vbprivk \
    --version 1 \
    --config ${config_path} \
    --bootloader "${bootloader_path}" \
    --vmlinuz "${kernel_image}" \
    --arch "${FLAGS_arch}"


    info "kernel image backup to ${BOARD}/$1 done"

    #exit 1
}


copy_local_kernelmodules() {
  local basedir="$1" # rootfs directory (could be in /tmp) or empty string
  local modules_dir=/build/"${BOARD}"/lib/modules/
  if [ ! -d "${modules_dir}" ]; then
    warn "No modules. Skipping."
    return
  fi

  info "Copying modules "
  cp -a "${modules_dir}" ${BOARD}/$1

  info "kernel modules backup to ${BOARD}/$1 done"
}


tarFiles(){
  if [ ! -f ${backupFileName} ]; then
    rm -rf tmp1234
    mkdir tmp1234
    cp -a ./${BOARD}/${now}/modules  ./${BOARD}/${now}/new_kern.bin tmp1234
    tar -zcvf ${backupFileName} tmp1234
    rm -rf tmp1234
    return
  else
    warn "file exists! Skipping."
  fi
}

main() {
  local now="$(date +'%m%d%H%M')"
  #local backupFileName="${BOARD}/${BOARD}${now}.tar.gz"
  local backupFileName="${BOARD}/a.tar.gz"


  learn_arch

  make_local_kernelimage ${now}
  copy_local_kernelmodules ${now}
  tarFiles
}

main "$@"
