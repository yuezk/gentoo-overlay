# Gentoo overlay

GP Connect is an independent client for GlobalProtect VPN networks. The two packages provide the same client commands and desktop launcher.

| Package | Installation |
| --- | --- |
| `net-vpn/globalprotect-openconnect` | Builds the client, service, authentication component, and GUI helper from the upstream source release. |
| `net-vpn/globalprotect-openconnect-bin` | Installs those components from the upstream glibc binary release. |

Both packages use the GUI helper to download the desktop client on demand. The binary ebuild fetches its release archive directly from GitHub. Mirroring is restricted because the original archive also contains the commercial desktop client.

## Use a local checkout

As root, add the absolute path to the checkout in `/etc/portage/repos.conf/yuezk.conf`:

```ini
[yuezk]
location = /absolute/path/to/gentoo-overlay
auto-sync = no
```

On stable ARM64, add the package you want to `/etc/portage/package.accept_keywords`, for example:

```text
net-vpn/globalprotect-openconnect-bin ~arm64
```

Both variants require GnuTLS with PKCS#11 support and GTK 3 with both the X11 and Wayland backends. If your profile does not already enable these USE flags, add the following to `/etc/portage/package.use`:

```text
net-libs/gnutls pkcs11
x11-libs/gtk+:3 X wayland
```

Install one variant with Portage:

```sh
emerge --ask net-vpn/globalprotect-openconnect-bin::yuezk
# Or build from source:
emerge --ask net-vpn/globalprotect-openconnect::yuezk
```

Open **GP Connect** from the application menu, or run `gpclient launch-gui` as your desktop user.

To switch from the binary package to the source package, accept the source package's keyword, then run:

```sh
emerge --deselect net-vpn/globalprotect-openconnect-bin::yuezk
emerge --ask net-vpn/globalprotect-openconnect::yuezk
```

Portage installs the replacement and removes the old package. To switch the other way, exchange the two package names.
