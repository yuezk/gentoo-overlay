# GP Connect for Gentoo

GP Connect is an independent client for GlobalProtect VPN networks. The two packages provide the same client commands and desktop launcher.

| Package | Installs |
| --- | --- |
| `net-vpn/globalprotect-openconnect-bin` | Prebuilt client for glibc systems |
| `net-vpn/globalprotect-openconnect` | Client built from source |

## Install

Add the overlay:

```sh
sudo emerge --ask app-eselect/eselect-repository dev-vcs/git
sudo eselect repository add yuezk git https://github.com/yuezk/gentoo-overlay.git
sudo emerge --sync yuezk
```

Install one package:

```sh
sudo emerge --ask net-vpn/globalprotect-openconnect-bin::yuezk
# Or build from source
sudo emerge --ask net-vpn/globalprotect-openconnect::yuezk
```

If Portage requests keyword or USE flag changes, review and apply them, then rerun the install command.

Open **GP Connect** from the application menu or run `gpclient launch-gui`.
