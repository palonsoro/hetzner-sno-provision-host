#!/bin/bash

# WARNING: This script assumes that
# - You have wiped the main hard drives as required
# - You are providing the right network configuration in the AgentConfig settings
# - You have already created the PXE files for assisted installer and placed them in `/root` folder of the rescue environment.

set -euo pipefail

KERNEL_CMDLINE="rw  ignition.firstboot ignition.platform.id=metal"

echo 'This script is meant to be run in the rescue environment to provision the Hetzner node, where the PXE files from agent-based installation should have been copied already.'

# Set right defaults for kexec-tools and install it
echo kexec-tools kexec-tools/use_grub_config select false | debconf-set-selections
echo kexec-tools kexec-tools/load_kexec select true | debconf-set-selections

apt-get update -y || true # This sometimes fails due to auxiliary repos. Still worth trying.
apt-get install -y kexec-tools

# Combine initrd images because kexec only allows a single one. Yes, with `cat` it just works.
cat /root/agent.x86_64-initrd.img /root/agent.x86_64-rootfs.img > /root/agent.x86_64-combinedinitrd.img 

kexec /root/agent.x86_64-vmlinuz --initrd=/root/agent.x86_64-combinedinitrd.img --command-line="${KERNEL_CMDLINE}"
