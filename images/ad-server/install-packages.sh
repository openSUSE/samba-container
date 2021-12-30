#!/bin/bash

set -ex

get_custom_repo() {
    url="$1"
    fname="$(basename "$url")"
    dest="/etc/yum.repos.d/${fname}"
    dnf install --setopt=install_weak_deps=False -y curl
    curl "$url" -o "$dest"
}

install_packages_from="$1"
case "${install_packages_from}" in
    samba-nightly)
        get_custom_repo "http://artifacts.ci.centos.org/samba/pkgs/master/fedora/samba-nightly-master.repo"
    ;;
    custom-repo)
        get_custom_repo "${INSTALL_CUSTOM_REPO}"
    ;;
esac

dnf install --setopt=install_weak_deps=False -y \
    findutils \
    python-pip \
    python3-jsonschema \
    python3-samba \
    samba-dc \
    procps-ng \
    /usr/bin/smbclient
dnf clean all

rm -rf /etc/samba/smb.conf
