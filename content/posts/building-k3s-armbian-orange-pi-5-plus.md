---
title: "Building a K3s Cluster with Armbian on Orange Pi 5 Plus"
author: Job Céspedes Ortiz
date: 2023-11-09T12:00:00-06:00
subtitle: "A Step-by-Step Guide"
image: "img/opi5-cluster-1.png"
tags:
  - armbian
  - k3s
  - kubernetes
  - orangepi5
  - ansible
  - john-1:4
---
In this blog post, I'll be sharing my practical journey of building a K3s Cluster on the Orange Pi 5 Plus (opi5+) using Armbian as the Operating System (OS) and Ansible. The post is meant as a straightforward guide for anyone looking to replicate the process. I hope it proves helpful for your own setup.

>Please consider that in some sections, there are references to external guides containing the respective steps.

## Why Armbian?
After [my failed attempt using Fedora CoreOS](/2023/11/building-a-k3s-cluster-with-fedora-coreos-on-orange-pi-5-plus), Armbian + K3s was one of the options I considered. Among the reasons behind selecting Armbian as the OS, there are:

- **Wide Hardware Support**: Armbian provides support for a wide range of ARM-based single-board computers (SBCs), giving you flexibility in choosing hardware for your K3s cluster.

- **Stability and Reliability**: Armbian is known for its stability and reliability, making it a suitable choice for building robust and resilient K3s clusters.

- **Optimized for ARM Architecture**: Armbian is optimized specifically for ARM architecture, ensuring efficient performance on ARM-based devices commonly used for SBCs.

- **Regular Updates**: Armbian releases regular updates and security patches, helping you keep your system up-to-date and secure.

- **Low Resource Footprint**: Armbian is designed to be resource-efficient, making it suitable for resource-constrained environments common in SBCs, which is ideal for setting up cost-effective K3s clusters.

- **Community Support**: Being an open-source project, Armbian has an active community that provides support, documentation, and troubleshooting assistance, which can be valuable when setting up and maintaining a K3s cluster.

## Warning
There are a couple of things you should be aware of:
- This is a laboratory environment.
- Some steps involve commands that will erase data.

## Assumptions
The following assumptions have been made:

- Device is Orange Pi 5+ version.
- There is another laptop/PC for preparations.

