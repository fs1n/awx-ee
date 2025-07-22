# AWX EE

This is a Fork of the Default (AWX execution environment)[https://github.com/ansible/awx-ee] updated with some stuff for VMWare automation due to the deprecation of community.vmware

## Build the image locally

First, [install ansible-builder](https://ansible-builder.readthedocs.io/en/stable/installation/).

Then run the following command from the root of this repo:

```bash
$ ansible-builder build -v3 -t quay.io/ansible/awx-ee # --container-runtime=docker # Is podman by default
```
