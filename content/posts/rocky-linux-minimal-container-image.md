---
title: "A Minimal Container Image for Rocky Linux 8"
author: Job Céspedes Ortiz
date: 2021-06-25T18:55:42-06:00
subtitle: "similar to UBI8, Fedora minimal"
image: ""
tags:
  - centos
  - rocky
  - kubernetes
  - containers
  - docker
  - podman
  - moodle-operator
  - krestomatio
---
Now that [Rocky Linux is GA](https://rockylinux.org/news/rocky-linux-8-4-ga-release/), here is a [repo](https://github.com/krestomatio/container_builder/tree/master/rocky8-minimal) for a [minimal container image for Rocky Linux](https://quay.io/krestomatio/rocky8-minimal/). Its size is around ~37 MB (compressed). It is based on [Fedora Minimal](https://registry.fedoraproject.org/repo/fedora-minimal/tags/) and [UBI8 minimal](https://catalog.redhat.com/software/containers/ubi8/ubi-minimal/5c359a62bed8bd75a2c3fba8) from Red Hat. You can [download it from Quay](https://quay.io/krestomatio/rocky8-minimal/) or build it, following the instructions in the [repo](https://github.com/krestomatio/container_builder/tree/master/rocky8-minimal). You could also generate a new rootfs yourself before building the image, again, following the short instructions in the [repo](https://github.com/krestomatio/container_builder/tree/master/rocky8-minimal).

At [Krestomatio](https://krestomatio.com/), we were in search of a Centos 8 minimal container image a couple months ago. Since it was not available, we did a test drive of [UBI8 minimal](https://catalog.redhat.com/software/containers/ubi8/ubi-minimal/5c359a62bed8bd75a2c3fba8). I believe it is a really good alternative as long as you understand its [End User License Agreement](https://www.redhat.com/licenses/EULA_Red_Hat_Universal_Base_Image_English_20190422.pdf) and [FAQ](https://developers.redhat.com/articles/ubi-faq). There was also [Fedora Minimal](https://registry.fedoraproject.org/repo/fedora-minimal/tags/). However, none seemed to fit perfectly in our use cases. So, we began building our own [Centos 8 minimal container image](https://github.com/krestomatio/container_builder/tree/master/centos8-minimal) based on [Fedora Minimal](https://registry.fedoraproject.org/repo/fedora-minimal/tags/) and [UBI8 minimal](https://catalog.redhat.com/software/containers/ubi8/ubi-minimal/5c359a62bed8bd75a2c3fba8). Then, Red Hat made [its announcement](https://blog.centos.org/2020/12/future-is-centos-stream/) about Centos Stream replacing Centos 8. We began planning for its replacement right away.

Immediately, and admirably, initiatives and communities were formed around the idea of a serious alternative. Two of them were [Alma Linux](https://almalinux.org/) and [Rocky Linux](https://rockylinux.org/). Even though Alma Linux did [its first stable release](https://almalinux.org/blog/almalinux-os-stable-release-is-live/) a couple weeks ago; we were waiting for a stable release of Rocky Linux. In the meantime, we started using [Centos Stream](https://www.centos.org/centos-stream/). A funny thing is we reached to the conclusion that the [Centos Stream project](https://www.centos.org/centos-stream/) and [its release cadence](https://www.redhat.com/es/blog/faq-centos-stream-updates) worked well for our container workloads. Still, we recognize the need of many for a Centos 8 alternative.

Therefore, we are building a [Rocky Linux minimal container image](https://quay.io/krestomatio/rocky8-minimal/). However, most of our workloads at [Krestomatio](https://krestomatio.com/) are using our own [Centos Stream minimal container image](https://quay.io/repository/krestomatio/centos8-stream-minimal). In case anyone has a use for any of those two, check out the [repo](https://github.com/krestomatio/container_builder). Cheers!
