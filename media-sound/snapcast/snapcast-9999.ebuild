# Copyright 1999-2018 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Synchronous multi-room audio player"
HOMEPAGE="https://github.com/badaix/snapcast"

if [[ ${PV} == *9999 ]] ; then
	inherit user cmake-utils git-r3

	EGIT_REPO_URI="https://github.com/badaix/snapcast.git"
	EGIT_BRANCH="develop"

	KEYWORDS=""
else
	inherit user cmake-utils

	POPLVER="1.2.0"
	AIXLOGVER="1.2.1"

	SRC_URI="https://github.com/badaix/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz
		https://github.com/badaix/popl/archive/v${POPLVER}.tar.gz -> popl-v${POPLVER}.tar.gz
		https://github.com/badaix/aixlog/archive/v${AIXLOGVER}.tar.gz -> aixlog-v${AIXLOGVER}.tar.gz"

	KEYWORDS="~amd64 ~x86"
fi

LICENSE="GPL-3+"
SLOT="0"
IUSE="+avahi +client +flac +server static-libs test tremor +vorbis"

REQUIRED_USE="|| ( server client )"

DEPEND=">=dev-cpp/asio-1.12.1
	avahi? ( net-dns/avahi[dbus] )
	client? ( media-libs/alsa-lib )
	flac? ( media-libs/flac )
	tremor? ( media-libs/tremor )
	vorbis? ( media-libs/libvorbis )"
RDEPEND="${DEPEND}"

PATCHES=( "${FILESDIR}/${PN}-options-for-use-flags.patch" )

pkg_preinst() {
	if use server ; then
		enewgroup "snapserver"
		enewuser "snapserver" -1 -1 /dev/null snapserver
	fi
	if use client ; then
		enewuser "snapclient" -1 -1 /dev/null audio
	fi
}

src_prepare() {
	if [[ ${PV} == *9999 ]] ; then
		cp "${S}/externals/popl/include/popl.hpp" "${S}/"
		cp "${S}/externals/aixlog/include/aixlog.hpp" "${S}/"
	else
		cp "${WORKDIR}/popl-${POPLVER}/include/popl.hpp" "${WORKDIR}/${P}/"
		cp "${WORKDIR}/aixlog-${AIXLOGVER}/include/aixlog.hpp" "${WORKDIR}/${P}/"
	fi

	cmake-utils_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DBUILD_WITH_AVAHI=$(usex avahi)
		-DBUILD_CLIENT=$(usex client)
		-DBUILD_WITH_FLAC=$(usex flac)
		-DBUILD_SERVER=$(usex server)
		-DBUILD_STATIC_LIBS=$(usex static-libs)
		-DBUILD_TESTS=$(usex test)
		-DBUILD_WITH_TREMOR=$(usex tremor)
		-DBUILD_WITH_VORBIS=$(usex vorbis)
	)

	cmake-utils_src_configure
}

src_install() {
	for bin in server client
	do
		if use ${bin} ; then
			doman "${bin}/snap${bin}.1"

			newconfd "${S}/${bin}/debian/snap${bin}.default" "snap${bin}"
			newinitd "${FILESDIR}/snap${bin}.initd" "snap${bin}"
		fi
	done

	cmake-utils_src_install
}
