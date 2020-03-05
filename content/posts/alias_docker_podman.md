---
title: "alias docker=podman"
slug: "alias-docker-podman"
date: 2020-03-02T10:48:50-06:00
description: "replacing docker with podman when trying to mount a unionfs inside a container"
keywords:
  - containers
  - podman
  - unionfs
  - docker
  - bind-propagation
  - user namespaces
authors:
  - Job Céspedes Ortiz
# categories: []
# series: []
tags:
  - containers
  - podman
  - unionfs
  - docker
  - bind-propagation
  - user namespaces
# images: []
# videos: []
# audio: []
draft: true
---
I have heard about Podman more and more often now. Whether it is that I have come closer to its developing environment or that it has come to mine, I'm not sure. It's both, I guess. I use Ansible a lot for automating baremetal and virtual infrastructure: for its definition, deployment, configuration, operation, among other things. In the recent years, I have being using more and more containers, particularly in the developing stages. And I really like open source, most of its concepts, and many initiatives around it. So, I have being wondering if I should be using mainly podman for containers already. There is, however, this one recurrent question in my head:

> How much work will adapting those docker projects take?

## Why that unionfs container?
I use Ansible a lot for automating infrastructure. It works well for having multiple stages/environments over that infrastructure. However, managing those multiple stage/environment directories sometimes become kind of messy. [Demo-multienv](https://github.com/jobcespedes/demo-multienv) looks for a way to avoid it. It uses unionfs inside a container to stack  directories/files, reducing data and file duplication among them. You only need docker and its python library installed and Ansible will do it for you. But, Could it be run with podman instead?

It was just docker. I wanted to add compatibility with podman also. I was hoping it would be little extra work, something very simple, just like `alias docker=podman` for cli. But it required more than that.

## Ansible and podman
Docker has `docker_container` and I was kind of hoping to just change it to `podman_container` and _mission accomplished_. But I found that there is no such module included with Ansible, yet. There is [WIP](https://github.com/ansible/ansible/issues/46362) for one, though. And, there is available a [Tripleo module](https://github.com/openstack/tripleo-ansible/blob/master/tripleo_ansible/ansible_plugins/modules/podman_container.py). That is the one I tried. It has some different parameter names but its usage is similar overall. It worked perfect in this particular case. The playbook ran successfully.

## The unexpected
Then, it came something unexpected. Files supposed to be exposed from the container to the host, were not there and neither was the mount point. The container successfully started. However, there were no files in the respective host's directory. In the host, it is a simple directory, shared with the container as a volume. In the container, it is the mount point for the _unionfs_. In the host, it was empty. In the container, the mount point and files were there. And, in docker it worked  :stuck_out_tongue_closed_eyes:.

By this point, I was running podman manually (not using Ansible and [demo-multienv](https://github.com/jobcespedes/demo-multienv)). Debug option for Ansible and [Tripleo module](https://github.com/openstack/tripleo-ansible/blob/master/tripleo_ansible/ansible_plugins/modules/podman_container.py) help me here. It shows the podman command being used. I copy pasted it and added a debug level, using: `podman --log-level=debug run`. There were no errors. It just had a warning:
```
WARN[0000] Failed to add conmon to cgroupfs sandbox cgroup: error creating cgroup for cpu: mkdir /sys/fs/cgroup/cpu/libpod_parent: permission denied
```
However, I could not related it with my problem. `podman logs` did not show anything wrong. I was clueless, honestly.

## Community to the rescue
I turned to the community, opening [#5322](https://github.com/containers/libpod/issues/5322) (after checking previous related issues/discussions of course :smile:). That was how I got to the cause of the problem and learned about other important concept around podman. One particular answer sums it up:
> "this is not a bug. Rootless containers cannot create mounts in the host.
>
> The shared mount is created inside of the rootless mount namespace, you can reach it with podman unshare" -- <cite>@giuseppe. From [Github](https://github.com/containers/libpod/issues/5322#issuecomment-591055081)</cite>

Everywhere in podman documentation says it is able to run rootless. And still, I forget that aspect :sweat_smile:. It did not work because:
- **It should be run as root for it to work**

However, podman still allows one rootless option. It is related to [_user namespaces_](https://opensource.com/article/18/12/podman-and-user-namespaces) and [_podman unshare_](https://github.com/containers/libpod/blob/master/docs/source/markdown/podman-unshare.1.md).
- **If rootless, it could be accessed using `podman unshare`**

For example:
```bash
# rootless
## prepare dir layout
parent=${HOME}/multienv
dir1=${parent}/dir1
dir2=${parent}/dir2
unionfs=${parent}/multienv/unionfs
mkdir -p $dir1 && echo "dir1_var1" > ${dir1}/var
mkdir -p $dir2 && echo "dir2_var1" > ${dir2}/var
mkdir -p $unionfs
cd $parent

# bind-propagation of unionfs dir inside 'podman unshare' environment
podman unshare mount --bind --make-shared ${unionfs} ${unionfs}

# run container
podman run --name multienv_unionfs --privileged=true --rm=true --env TZ=America/Costa_Rica --env PGID=1000 --env PUID=1000 --env UNION_DIRS=/dir2=RW:/dir1=RO --env MOUNT_PATH=/unionfs/ --env COW=true --volume ${dir2}:/dir2 --volume ${dir1}:/dir1 --volume ${unionfs}:/unionfs:shared --detach=true jobcespedes/multienv

# check that files are there inside 'podman unshare' environment
podman unshare ls -al ${unionfs}
# check that mount point is there inside 'podman unshare' environment
podman unshare mount | grep ${unionfs}
```

## More than `alias docker=podman`
In retrospective, replacing docker with podman may require more than `alias docker=podman`. It required me to:
1. read the documentation
2. take advantage of the community
3. start to really grasp concepts like _rootless_ and _user namespace_
4. have fun learning new things

To be fair, in many cases, the alias could be all you need. But in this particular case, those things help replace docker with podman and extend [demo-multienv](https://github.com/jobcespedes/demo-multienv). Now I could run it in either on of three modes :smile::
1. docker (docker group)
2. podman (root)
3. `unionfs` binary, in the host (no root)
