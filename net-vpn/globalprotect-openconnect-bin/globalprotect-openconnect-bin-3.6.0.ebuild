# Copyright 2026 Kevin Yue
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit xdg

DESCRIPTION="Independent client for GlobalProtect VPN networks (upstream binaries)"
HOMEPAGE="https://github.com/yuezk/GlobalProtect-openconnect"
MY_PN=${PN%-bin}
BASE_URI="https://github.com/yuezk/GlobalProtect-openconnect/releases/download/v${PV}/${MY_PN}_${PV}"
SRC_URI="
	amd64? ( ${BASE_URI}_x86_64.bin.tar.xz )
	arm64? ( ${BASE_URI}_aarch64.bin.tar.xz )
"
S="${WORKDIR}/${MY_PN}_${PV}"

LICENSE="GPL-3 GPL-2+ LGPL-2.1 Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD BSD-2 CDLA-Permissive-2.0 ISC MIT MPL-2.0 Unicode-3.0 ZLIB"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
RESTRICT="mirror"

RDEPEND="
	!net-vpn/GlobalProtect-openconnect
	!net-vpn/globalprotect-openconnect
	app-arch/lz4
	app-arch/xz-utils
	app-crypt/libsecret
	app-crypt/p11-kit
	dev-libs/gmp
	dev-libs/libayatana-appindicator
	dev-libs/nettle
	net-libs/gnutls[pkcs11]
	net-libs/libsoup:3.0
	net-libs/webkit-gtk:4.1
	sys-apps/dbus
	sys-apps/iproute2
	sys-auth/polkit
	sys-libs/glibc
	virtual/secret-service
	virtual/zlib
	x11-libs/gtk+:3[X,wayland]
	x11-misc/xdg-utils
"
QA_PREBUILT="usr/bin/gp* usr/libexec/gpclient/gp-*-installer"

src_compile() { :; }

src_install() {
	# The helper downloads the desktop client when requested.
	rm -f artifacts/usr/bin/gpgui || die
	emake install DESTDIR="${ED}"
}
