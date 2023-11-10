---
title: "Building a K3s Cluster with Fedora CoreOS on Orange Pi 5 Plus"
author: Job Céspedes Ortiz
date: 2023-11-09T11:00:00-06:00
subtitle: "Lessons from My Unsuccessful Attempt"
image: ""
tags:
  - fedora
  - coreos
  - k3s
  - kubernetes
  - orangepi5
  - john-17:21
---
This blog post summarizes my unsuccessful attempt to build a K3s Cluster on the Orange Pi 5 Plus (opi5+) using Fedora CoreOS (FCOS). It also outlines the steps taken before arriving at that conclusion and presents a list of possible alternatives to achieve a similar result.

## Why Fedora CoreOS?
The main reasons behind selecting FCOS as the Operating System (OS) were:

- **Automatic Updates**: Fedora CoreOS follows an automated update model, and reboots can also be orchestrated using Zincati.

- **Immutable OS**: The operating system is designed to be immutable, meaning that changes are made by replacing the entire OS image rather than modifying the existing system. This helps improve stability and reproducibility.

- **Container-Optimized**: It is optimized for running containers and container orchestration platforms like Kubernetes. This makes it well-suited for modern cloud-native applications.

- **RPM-OSTree**: Fedora CoreOS uses RPM-OSTree, which allows for atomic updates and rollbacks, making it easier to maintain system consistency and recover from issues.

- **Security**: Frequent updates and immutability contribute to a more secure system. Security patches are quickly applied to minimize vulnerabilities.

- **Community, Ecosystem, and Open Source**: Being part of the Fedora Project and Open Source, Fedora CoreOS benefits from a vibrant community and a rich ecosystem of tools and applications.

- **Don't start from scratch**: As part of [Krestomatio tools for automating infrastructure](https://krestomatio.com/), a [terraform module](https://registry.terraform.io/modules/krestomatio/butane-snippets/ct/latest/submodules/k3s) was developed to help the deployment of a K3s Cluster using FCOS. The module outputs ignitions (ign) files required, just by setting some variables.

## Warning
There are a couple of things you should be aware of:
- This is a laboratory environment.
- Ensure that you use the correct official image and URL for your device version. For instance, the opi5+ version differs from the opi5 version.
- Some steps involve commands that will erase data.

## Assumptions
The following assumptions have been made:

- Device is Orange Pi 5+ version.
- Availability of another Fedora-based laptop for preparations.
- The SD Card in the laptop/PC is mounted in `/dev/sda`.

## Preparations
###  Items
The items used for this task are:
- 1x SD Card with at least 4GB
- 1x USB Drive with at least 4GB
- 1x Orange Pi5 Plus 16G + 256G EMMC

### SD Card
For the SD card:
- Check SD card requirements in [opi5+ manual](http://www.orangepi.org/)
- Install OS image, following the [opi5 official docs for burning it to the SD](http://www.orangepi.org/).

### USB Drive
In the USB drive;
- Copy [EDK2 latest release](https://github.com/edk2-porting/edk2-rk3588/releases), naming it `edk2-firmware.img`
- Copy [FCOS image](#fcos-image), generate in the step below, naming it `fcos.img`

### FCOS image
To prepare the FCOS image:
1. Create an ignition file and store it in `/tmp/config.ign`
2. Create FCOS image

```bash
# Create FCOS image
STREAM=next # CHANGEME: `stable` or `testing` or `next`
FCOS_IMG=fcos.img
IGN_FILE=/tmp/config.ign # CHANGEME
CONTAINER_BUILDER=podman # CHANGEME: `podman` or `docker`
sudo losetup -D
rm -f "${PWD}/${FCOS_IMG}"
truncate -s 3GB "${PWD}/${FCOS_IMG}"
sudo losetup -f -P "${PWD}/${FCOS_IMG}"
sudo $CONTAINER_BUILDER run --pull=always --privileged --rm \
    -v /dev:/dev -v /run/udev:/run/udev -v $IGN_FILE:$IGN_FILE \
    quay.io/coreos/coreos-installer:release \
    install --firstboot-args=console=tty0 \
    -p "metal" -a aarch64 -s $STREAM -i $IGN_FILE /dev/loop0
sudo sync
sudo losetup -D
```

## First Boot
Once preparations are done, continue:
1. Insert and boot from SD Card
2. Insert USB drive and mount it to `/mnt`
3. Copy [EDK2 to SPI, following steps below](#edk2-to-spi)
4. Copy [FCOS image to eMMC, following steps below](#fcos-image-to-emmc)
5. Power off
6. Remove SD Card
7. Boot from eMMC

### EDK2 to SPI
To install EDK2 to SPI:
1. Erase SPI
2. Copy EDK2 to SPI
```
# erase SPI
sudo dd if=/dev/zero of=/dev/mtdblock0
sudo sync
# copy EDK2 to SPI
sudo dd if=edk2-firmware.img of=/dev/mtdblock0
sudo sync
```

### FCOS image to eMMC
1. Identify eMMC device
2. Erase eMMC device
3. Copy FCOS image to eMMC
```
# identify emmc device. Ex: /dev/mmcblk1
ls /dev/mmcblk*boot0 | cut -c1-12
# erase
sudo dd bs=1M if=/dev/zero of=/dev/mmcblk1 count=1000 status=progress
sudo sync
# copy
sudo dd bs=1M if=fcos.img of=/dev/mmcblk1 count=1000 status=progress
sudo sync
```
## Result
>Remember to power off and remove the SD card. Then test booting from FCOS image in eMMC on the opi5+.

The generic FCOS image does not work out of the box. It throws the error `Timed out wating for device` for boot and root devices and then enters emergency mode. Attempts to run using F39 and F40 were made, with the same result though.

## Alternatives
After this result, there are three alternatives I am considering to build a K3s Cluster using opi5+ devices. Those are:
1. Use official or third party images + K3s
2. Use [Ubuntu + Libvirt](https://github.com/Joshua-Riek/ubuntu-rockchip#installation) + Fedora CoreOS VM + K3s
3. Build a custom Fedora CoreOS, with [Orange Pi linux Kernel](https://github.com/orangepi-xunlong/linux-orangepi) + K3s
