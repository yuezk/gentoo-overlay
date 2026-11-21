# Copyright 2026 Kevin Yue
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.91.0"
inherit multiprocessing optfeature rust xdg

DESCRIPTION="Independent client for GlobalProtect VPN networks"
HOMEPAGE="https://github.com/yuezk/GlobalProtect-openconnect"
SRC_URI="https://github.com/yuezk/GlobalProtect-openconnect/releases/download/v${PV}/${P}.offline.tar.gz"

LICENSE="GPL-3 GPL-2+ LGPL-2.1 Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD BSD-2 CDLA-Permissive-2.0 ISC MIT MPL-2.0 Unicode-3.0 ZLIB"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="+gui"

DEPEND="
	app-arch/lz4:=
	app-arch/xz-utils
	app-crypt/p11-kit
	dev-libs/gmp:=
	dev-libs/libxml2:=
	dev-libs/nettle:=
	net-libs/gnutls:=[pkcs11]
	sys-apps/dbus
	virtual/zlib:=
	gui? (
		net-libs/libsoup:3.0
		net-libs/webkit-gtk:4.1=
		x11-libs/gtk+:3[X,wayland]
	)
"
RDEPEND="${DEPEND}
	!net-vpn/GlobalProtect-openconnect
	!net-vpn/globalprotect-openconnect-bin
	sys-apps/iproute2
	sys-auth/polkit
	gui? (
		virtual/secret-service
		x11-misc/xdg-utils
	)
"
BDEPEND+="
	dev-build/autoconf
	dev-build/automake
	dev-build/libtool
	sys-devel/gettext
	virtual/pkgconfig
"

src_prepare() {
	default
	if ! use gui; then
		# The upstream install target relocates the callback command for EPREFIX.
		cp "${FILESDIR}/gpgui-callback.desktop" packaging/files/usr/share/applications/gpgui.desktop || die
	fi
}

gp_emake() {
	local gui=$(usex gui 1 0)
	emake INCLUDE_GUI=0 BUILD_GUI_HELPER="${gui}" BUILD_WEBVIEW_AUTH="${gui}" "$@"
}

src_compile() {
	export CARGO_BUILD_JOBS=$(makeopts_jobs)
	export CARGO_PROFILE_RELEASE_STRIP=none
	gp_emake build-rs OFFLINE=1
}

src_install() {
	gp_emake install DESTDIR="${D}" PREFIX="${EPREFIX}/usr"
	if ! use gui; then
		rm "${ED}"/usr/share/applications/{gpauth,gpgui-helper}.desktop || die
		rm "${ED}"/usr/share/icons/hicolor/*/apps/gpgui.* || die
	fi
}

pkg_postinst() {
	xdg_pkg_postinst
	if use gui; then
		optfeature "the Native Shell desktop interface" ">=gui-libs/gtk-4.14:4"
	else
		optfeature "opening a local browser for sign-in" x11-misc/xdg-utils
	fi
}
