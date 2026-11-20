# Copyright 2026 Kevin Yue
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.91.0"
inherit multiprocessing rust xdg

DESCRIPTION="Independent client for GlobalProtect VPN networks"
HOMEPAGE="https://github.com/yuezk/GlobalProtect-openconnect"
SRC_URI="${HOMEPAGE}/releases/download/v${PV}/${P}.offline.tar.gz"

LICENSE="GPL-3 GPL-2+ LGPL-2.1 Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD BSD-2 CDLA-Permissive-2.0 ISC MIT MPL-2.0 Unicode-3.0 ZLIB"
SLOT="0"
KEYWORDS="~arm64"

DEPEND="
	app-arch/lz4:=
	app-arch/xz-utils
	app-crypt/p11-kit
	dev-libs/gmp:=
	dev-libs/libxml2:=
	dev-libs/nettle:=
	net-libs/gnutls:=[pkcs11]
	net-libs/libsoup:3.0
	net-libs/webkit-gtk:4.1=
	sys-apps/dbus
	virtual/zlib:=
	x11-libs/gtk+:3[X,wayland]
"
RDEPEND="${DEPEND}
	!net-vpn/GlobalProtect-openconnect
	!net-vpn/globalprotect-openconnect-bin
	app-crypt/libsecret
	dev-libs/libayatana-appindicator
	sys-apps/iproute2
	sys-auth/polkit
	virtual/secret-service
	x11-misc/xdg-utils
"
BDEPEND+="
	dev-build/autoconf
	dev-build/automake
	dev-build/libtool
	sys-devel/gettext
	virtual/pkgconfig
"

src_compile() {
	export CARGO_BUILD_JOBS=$(makeopts_jobs)
	export CARGO_PROFILE_RELEASE_STRIP=none
	emake build-rs OFFLINE=1
}

src_install() {
	emake install DESTDIR="${D}" PREFIX="${EPREFIX}/usr"
}
