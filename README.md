# GP Connect for Gentoo

GP Connect is an independent client for GlobalProtect VPN networks.

| Package | Installs |
| --- | --- |
| `net-vpn/globalprotect-openconnect-bin` | Prebuilt desktop and CLI for glibc systems |
| `net-vpn/globalprotect-openconnect` | Desktop and CLI by default, or CLI only with `-gui` |

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

## CLI only

For a headless system, add this line to `/etc/portage/package.use/gp-connect`:

```text
net-vpn/globalprotect-openconnect::yuezk -gui
```

```sh
sudo emerge --ask --changed-use net-vpn/globalprotect-openconnect::yuezk
sudo gpclient connect vpn.example.com --browser manual
```

Open the printed URL in a browser and paste the callback into the terminal. This requires a portal that allows external-browser sign-in. For embedded sign-in, enable `gui` and rerun the emerge command.
