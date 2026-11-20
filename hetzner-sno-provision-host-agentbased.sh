#!/bin/bash

# WARNING: This script assumes that
# - You have wiped the main hard drives as required
# - You are providing the right network configuration in the AgentConfig settings
# - You have already created the PXE files for assisted installer and placed them in `/root` folder of the rescue environment.

set -euo pipefail


build_combined_initrd() {
  local initrd_path rootfs_path combined_initrd tmp_initrd
  local initrd_size rootfs_size padding_bytes required_kb available_kb

  initrd_path="/root/agent.x86_64-initrd.img"
  rootfs_path="/root/agent.x86_64-rootfs.img"
  combined_initrd="/root/agent.x86_64-combinedinitrd.img"
  tmp_initrd="${combined_initrd}.tmp"
  initrd_size="$(wc -c < "$initrd_path")"
  rootfs_size="$(wc -c < "$rootfs_path")"
  padding_bytes=$(( 4 + ((4 - (initrd_size % 4)) % 4) ))

  if command -v df >/dev/null 2>&1 && command -v awk >/dev/null 2>&1; then
    required_kb=$(( (initrd_size + rootfs_size + padding_bytes + 1023) / 1024 ))
    available_kb="$(df -kP /root | awk 'END {print $4}')"
    if [[ "$available_kb" =~ ^[0-9]+$ ]] && [[ "$available_kb" -lt "$required_kb" ]]; then
      die "Insufficient disk space to combine initrd and rootfs. Need ~${required_kb}KB, have ${available_kb}KB in ${ARTIFACT_DIR}."
      return 1
    fi
  fi

  rm -f "$tmp_initrd"
  cat "$initrd_path" > "$tmp_initrd"
  dd if=/dev/zero bs=1 count="$padding_bytes" status=none >> "$tmp_initrd"
  cat "$rootfs_path" >> "$tmp_initrd"
  mv -f "$tmp_initrd" "$combined_initrd"
  printf '%s\n' "$combined_initrd"
}

KERNEL_CMDLINE="rw  ignition.firstboot ignition.platform.id=metal"

echo 'This script is meant to be run in the rescue environment to provision the Hetzner node, where the PXE files from agent-based installation should have been copied already.'

# Set right defaults for kexec-tools and install it
echo kexec-tools kexec-tools/use_grub_config select false | debconf-set-selections
echo kexec-tools kexec-tools/load_kexec select true | debconf-set-selections

apt-get update -y || true # This sometimes fails due to auxiliary repos. Still worth trying.
apt-get install -y kexec-tools

build_combined_initrd

kexec /root/agent.x86_64-vmlinuz --initrd=/root/agent.x86_64-combinedinitrd.img --command-line="${KERNEL_CMDLINE}"
