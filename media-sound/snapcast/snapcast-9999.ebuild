# Copyright 1999-2018 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit user git-r3

DESCRIPTION="Synchronous multi-room audio player"
HOMEPAGE="https://github.com/badaix/snapcast"
EGIT_REPO_URI="https://github.com/badaix/snapcast.git"

if [[ ${PV} == *9999 ]] ; then
	EGIT_BRANCH="develop"
else
	EGIT_COMMIT="v${PV}"
fi

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""
IUSE="+server +client"

REQUIRED_USE="|| ( server client )"

DEPEND="net-dns/avahi[dbus]
	media-libs/libvorbis
	media-libs/flac
	client? ( media-libs/alsa-lib )"
RDEPEND="${DEPEND}"

pkg_preinst() {
	for bin in server client
	do
		if use server ; then
			enewgroup "snapserver"
			enewuser "snapserver" -1 -1 /dev/null snapserver
		fi
		if use client ; then
			enewuser "snapclient" -1 -1 /dev/null audio
		fi
	done
}

src_compile() {
	for bin in server client
	do
		if use ${bin} ; then
			emake STRIP="echo" ADD_CFLAGS="${CXXFLAGS}" ADD_LDFLAGS="${LDFLAGS}" "${bin}"
		fi
	done
}

src_install() {
	for bin in server client
	do
		if use ${bin} ; then
			dobin "${bin}/snap${bin}"
			doman "${bin}/snap${bin}.1"

			newconfd "${S}/${bin}/debian/snap${bin}.default" "snap${bin}"
			newinitd "${FILESDIR}/snap${bin}.openrc" "snap${bin}"
		fi
	done
}
