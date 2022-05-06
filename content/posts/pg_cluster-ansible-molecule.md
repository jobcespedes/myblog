---
title: "Simple Testing of Complex Scenarios"
author: Job Céspedes Ortiz
date: 2020-05-21T18:14:42-06:00
subtitle: "using Ansible and Molecule"
image: ""
tags:
  - database
  - postgres
  - pgpool2
  - molecule
  - ansible
  - containers
  - docker
  - IaC
---
**Is there something easy when deploying and configuring the database layer?**

Aspects of Data integrity and reliable/safe operations add up to complexity, which only increases when tradicional SQL, high availability, fault tolerance, scalability and high levels of concurrency, are required. It is a sensitive layer, no doubt. Consequently, if there is something easy there, it would be to screw everything up.

Do not fear, go test, screw up and learn. I mean, just not in production. How? By leveraging Infra automation and testing using [Ansible](https://docs.ansible.com/), [Molecule](https://molecule.readthedocs.io/en/latest/) and containers. They will allow you to quickly create a disposable local environment in which you can deploy your automated configuration and do all the testing you need as well as verification.

If this is of interest to you, keep reading for an actual example you could try in your machine. It is a Postgres cluster to be configured by Ansible. You can deploy it to local containers using Molecule, a framework for developing and testing Ansible roles. You just need to be acquainted with Ansible [inventories](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html), [roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html) and [playbooks](https://docs.ansible.com/ansible/latest/user_guide/playbooks_intro.html).

This reading will be structured as follows: a) Ansible role for the cluster; b) prerequisites to run it; c) screwing things up; d) testing and verifying;

