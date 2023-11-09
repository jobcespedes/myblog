---
title: "A KeyDB Operator"
author: Job Céspedes Ortiz
date: 2022-01-22T23:00:00-06:00
subtitle: "for Kubernetes"
image: ""
tags:
  - keydb
  - redis
  - kubernetes
  - containers
  - moodle-operator
  - krestomatio
---
[KeyDB](https://keydb.dev/) is a multithreading, drop-in alternative to Redis. The [Keydb-operator](https://github.com/krestomatio/keydb-operator) can easily create either a standalone instance (1 replica) or a multimaster setup (3 replicas) of the [KeyDB in-memory database](https://github.com/EQ-Alpha/KeyDB). When KeyDB is in [multimaster mode](https://docs.keydb.dev/docs/multi-master/), it is possible to have more than one master, allowing for read/write operations across all of them. This capability enhances high availability and fault tolerance.

>This operator is part of the Kubernetes operators and tools developed by [Krestomatio, a managed service for Moodle™ instances](https://krestomatio.com)

## Install

> The Kubernetes Operator in this project is in **Alpha** version. **Use at your own risk**

Check out the [sample CR](config/samples/keydb_v1alpha1_keydb.yaml). Follow the next steps to first install the KeyDB Operatorn and then a KeyDB instance:
```bash
# install the operator
make deploy

# create KeyDB instance from sample
kubectl apply -f config/samples/keydb_v1alpha1_keydb.yaml

# follow/check KeyDB operator logs
kubectl -n keydb-operator-system logs -l control-plane=controller-manager -c manager  -f

# follow sample CR status
kubectl get keydb keydb-sample -o yaml -w
```

## Uninstall
Follow the next steps to uninstall it.
```bash
# delete the KeyDB object
# CAUTION with data loss
kubectl delete -f config/samples/keydb_v1alpha1_keydb.yaml

# uninstall the operator
make undeploy
```

### Advanced Options
For different or advanced configuration via the CR spec, take a look at the [variables available](https://github.com/krestomatio/ansible-collection-k8s/blob/master/roles/v1alpha1/database/keydb/defaults/main/keydb.yml)

## Want to contribute?
* Use github issues to report bugs, send enhancement, new feature requests and questions

## [About Krestomatio](https://krestomatio.com/about)
[Krestomatio is a managed service for Moodle™ e-learning platforms](https://krestomatio.com/). It allows you to have open-source instances managed by a service optimized for Moodle™, complete with an additional plugin pack and customization options.
