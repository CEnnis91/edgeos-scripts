# edgeos-scripts

Collection of pure Unix shell scripts and utilities for managing Ubiquiti EdgeMAX routers. Some scripts are derived from various guides around the internet. This repo is designed to be installed into `/config/scripts`.

# Getting Started

I prefer to install this through git, but some routers have smaller filesystems, like the EdgeRouter-X, and git can take up a lot of space.

## Prerequisites

- SSH access with **admin privileges**

## Installing via Curl
```bash
curl -so /tmp/edgeos-scripts.tar.gz https://www.github.com/CEnnis91/edgeos-scripts/archive/master.tar.gz

cd /config
mv scripts/ scripts_old/    # if it exists

tar xzvf /tmp/edgeos-scripts.tar.gz
mv edgeos-scripts-master/ scripts/
```

## Installing via Git

If you don't have git installed yet:
```bash
curl -so /tmp/cfg_debian_packages.sh https://raw.githubusercontent.com/CEnnis91/edgeos-scripts/master/bin/cfg_debian_packages.sh

# don't run random things from the internet without inspecting them first
chmod +x /tmp/cfg_debian_packages.sh
/tmp/cfg_debian_packages.sh

apt-get update && apt-get install -y git
```

Once git is installed:
```bash
cd /config
mv scripts/ scripts_old/    # if it exists

git clone https://github.com/CEnnis91/edgeos-scripts.git scripts/
```

# Contributing

TODO, I'm not sure what I plan to do with this yet.

# Acknowledgements

- [EdgeRouter - Add Debian Packages to EdgeOS](https://help.ui.com/hc/en-us/articles/205202560-EdgeRouter-Add-Debian-Packages-to-EdgeOS)
- [Install EdgeOS Packages Script V1.0 with Upgrade Persistence](https://community.ui.com/questions/cf737894-174c-4aef-8aed-ebcfe62f5cff)
- [EdgeRouter - Custom Dynamic DNS](https://help.ui.com/hc/en-us/articles/204976324-EdgeRouter-Custom-Dynamic-DNS)
- [EdgeRouter - OpenVPN Server](https://help.ui.com/hc/en-us/articles/115015971688-EdgeRouter-OpenVPN-Server)
- https://github.com/hungnguyenm/edgemax-acme
- https://github.com/acmesh-official/acme.sh

# License

License is [Unlicense](LICENSE.md).