---
## Ansible role
Ok. Back to the example, [pg_cluster](https://github.com/jobcespedes/pg_cluster) is an Ansible role to install, configure and bootstrap a Postgres cluster. You can install it, run it and test it, in a local environment using Molecule, checking that some prerequisites are installed first.

Let me just mention real quick what Postgres and Pgpool2 are, in case they need some introduction :stuck_out_tongue_winking_eye:. [Postgres](https://www.postgresql.org/) is a object-relational database system, considered one of the best. [Pgpool2](https://www.pgpool.net/mediawiki/index.php/Main_Page) is a middleware in front of Postgres for connection pooling, load balancing and watchdog. It can handle backend failover, failback and recovery. Both are open source.

This role installs a cluster with 3 nodes -bear with me, here comes a textual description-. Each node runs Pgpool2 and Postgres. Pgpool2 and Postgres have two roles each. For Postgres, those roles are: primary and standby. For Pgpool2, those roles are: active and standby. Pgpool and Postgres roles are independent. However, the first node starts with both, active (pgpool2) and primary(postgres). It has a Floating IP. The rest of nodes have standby role (pgpool and postgres).

The following diagram is a graphical and probably better description of the last paragraph:
```Plaintext
                  FLOATING IP
                 +-----------+     WATCHDOG
        +--------|  PGPOOL2  |--------+
        |        ------------- nic0   |
        |        |           |        |
        |        | POSTGRES  |        |
        |        | master    |        |
        |        +-----------+        |
        |          nic1|              |
  +-----------+        |        +-----------+
  |  PGPOOL2  |        |        |  PGPOOL2  |
  |-----------|        |        -------------
  |           |        |        |           |
  | POSTGRES  |        |        | POSTGRES  |
  | standby   |-----------------| stanby    |
  +-----------+   REPLICATION   +-----------+
```
> DISCLAIMER: pg_cluster has been used only in testing so far

---
## Prerequisites
In order to test this role, make sure the following prerequisites are met. [Docker should be installed](https://docs.docker.com/engine/install/#server). You also need [pip](https://pip.pypa.io/en/stable/installing/) to install Molecule and some other required python packages. For example, to install the prerequisites in Fedora you can do:
```bash
## Docker
sudo dnf install -y docker
## Pip
sudo dnf install -y python3-pip
## Ansible and role requirements
pip install --user "ansible>=2.8" netaddr
## Molecule and its requirements
pip install --user "molecule>=3" docker ansible-lint yamllint flake8
```
Once they are installed, download [pg_cluster](https://github.com/jobcespedes/pg_cluster) and you are ready to go:
```bash
git clone https://github.com/jobcespedes/pg_cluster
cd pg_cluster
working_dir=$(pwd)
```
> $working_dir will be our working directory

With `$working_dir` as your current path, _molecule_ would be one of its directories. Inside _molecule_ dir you will find the _default_ test scenario. There you can find molecule configuration, playbooks for each [sequence](##Test-and-verify) and the scenario's inventory.
```bash
├── defaults
├── handlers
├── meta
├── molecule
│   └── default
│       ├── converge.yml
│       ├── group_vars
│       │   └── all.yml
│       ├── hosts
│       ├── molecule.yml
│       ├── prepare.yml
│       ├── side_effect.yml
│       └── verify.yml
├── tasks
├── templates
└── test
```
If you want to modify the inventory and its variables, you can edit the 'hosts' file, add 'group_vars' files or add a 'host_vars' dir and put some files in it. For example:
```
├── molecule
│   └── default
│       ├── host_vars
│       │   └── pg-master.yml
│       ├── group_vars
│       │   └── all.yml
│       ├── hosts
```

---
## Screwing things up
With prerequisites met, you are ready to configure the cluster using containers. To create the local environment, run (be patient, it might take some time  :smile:):
```
molecule converge
```
That´s it. Molecule configured the cluster in your machine. The subcommand _converge_ creates and prepares the default test scenario and leaves it up, running. So, you are able to modify it afterwards. The command `molecule destroy` removes it, in case you have no need for it anymore.

While it is running, you can modify the Ansible role, molecule playbooks, molecule inventory, list cluster containers and log in to any of them, among other things:
```bash
# list cluster containers
molecule list

# log in to master node
molecule login -h pg-master
```
I will not try to tell you what to do here. You can do anything you want. But you might be interested in trying to remove one postgres backend and do an online recovery for it. You will need to log in to a container and run some commands there. First, run `molecule login -h pg-master` and then, inside the container:
```
# 1. Dettachment
## check nodes status and notice 'status' column of all nodes: 'up'
psql -h localhost -U postgres -c "show pool_nodes;"

## dettach first standby node with pcp command
pcp_detach_node -h localhost  -w -p 9898 -U postgres 1

# 2. Recovery
## check nodes status and notice 'status' column of node 1: 'down'
psql -h localhost -U postgres -c "show pool_nodes;"

## online recovery of node 1
pcp_recovery_node -h localhost  -w -p 9898 -U postgres 1

# 3. Check recovery
## check nodes status and notice 'status' column of all nodes: 'up'
psql -h localhost -U postgres -c "show pool_nodes;"
```

---
## Test and verify
Molecule has several test sequences. Creating the scenario and preparing it are two of them.  In addition, Molecule gives you the option to run a specific one, a set of them or a full test with all sequences.

Two sequences inside [pg_cluster](https://github.com/jobcespedes/pg_cluster) are side_effect and verify. Side_effect sequence has some tasks related to what we already try: failover and online recovery. Verify sequence has some assertions about the cluster: checking all backends are up, checking pcp commands, number of nodes, roles, among others. Check each respective playbook for the details of what is being tested and verified.

To verify after converge, run `molecule verify`. After you are done testing, remember to run `molecule destroy`.

---
## Conclusion
Ansible and Molecule help you test and verify an automated deployment. It could be on your machine, CI/CD or any any other environment. You have the option to do a full test sequence or specific sets. It enables incremental development of your automated configuration. The best part for me, it gives me a safe environment to debug, test and learn. I just need to run `molecule converge` and there I have it.

Molecule has more to it than what has been covered here. [Check out its docs](https://molecule.readthedocs.io/en/latest/getting-started.html) to learn more. If you have read this far, I hope you have been able to simple test a complex scenario and safely screwed things up. :wave:

---
## Additional Resources
The following resources are useful for further learning basic and advanced Ansible topics:
- [Working with Ansible Playbooks – Tips & Tricks with Examples](https://spacelift.io/blog/ansible-playbooks)
- [Multiple Environments in Ansible ](https://dev.to/jobcespedes/multiple-environments-in-ansible-4c6n)
