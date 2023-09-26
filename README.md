# KPT demo
<!-- markdown-link-check-disable-next-line -->
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)
<!-- markdown-link-check-disable-next-line -->
![visitors](https://visitor-badge.laobi.icu/badge?page_id=electrocucaracha.k8s-KPT-demo)

## Summary

This project provides a Sandbox environment for testing [KPT project][1].

### Local kpt Command-line demo
[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?repo=electrocucaracha/k8s-KPT-demo)

### Porch demo
![Screen porch demo](demo-porch.svg)

## Virtual Machines

The [Vagrant tool][2] can be used for provisioning an Ubuntu Focal
Virtual Machine. It's highly recommended to use the  *setup.sh* script
of the [bootstrap-vagrant project][3] for installing Vagrant
dependencies and plugins required for this project. That script
supports two Virtualization providers (Libvirt and VirtualBox) which
are determine by the **PROVIDER** environment variable.

    curl -fsSL http://bit.ly/initVagrant | PROVIDER=libvirt bash

Once Vagrant is installed, it's possible to provision a Virtual
Machine using the following instructions:

    vagrant up

The provisioning process will take some time to install all
dependencies required by this project and perform a Kubernetes
deployment on it.

[1]: https://kpt.dev/
[2]: https://www.vagrantup.com/
[3]: https://github.com/electrocucaracha/bootstrap-vagrant
