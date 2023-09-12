# SNO provision from Hetzner rescue

**WARNING**: This is neither supported nor endorsed by Red Hat or Hetzner. It is experimental and not intended for production use. Use it under your own risk.

This is a simple script meant to be run from [Hetzner Rescue System](https://docs.hetzner.com/robot/dedicated-server/troubleshooting/hetzner-rescue-system/) to be able to install OpenShift from the [assisted installer](https://docs.openshift.com/container-platform/4.13/installing/installing_on_prem_assisted/installing-on-prem-assisted.html).

What the script does:
- Installs `kexec-tools` into the rescue system
- It downloads the indicated iPXE script, provided by assisted installer for the discovery phase (as an alternative to the discovery ISO)
- Then it downloads the kernel and the initrd from the URLs on the iPXE script.
- Last, it kexecs into the downloaded kernel and initrd with the kernel parameters provided by the iPXE script

**More warnings**:
- This script assumes that you have previously wiped the hard drives of the node.
- You must feed assisted installer with the right network configuration before generating the iPXE script. Using nmstate file is recommended.
- This worked in the server where I could test it. However, as kexec does not perform the hardware initialization in the very same way than a regular boot, it might not work as expected depending on the server hardware (or just on how lucky you are).

Usage
```
./hetzner-sno-provision-host.sh <iPXE script URL>
```
Where:
- `<iPXE script URL>` is the download URL for the iPXE script provided by assisted installer.
