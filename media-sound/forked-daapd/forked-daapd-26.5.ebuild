# Copyright 2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools eutils user systemd

DESCRIPTION="A DAAP (iTunes) media server"
HOMEPAGE="http://ejurgensen.github.io/forked-daapd/"
SRC_URI="https://github.com/ejurgensen/forked-daapd/releases/download/${PV}/${P}.tar.xz -> ${P}.tar.xz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

# TODO: Spotify
IUSE="alsa chromecast +itunes lastfm libav +libwebsockets +mpd pulseaudio +verification +webinterface +zeroconf"

REQUIRED_USE="webinterface? ( libwebsockets )"

RDEPEND="
	>=dev-db/sqlite-3.5.0
	dev-libs/antlr-c
	dev-libs/confuse
	dev-libs/json-c
	>=dev-libs/libevent-2.1.4
	>=dev-libs/libgcrypt-1.2.0
	>=dev-libs/libunistring-0.9.3
	dev-libs/mxml
	sys-libs/zlib

	alsa? ( media-libs/alsa-lib )
	chromecast? (
		dev-libs/protobuf-c
		net-libs/gnutls
	)
	itunes? ( app-pda/libplist )
	lastfm? ( net-misc/curl )
	!libav? ( media-video/ffmpeg:= )
	libav? ( media-video/libav:= )
	libwebsockets? ( >=net-libs/libwebsockets-2.0.2 )
	pulseaudio? ( media-sound/pulseaudio )
	verification? (
		app-pda/libplist
		dev-libs/libsodium
	)
	zeroconf? ( >=net-dns/avahi-0.6.24[dbus] )
"

DEPEND="
	${RDEPEND}
"

pkg_setup() {
	# TODO: Use user virtual.
	enewuser daapd
	enewgroup daapd
}

src_configure() {
	econf --localstatedir="${EPREFIX}"/var \
		$(use_enable chromecast) \
		$(use_enable itunes) \
		$(use_enable lastfm) \
		$(use_enable mpd) \
		$(use_enable verification) \
		$(use_enable webinterface) \
		$(use_with alsa) \
		$(use_with lastfm libcurl) \
		$(use_with libwebsockets) \
		$(use_with pulseaudio) \
		$(use_with zeroconf avahi)
}

src_install() {
	emake DESTDIR="${D}" install

	# remove empty dirs
	rm -rf "${D}"/var/{log,run} || die

	keepdir /var/cache/forked-daapd
	fowners daapd:daapd /var/cache/forked-daapd /var/cache/forked-daapd/libspotify

	newinitd "${FILESDIR}/forked-daapd.initd" "forked-daapd"

	systemd_dounit "${S}/forked-daapd.service"

	# TODO: Add some info about /srv/music
}
