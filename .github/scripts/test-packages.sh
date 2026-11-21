#!/usr/bin/env bash
set -euo pipefail

mode=${1:?expected desktop or headless}
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
echo "net-libs/gnutls pkcs11" > /etc/portage/package.use/gp-connect
case "$mode" in
headless)
    # polkit on the systemd profile requires systemd's policykit integration.
    printf '%s\n' "$package::yuezk -gui" "sys-apps/systemd policykit" >> /etc/portage/package.use/gp-connect
    ;;
desktop)
    cat >> /etc/portage/package.use/gp-connect <<'USE'
x11-libs/gtk+:3 X wayland
# Match the official desktop binhost's WebKit build.
net-libs/webkit-gtk:4.1 keyring
USE
    ;;
*) exit 2 ;;
esac

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
    local desktop=/usr/share/applications/gpgui.desktop
    local executables=(/usr/bin/{gpclient,gpservice,gpauth}
        /usr/libexec/gpclient/{gp-hip-script-installer,gp-vpnc-script-installer})
    test ! -e /usr/bin/gpgui
    grep -Fxq 'MimeType=x-scheme-handler/globalprotectcallback;' "$desktop"
    grep -Fxq 'Exec=/usr/bin/gpclient launch-gui %u' "$desktop"
    if [[ $mode == desktop ]]; then
        gpgui-helper --help > /dev/null
        executables+=(/usr/bin/gpgui-helper)
        if grep -Fxq 'NoDisplay=true' "$desktop"; then return 1; fi
    else
        test ! -e /usr/bin/gpgui-helper
        test ! -e /usr/share/applications/gpgui-helper.desktop
        test ! -e /usr/share/applications/gpauth.desktop
        if compgen -G '/usr/share/icons/hicolor/*/apps/gpgui.*' >/dev/null; then return 1; fi
        grep -Fxq 'NoDisplay=true' "$desktop"
    fi
    for executable in "${executables[@]}"; do
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
if [[ $mode == desktop ]]; then
    emerge "${emerge_args[@]}" "$package-bin::yuezk"
    verify_install "$package-bin" "$package"
    emerge --deselect "$package-bin::yuezk"
fi

desktop_atoms=(x11-libs/gtk+:3 net-libs/libsoup:3.0 net-libs/webkit-gtk:4.1 virtual/secret-service x11-misc/xdg-utils)
if [[ $mode == headless ]]; then
    # Verbose merge rows include the slot for both ebuilds and binary packages.
    emerge "${emerge_args[@]}" --pretend --verbose --color=n "$package::yuezk" |
        awk -v atoms="${desktop_atoms[*]}" '
            BEGIN { count = split(atoms, forbidden) }
            { print }
            /^\[(ebuild|binary) / {
                sub(/^[^]]*] +/, "")
                split($1, parts, ":")
                name = parts[1]
                sub(/-[0-9].*$/, "", name)
                split(parts[2], slot, "/")
                for (i = 1; i <= count; i++)
                    if (forbidden[i] == name || forbidden[i] == name ":" slot[1]) {
                        print "Unexpected desktop dependency in plan: " $1
                        failed = 1
                    }
            }
            END { exit failed }
        '
fi

# Exercise the source build with the system JSON parser visible to pkg-config.
emerge "${emerge_args[@]}" --oneshot dev-libs/json-parser
pkg-config --exists json-parser

emerge "${emerge_args[@]}" "$package::yuezk"
verify_install "$package" "$package-bin"

if [[ $mode == headless ]]; then
    for atom in "${desktop_atoms[@]}"; do
        if portageq has_version / "$atom"; then
            echo "Unexpected desktop dependency: $atom" >&2
            exit 1
        fi
    done
    useradd --create-home gp-test
    runuser -u gp-test -- timeout 45s python3 "$(dirname "$0")/test-manual-auth.py"
fi