## Preparations
###  Items
The items used for this task are:
- 1x SD Card with at least 4GB
- 3x [Orange Pi5 Plus 16G + 256G EMMC Module with US 5V4A Type C Power](https://www.aliexpress.com/item/1005005775077219.html)
- 3x [Geekworm Orange Pi 5 Plus Cluster Acrylic Case with Fan and Heatsink Kit](https://www.aliexpress.com/item/1005005626040665.html). Please note:
  - The included heatsink may not fit perfectly and might require some force to install.
  - One of the screws on the fan may touch a clip on the heatsink and lift the top cover on one side. To address this, you can remove that specific fan screw, leaving only 3 of the 4, to prevent any unevenness in the top stack.
  - There is no step-by-step manual or video guide available.
- 1x [HORACO 8 Port 2.5G Ethernet Switch](https://aliexpress.com/item/1005005118650350.html)

#### Other items
For upgrading and connecting to a Linux storage server, utilizing the aforementioned switch, the following items were acquired:
- 1x [25G SFP28 SFP+ DAC Cable - 25GBASE-CR SFP28 to SFP28 Passive Direct Attach Copper](https://www.aliexpress.com/item/1005002276380808.html).
- 1x ConnectX-4 Lx EN CX4121A-ACAT 2-Port 10/25GbE SFP28 PCI-E

## Install Armbian
To install Armbian, follow [Armbian Quickstart](https://docs.armbian.com/User-Guide_Getting-Started/). The steps include:
1. Downloading Armbian image for opi5+
2. Installing Armbian image in the SD Card
3. Booting from SD card, do basic config, and install image in opi5+ eMMC with: `armbian-install`
4. Powering off
5. Removing SD card
6. Booting into eMMC and Armbian

### Other Basic Config
> Remove the SD card

Boot into eMMC and configure basic settings before proceeding further. Access using SSH keys without asking for a password is required for [installing K3s using ansible](#install-k3s). The other steps are optional:

1. Get root access
2. Change root password
3. Change user password
4. Upgrade OS and packages
5. Allow sudo without password
6. Allow auth using SSH keys
7. Customize /etc/hosts
8. Create network teaming/bonding

Below are the commands to perform the steps listed above. Change variable values according to your context. Replicate them in each of the other devices. Remember you need root access:
```bash
## as root.
# sudo bash

## change passwords
# passwd root
# passwd ${opi_hostname}

## upgrade pkgs
apt update
DEBIAN_FRONTEND=noninteractive apt upgrade -y

## vars /CHANGE_THEM
opi_username=changeme
opi_hostname=changeme-01
opi_domain=change.me
opi_fqdn=${opi_hostname}.${opi_domain}
opi_cidr=192.168.1.10/24
opi_gw=192.168.1.1
opi_dns='8.8.8.8 8.8.4.4'
opi_ssh_authorized_key='ssh-rsa CHANGEME'

## sudo
cat << _EOF > /etc/sudoers.d/10-opi5-user
# User rules for ${opi_username}
${opi_username} ALL=(ALL) NOPASSWD:ALL
_EOF

## ssh
mkdir -p /home/${opi_username}/.ssh
cat << _EOF > /home/${opi_username}/.ssh/authorized_keys
ssh-rsa ${opi_ssh_authorized_key}
_EOF
chmod 0700 -R /home/${opi_username}/.ssh
chown ${opi_username}:${opi_username} -R /home/${opi_username}/.ssh
sed -i "s@#PasswordAuthentication.*@PasswordAuthentication no@" /etc/ssh/sshd_config
systemctl restart ssh

## /etc/hosts
cat << _EOF > /etc/hosts
127.0.0.1   localhost
127.0.1.1   ${opi_fqdn} ${opi_hostname}
::1         localhost ip6-localhost ip6-loopback ${opi_fqdn} ${opi_hostname}
fe00::0     ip6-localnet
ff00::0     ip6-mcastprefix
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
_EOF

## hostname
hostnamectl set-hostname ${opi_hostname}

## lock root password
passwd -l root

## network bonding
# workaround: https://github.com/coreos/fedora-coreos-tracker/issues/919
cat << _EOF > /etc/systemd/network/98-bond-inherit-mac.link
[Match]
Type=bond

[Link]
MACAddressPolicy=none
_EOF

# add bond interface
# this could cause disconection
nmcli connection add type bond con-name bond0 ifname bond0 bond.options "mode=balance-alb,miimon=1000" mtu 9000 ipv4.addresses "${opi_cidr}" ipv4.gateway "${opi_gw}" ipv4.dns "${opi_dns}" ipv4.dns-search "${opi_domain}" ipv4.method manual bond.options "mode=balance-alb,miimon=1000" mtu 9000
# add current devices
nmcli connection add type ethernet slave-type bond con-name bond0-port1 ifname enP3p49s0 master bond0 mtu 9000
nmcli connection add type ethernet slave-type bond con-name bond0-port2 ifname enP4p65s0 master bond0 mtu 9000
# delete old connections
nmcli connection delete "Wired connection 1"
nmcli connection delete "Wired connection 2"
```

## Install K3s
Now you are ready to install K3s, using Ansible and [a K3s role](https://github.com/PyratLabs/ansible-role-k3s). Perform the following steps on a system other than your Opi5+ devices:

1. Install [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) and the [K3s role](https://github.com/PyratLabs/ansible-role-k3s).
    - For [installing Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html), you could run `pip install ansible`
    - For installing the [K3s role](https://github.com/PyratLabs/ansible-role-k3s), you could run `ansible-galaxy role install xanmanning.k3s`
2. Install a Highly Available (HA) K3s Cluster with embedded etcd, following [these steps](https://github.com/PyratLabs/ansible-role-k3s/blob/main/documentation/quickstart-ha-cluster.md). They include:
    - Creating an inventory with your opi5+ devices
    - Creating a playbook, using that inventory and [the K3s role](https://github.com/PyratLabs/ansible-role-k3s)
    - Running the playbook

## Enjoy!
To wrap it up, building the K3s Cluster on the Orange Pi 5 Plus was a hands-on experience. Now I will use it to develop and test [Moodle™ instances managed by Krestomatio](https://krestomatio.com/) [operators for Kubernetes](https://github.com/krestomatio/). I hope this guide makes it easy for you to do the same. Good luck with your K3s Cluster setup on the Orange Pi 5 Plus, and I hope you too have fun!
