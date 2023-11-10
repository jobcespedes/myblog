---
title: "Running Virtual Machines on Orange Pi 5"
author: Job Céspedes Ortiz
date: 2023-11-09T09:00:00-06:00
subtitle: "with Libvirt and Ubuntu"
image: ""
tags:
  - ubuntu
  - libvirt
  - orangepi5
  - virtualization
  - matthew-11:27
---
In this guide, we'll walk through the steps to install libvirt on the Single Board Computer (SBC) Orange Pi 5 (opi5) for running virtual machines (VMs). I've compiled these steps after dealing with the opi5 instructions, searching on the internet and communities, and my own experience. I hope this guide helps someone accomplish this task more quickly than I did initially.

## Installing Orange Pi 5
The first step is to install an Operating System (OS) on the opi5. You have several options here: you can use official images, third-party images, or build your own. In this case, I used a third-party image, [Ubuntu](https://github.com/Joshua-Riek/ubuntu-rockchip). Additionally, I used a PCIe NVMe SSD for storage. Here are the installation steps:

1. [Install Ubuntu](https://github.com/Joshua-Riek/ubuntu-rockchip#installation) on the NVMe, following the [opi5 official docs for burning it to the SSD](http://www.orangepi.org/).
2. Apply basic configurations, including:
    - Network
    - Locale
    - Keyboard
3. Perform a package update/upgrade.

## Installing Libvirt
To install libvirt, you will need to install some other related packages and add a user to the libvirt group. You may also consider applying a workaround for running UEFI VMs. Afterward, you can easily test with a Cirros VM. Follow these steps to accomplish this.
```bash
## `--no-install-recommends` for avoiding recommended pkgs in a server
## alternative or additional pkgs
## `qemu-system`  for all qemu architecture or
## `qemu-efi-arm` for arm 32bits efi
## `u-boot-qemu` if planning to use uboot
# install pkgs in ubuntu 22.04
sudo apt install --no-install-recommends libvirt-daemon \
  libvirt-daemon-system libvirt-clients qemu-kvm qemu-system-arm \
  qemu-utils qemu-efi-aarch64 qemu-efi-arm arm-trusted-firmware \
  seabios bridge-utils virtinst dnsmasq-base ipxe-qemu

# add user to libvirt group
sudo adduser $USER libvirt
newgrp libvirt
export LIBVIRT_DEFAULT_URI=qemu:///system

# workaround
# set `60-edk2-aarch64.json` as the default uefi configuration
# using a symlink to place the descritor file first
# https://bugzilla.redhat.com/show_bug.cgi?id=1564270
sudo ln -s  /usr/share/qemu/firmware/60-edk2-aarch64.json \
  /usr/share/qemu/firmware/00-edk2-aarch64.json

# test cirros VM
## download cirros image
sudo wget http://download.cirros-cloud.net/0.5.2/cirros-0.5.2-aarch64-disk.img \
  -P /var/lib/libvirt/images
## create root qcow2 from image
sudo qemu-img create -b /var/lib/libvirt/images/cirros-0.5.2-aarch64-disk.img \
  -F qcow2 -f qcow2 /var/lib/libvirt/images/test.qcow2
## autostart default net
virsh net-autostart --network default
virsh net-start default
## install test VM in ubuntu host
virt-install -n test --memory 1024 --arch aarch64 --vcpus 1 \
  --disk /var/lib/libvirt/images/test.qcow2,device=disk,bus=virtio \
  --os-variant=cirros0.5.2 \
  --nographic \
  --boot loader=/usr/share/AAVMF/AAVMF_CODE.fd,loader.readonly=yes,loader.type=pflash
```

## On Debian?
I attempted to install libvirt on a Debian image on the opi5, but I was not successful. I subsequently switched to Ubuntu. Here are the steps that I used to install libvirt on Debian, in case anyone wants to explore that route.
```bash
sudo apt install --no-install-recommends qemu-system-arm libvirt-clients \
  libvirt-daemon-system bridge-utils virtinst libvirt-daemon qemu-utils \
  qemu-efi-aarch64
```

## Have Fun
Originally, my goal with a Single Board Computer (SBC) was to unwind and take a break from the usual work routine. I opted for an opi5 in the way. However, lo and behold, here I am, enabling virtualization, almost like it's a rarity in my line of work over at [Krestomatio](https://krestomatio.com/)! It's been a fun experience, nonetheless.
