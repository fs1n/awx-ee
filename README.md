# AWX EE – VMware Enhanced Fork

This repository is a fork of the default [AWX execution environment](https://github.com/ansible/awx-ee), enhanced for VMware automation workflows. It replaces the deprecated `community.vmware` collection and integrates the official VMware SDKs and dependencies.

## Build the image locally

First, [install ansible-builder](https://ansible-builder.readthedocs.io/en/stable/installation/).

Then run the following command from the root of this repo:

```bash
$ ansible-builder build -v3 -t quay.io/ansible/awx-ee # --container-runtime=docker # Is podman by default
```
