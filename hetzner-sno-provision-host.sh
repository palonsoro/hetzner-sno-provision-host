#!/bin/bash

# WARNING: This script assumes that
# - You have wiped the main hard drives as required
# - You are providing the right network configuration in the assisted installer (using nmstate file is recommended)

set -euo pipefail

IPXE_SCRIPT_URL="${1}"
curl -f -s -o discovery_ipxe_script.txt "${IPXE_SCRIPT_URL}"

echo 'This script is meant to be run in the rescue environment to provision the Hetzner node so it can be discovered by assisted installer'

# Set right defaults for kexec-tools and install it
echo kexec-tools kexec-tools/use_grub_config select false | debconf-set-selections
echo kexec-tools kexec-tools/load_kexec select true | debconf-set-selections

apt-get install -y kexec-tools

INITRD_URL="$(awk '/^initrd/{print $NF}' discovery_ipxe_script.txt)"
KERNEL_URL="$(awk '/^kernel/{print $2}' discovery_ipxe_script.txt)"
KERNEL_CMDLINE="$(grep '^kernel' discovery_ipxe_script.txt  | cut -d' ' -f 3-)"

curl -L -f -s -o kernel "${KERNEL_URL}"
curl -L -f -s -o initrd "${INITRD_URL}"

kexec kernel --initrd=initrd --append="${KERNEL_CMDLINE}"
