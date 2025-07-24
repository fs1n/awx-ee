# AWX EE – VMware Enhanced Fork

This repository is a fork of the default [AWX execution environment](https://github.com/ansible/awx-ee), enhanced for VMware automation workflows. It replaces the deprecated `community.vmware` collection and integrates the official VMware SDKs and dependencies.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
  - [Using with AWX](#using-with-awx)
  - [Using with AWX Operator](#using-with-awx-operator)
  - [Using with Ansible Navigator](#using-with-ansible-navigator)
- [VMware Collections and Capabilities](#vmware-collections-and-capabilities)
- [Examples](#examples)
- [Development](#development)
  - [Prerequisites](#development-prerequisites)
  - [Building Locally](#building-locally)
  - [Testing](#testing)
  - [Contributing](#contributing)
- [License](#license)

## Features

This enhanced execution environment provides:

- **Official VMware SDKs**: Includes `vsphere-automation-sdk-python`, `pyvmomi`, and `vcf-sdk`
- **Modern VMware Collections**: Both `community.vmware` and official `vmware.vmware` collections
- **VMware vSphere REST API**: Support via `vmware.vmware_rest` collection
- **Enhanced Dependencies**: All necessary Python packages for VMware automation
- **Multi-Cloud Support**: Includes collections for Azure, AWS, Google Cloud, and OpenStack
- **Container Runtime**: Podman-remote support for containerized workflows
- **Python 3.11**: Modern Python runtime with latest features and performance improvements

## Prerequisites

- Container runtime (Podman or Docker)
- AWX, AWX Operator, or Ansible Navigator
- Access to VMware vCenter/ESXi infrastructure
- Valid VMware credentials

## Usage

### Using with AWX

1. **Add the Execution Environment** in AWX:
   - Navigate to **Administration** → **Execution Environments**
   - Click **Add** and configure:
     - **Name**: `VMware Enhanced EE`
     - **Image**: `ghcr.io/fs1n/awx-ee:latest`
     - **Registry credential**: Configure if using private registry

2. **Configure Job Templates**:
   - When creating or editing a Job Template
   - Set **Execution Environment** to `VMware Enhanced EE`
   - Your playbooks will now have access to all VMware collections and SDKs

### Using with AWX Operator

Configure the execution environment in your AWX resource:

```yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
  namespace: awx
spec:
  # ... other configurations ...
  ee_images:
    - name: VMware Enhanced EE
      image: ghcr.io/fs1n/awx-ee:latest
```

Or add it to an existing AWX instance:

```yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
  namespace: awx
spec:
  # ... existing configurations ...
  extra_settings:
    - setting: AWX_EE_IMAGES
      value:
        - name: VMware Enhanced EE
          image: ghcr.io/fs1n/awx-ee:latest
```

### Using with Ansible Navigator

Create an `ansible-navigator.yml` configuration file:

```yaml
---
ansible-navigator:
  execution-environment:
    image: ghcr.io/fs1n/awx-ee:latest
    enabled: true
    container-engine: podman  # or docker
  ansible:
    inventory:
      entries:
        - /path/to/your/inventory
```

Then run your playbooks:

```bash
ansible-navigator run vmware-playbook.yml
```

## VMware Collections and Capabilities

This execution environment includes the following VMware-related collections:

| Collection | Version | Description |
|------------|---------|-------------|
| `community.vmware` | Latest | Community-maintained VMware modules |
| `vmware.vmware` | Latest | Official VMware-supported collection |
| `vmware.vmware_rest` | Latest | VMware vSphere REST API collection |

### Supported VMware Operations

- **vCenter Management**: User, role, and permission management
- **Virtual Machine Lifecycle**: Creation, configuration, deployment, and management
- **Storage Management**: Datastore and storage policy operations
- **Network Configuration**: Virtual switches, port groups, and distributed switches
- **Host Management**: ESXi host configuration and maintenance
- **Cluster Operations**: DRS, HA, and cluster management
- **Content Library**: Template and ISO management
- **vSphere Tags**: Tagging and categorization
- **Resource Pools**: Resource allocation and management

## Examples

### Basic vCenter Connection Test

```yaml
---
- name: Test vCenter connectivity
  hosts: localhost
  gather_facts: false
  
  tasks:
    - name: Gather vCenter information
      vmware.vmware.vcenter_datacenter_info:
        hostname: "{{ vcenter_hostname }}"
        username: "{{ vcenter_username }}"
        password: "{{ vcenter_password }}"
        validate_certs: false
      register: datacenter_info
    
    - name: Display datacenter information
      debug:
        var: datacenter_info
```

### Create a Virtual Machine

```yaml
---
- name: Create VM from template
  hosts: localhost
  gather_facts: false
  
  tasks:
    - name: Deploy VM from template
      vmware.vmware.vcenter_vm:
        hostname: "{{ vcenter_hostname }}"
        username: "{{ vcenter_username }}"
        password: "{{ vcenter_password }}"
        validate_certs: false
        state: present
        name: "{{ vm_name }}"
        template: "{{ vm_template }}"
        datacenter: "{{ datacenter_name }}"
        folder: "{{ vm_folder }}"
        datastore: "{{ datastore_name }}"
        networks:
          - name: "{{ network_name }}"
```

### Using vSphere REST API

```yaml
---
- name: Get VM information using REST API
  hosts: localhost
  gather_facts: false
  
  tasks:
    - name: Get session information
      vmware.vmware_rest.vcenter_session:
        vcenter_hostname: "{{ vcenter_hostname }}"
        vcenter_username: "{{ vcenter_username }}"
        vcenter_password: "{{ vcenter_password }}"
        vcenter_validate_certs: false
      register: session
    
    - name: Get VM list
      vmware.vmware_rest.vcenter_vm_info:
        vcenter_hostname: "{{ vcenter_hostname }}"
        vcenter_username: "{{ vcenter_username }}"
        vcenter_password: "{{ vcenter_password }}"
        vcenter_validate_certs: false
      register: vm_list
```

## Development

### Development Prerequisites

- Python 3.11+
- [ansible-builder](https://ansible-builder.readthedocs.io/en/stable/installation/)
- Container runtime (Podman recommended, Docker supported)
- Git

Install ansible-builder:

```bash
pip install ansible-builder
```

### Building Locally

Clone the repository and build the execution environment:

```bash
git clone https://github.com/fs1n/awx-ee.git
cd awx-ee

# Build with Podman (default)
ansible-builder build -v3 -t awx-ee:local

# Build with Docker
ansible-builder build -v3 -t awx-ee:local --container-runtime=docker
```

### Testing

This project uses `tox` for testing builds with different container runtimes.

Install tox:

```bash
pip install tox
```

Run tests:

```bash
# Test with Podman
tox -e podman

# Test with Docker
tox -e docker
```

### Modifying the Execution Environment

The execution environment configuration is defined in `execution-environment.yml`. Key sections:

- **Base Image**: CentOS Stream 9 with Python 3.11
- **Collections**: Ansible collections to include
- **Python Dependencies**: Additional Python packages
- **System Dependencies**: System packages and tools
- **Build Steps**: Custom build instructions

After modifying the configuration, rebuild and test:

```bash
ansible-builder build -v3 -t awx-ee:test
podman run --rm -it awx-ee:test ansible --version
```

### Contributing

1. **Fork the repository** on GitHub
2. **Create a feature branch**: `git checkout -b feature/your-feature-name`
3. **Make your changes** and test them locally
4. **Update documentation** if necessary
5. **Test the build**: Run `tox -e podman` or `tox -e docker`
6. **Commit your changes**: Use clear, descriptive commit messages
7. **Push to your fork**: `git push origin feature/your-feature-name`
8. **Create a Pull Request** with a clear description of your changes

#### Guidelines

- Keep changes focused and atomic
- Update documentation for user-facing changes
- Test your changes with both Podman and Docker if possible
- Follow existing code style and conventions
- Update the version in relevant files if making significant changes

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE.md](LICENSE.md) file for details.
