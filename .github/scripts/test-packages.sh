#!/usr/bin/env bash
set -euo pipefail

# Run inside a fresh Gentoo desktop stage3.
emerge-webrsync
arch=$(portageq envvar ARCH)
package=net-vpn/globalprotect-openconnect

mkdir -p /etc/portage/{repos.conf,package.accept_keywords,package.use}
cat > /etc/portage/repos.conf/yuezk.conf <<'REPO'
[yuezk]
location = /var/db/repos/yuezk
auto-sync = no
REPO
printf '%s::yuezk ~%s\n' "$package" "$arch" "$package-bin" "$arch" \
    > /etc/portage/package.accept_keywords/gp-connect
cat > /etc/portage/package.use/gp-connect <<'USE'
net-libs/gnutls pkcs11
x11-libs/gtk+:3 X wayland
# Match the official desktop binhost's WebKit build.
net-libs/webkit-gtk:4.1 keyring
USE

verify_install() {
    local installed=$1 removed=$2 executable linkage
    portageq has_version / "$installed::yuezk"
    if portageq has_version / "$removed"; then
        echo "Unexpected installed package: $removed" >&2
        return 1
    fi

    gpclient --version
    gpservice --version
    gpauth --version
    gpgui-helper --help > /dev/null
    test ! -e /usr/bin/gpgui
    for executable in /usr/bin/{gpclient,gpservice,gpauth,gpgui-helper} \
        /usr/libexec/gpclient/{gp-hip-script-installer,gp-vpnc-script-installer}; do
        linkage=$(LC_ALL=C ldd -r "$executable" 2>&1)
        if grep -E 'not found|undefined symbol:' <<< "$linkage"; then
            echo "Unresolved dependency in $executable" >&2
            return 1
        fi
    done
}

# Use Gentoo binaries for dependencies and always exercise the overlay's ebuilds.
emerge_args=(--getbinpkg --usepkg-exclude "${package} ${package}-bin")
MAKEOPTS="-j$(nproc)"
export MAKEOPTS
emerge "${emerge_args[@]}" "$package-bin::yuezk"
verify_install "$package-bin" "$package"

# Exercise the source build with the system JSON parser visible to pkg-config.
emerge "${emerge_args[@]}" --oneshot dev-libs/json-parser
pkg-config --exists json-parser

emerge --deselect "$package-bin::yuezk"
emerge "${emerge_args[@]}" "$package::yuezk"
verify_install "$package" "$package-bin"
