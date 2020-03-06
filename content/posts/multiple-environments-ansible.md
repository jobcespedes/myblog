---
title: "Multiple Environments in Ansible"
author: Job Céspedes Ortiz
date: 2020-02-27T14:14:42-06:00
subtitle: "with little file and data duplication"
image: ""
tags:
  - containers
  - podman
  - unionfs
  - docker
  - bind-propagation
  - user namespaces
draft: true
---
Many systems are deployed in a multienvironment context, for example: production, stage, and dev.  These environments often share variables and artifacts. In Ansible, there are different methods to work in this context. For example, [separate directory layout](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html#alternative-directory-layout) and [soft links](https://www.digitalocean.com/community/tutorials/how-to-manage-multistage-environments-with-ansible). However, it can end with a considerable amount of data and duplicate files between environments, exposing variables to all hosts or adding much more complexity to playbooks.

[Demo multienv](https://github.com/jobcespedes/demo-multienv) tests a stackable multienvironment directory layout for Ansible, using [multienv Ansible role](https://github.com/jobcespedes/multienv). The main goal is to have little file and data duplication in a multienvironment Ansible project while maintaining Ansible groups and host granularity. The environments are separated. However, they are based over the others in a hierarchical way. So each one only has the necessary files and artifacts.

The approach to achieve this is to use [unionfs](http://unionfs.filesystems.org/) and a container (_docker_ by default) for stacking the environments. There are other two alternative modes to run it: 2) _podman_ or 3) _binary_ `unionfs` install on the host. A variable is used for changing to the preferred method.

---
## Approach
A [separate directory layout](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html#alternative-directory-layout) is used as recommended by Ansible Best Practices. There could be: a. **base** environment: for the most common and shared variables and artifacts; b. **dev** environment; c. **stage** environment; and d. **production**. Then, two or more of them could be unified as one using [unionfs](http://unionfs.filesystems.org/). That directory is used as the current Ansible environment (inventory, vars, artifacts, etc). This way, one can modify each environment in its respective directory. And instruct Ansible to use the unified directory as its inventory parameter.

---
## Example #1 - simple stacked environment
In the following example there is one environment for the most common variables and artifacts among environments. This is the **base** environment. Then, any other environment could be stacked over it by setting `multienv_union`. For example:

**Dev**
```yaml
multienv_union:
  - base
  - dev
```
**Production**
```yaml
multienv_union:
  - base
  - production
```
In the latter example, there are two separate directories: `environment/base`, and `environment/production`. The unified directory in that case would be `union_environment/production`, as a stacked environment: _base+production_

---
## Example #2 - multiple stacked environments
More than two environments can be stacked. `multienv_union` could be set with _base+dev+stage_. In that case, **base** is mounted, then **dev**, and over it **stage**:
**Stage**
```yaml
multienv_union:
  - base
  - dev
  - stage
```
---
## Other options considered
* **Ansible plugins**: the logic could be added using Ansible plugins. It has to handled inventory, vars and other artifacts (files, templates, among others). [Unionfs](http://unionfs.filesystems.org/) approach could handled those without addional plugins
* **Overlayfs**: It is another union filesystem included in the current linux kernel. However, I couldn't get it working for some type of modifications of the lower and upper layers using fuse-overlayfs. For example, while mounted, a file created in the base environment (lower) does not appear in the union directory. A file that exists in both environment and is deleted, breaks its path in the union folder. An operation like remount is needed to reflect those changes in the union mount because _modifying the underlying directories is undefined._
* **Rsync and Inotify**. Using inotify to monitor modifications and rsync to sync into one environment. One consideration about this is how to handle deleted files in the destination. They are replace again every time the command runs.

## Issues
- Centos: if using Centos and getting a message like **'is mounted on / but it is not a shared mount'**, you may need to make ```multienv_host_mountpoint``` a shared mount point with ```mount --make-rshared <multienv_host_mountpoint>```. Replace ```<multienv_host_mountpoint>``` with the respective value
