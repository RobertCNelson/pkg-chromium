#!/bin/sh -e
#
# Copyright (c) 2014 Robert Nelson <robertcnelson@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

DIR=$PWD

#http://gsdview.appspot.com/chromium-browser-official/
chrome_version="31.0.1650.69"
unset use_testing
if [ -f testing ] ; then
	chrome_version="32.0.1700.69"
	use_testing=enable
fi

check_dpkg () {
	LC_ALL=C dpkg --list | awk '{print $2}' | grep "^${pkg}$" >/dev/null || deb_pkgs="${deb_pkgs}${pkg} "
}

check_dependencies() {
	unset deb_pkgs
	pkg="bison"
	check_dpkg
	pkg="build-essential"
	check_dpkg
	pkg="gperf"
	check_dpkg
	pkg="libcups2-dev"
	check_dpkg
	pkg="libgtk2.0-dev"
	check_dpkg
	pkg="libnss3-dev"
	check_dpkg
	pkg="libgconf2-dev"
	check_dpkg
	pkg="libgcrypt11-dev"
	check_dpkg
	pkg="libgnome-keyring-dev"
	check_dpkg
	pkg="libpci-dev"
	check_dpkg
	pkg="libspeechd-dev"
	check_dpkg
	pkg="libudev-dev"
	check_dpkg
	pkg="pkg-config"
	check_dpkg
	pkg="yasm"
	check_dpkg

	deb_arch=$(LC_ALL=C dpkg --print-architecture)
	pkg="libasound2-dev:${deb_arch}"
	check_dpkg
	pkg="libjpeg8-dev:${deb_arch}"
	check_dpkg
	pkg="libpulse-dev:${deb_arch}"
	check_dpkg
	pkg="libxml2-dev:${deb_arch}"
	check_dpkg
	pkg="libxss-dev:${deb_arch}"
	check_dpkg
	pkg="libxtst-dev:${deb_arch}"
	check_dpkg

	deb_distro=$(lsb_release -cs | sed 's/\//_/g')
	case "${deb_distro}" in
	wheezy)
		pkg="libsqlite3-dev"
		check_dpkg
		pkg="libxslt1-dev"
		check_dpkg
		if [ ! -f /usr/local/bin/ninja ] ; then
			mkdir -p /tmp/ninja
			git clone git://github.com/martine/ninja.git /tmp/ninja
			cd /tmp/ninja
			git checkout release
			./bootstrap.py
			sudo cp -v ./ninja /usr/local/bin/
		fi
		;;
	jessie|sid)
		pkg="libsqlite3-dev:${deb_arch}"
		check_dpkg
		pkg="libxslt1-dev:${deb_arch}"
		check_dpkg
		pkg="ninja-build"
		check_dpkg
		;;
	esac

	if [ "${deb_pkgs}" ] ; then
		echo "Installing: ${deb_pkgs}"
		sudo apt-get update
		sudo apt-get -y install ${deb_pkgs}
		sudo apt-get clean
	fi
}

set_testing_defines () {
	#http://anonscm.debian.org/gitweb/?p=pkg-chromium/pkg-chromium.git;a=blob_plain;f=debian/rules;hb=HEAD

	# Disable SSE2
	GYP_DEFINES="disable_sse2=1"

	#Debian Chromium Api Key
	#GYP_DEFINES="${GYP_DEFINES} google_api_key=''"
	#GYP_DEFINES="${GYP_DEFINES} google_default_client_id=''"
	#GYP_DEFINES="${GYP_DEFINES} google_default_client_secret=''"

	# Enable all codecs for HTML5 in chromium, depending on which ffmpeg sumo lib
	# is installed, the set of usable codecs (at runtime) will still vary
	GYP_DEFINES="${GYP_DEFINES} proprietary_codecs=1"

	# enable compile-time dependency on gnome-keyring
	GYP_DEFINES="${GYP_DEFINES} use_gnome_keyring=1 linux_link_gnome_keyring=1"

	# controlling the use of GConf (the classic GNOME configuration
	# and GIO, which contains GSettings (the new GNOME config system)
	GYP_DEFINES="${GYP_DEFINES} use_gconf=1 use_gio=1"

	# disable native client (nacl)
	GYP_DEFINES="${GYP_DEFINES} disable_nacl=1"

	# do not use embedded third_party/gold as the linker.
	GYP_DEFINES="${GYP_DEFINES} linux_use_gold_binary=0 linux_use_gold_flags=0"

	# disable tcmalloc
	GYP_DEFINES="${GYP_DEFINES} linux_use_tcmalloc=0"

	# Use explicit library dependencies instead of dlopen.
	# This makes breakages easier to detect by revdep-rebuild.
	GYP_DEFINES="${GYP_DEFINES} linux_link_gsettings=1"

	GYP_DEFINES="${GYP_DEFINES} disable_nacl=1"
	GYP_DEFINES="${GYP_DEFINES} linux_use_tcmalloc=0"
	GYP_DEFINES="${GYP_DEFINES} enable_webrtc=0"
	GYP_DEFINES="${GYP_DEFINES} use_cups=1"

	if [ "x${deb_arch}" = "xarmhf" ] ; then
		GYP_DEFINES="${GYP_DEFINES} sysroot=/"
		GYP_DEFINES="${GYP_DEFINES} target_arch=arm"
		GYP_DEFINES="${GYP_DEFINES} -DUSE_EABI_HARDFLOAT"
		GYP_DEFINES="${GYP_DEFINES} v8_use_arm_eabi_hardfloat=true"
		GYP_DEFINES="${GYP_DEFINES} arm_fpu=vfpv3"
		GYP_DEFINES="${GYP_DEFINES} arm_float_abi=hard"
		GYP_DEFINES="${GYP_DEFINES} arm_thumb=1"
		GYP_DEFINES="${GYP_DEFINES} armv7=1"
		GYP_DEFINES="${GYP_DEFINES} arm_neon=0"
	fi

	GYP_DEFINES="${GYP_DEFINES} library=shared_library"

	# Always ignore compiler warnings
	GYP_DEFINES="${GYP_DEFINES} werror="

	# FFmpeg-mt
	#ifeq (1,$(USE_SYSTEM_FFMPEG))
	#GYP_DEFINES="${GYP_DEFINES} build_ffmpegsumo=0"
	#else
	GYP_DEFINES="${GYP_DEFINES} ffmpeg_branding=Chrome"
	#endif

	#$USE_SYSTEM_LIBWEBP := $(shell pkg-config 'libwebp >= 0.3.0' && echo 1 || echo 0)
	#USE_SYSTEM_LIBWEBP := 0

	# System libs
	GYP_DEFINES="${GYP_DEFINES} use_system_bzip2=1"
	GYP_DEFINES="${GYP_DEFINES} use_system_libjpeg=1"
	GYP_DEFINES="${GYP_DEFINES} use_system_libpng=1"
	#sqlite3 >= 3.6.1
	#fails with jessie: 31.0.1650.69
	#GYP_DEFINES="${GYP_DEFINES} use_system_sqlite=1"
	GYP_DEFINES="${GYP_DEFINES} use_system_libxml=1"
	GYP_DEFINES="${GYP_DEFINES} use_system_libxslt=1"
	GYP_DEFINES="${GYP_DEFINES} use_system_zlib=1"
	GYP_DEFINES="${GYP_DEFINES} use_system_libevent=1"
	GYP_DEFINES="${GYP_DEFINES} use_system_icu=0"
	GYP_DEFINES="${GYP_DEFINES} use_system_yasm=1"
	#GYP_DEFINES="${GYP_DEFINES} use_system_ffmpeg=$(USE_SYSTEM_FFMPEG)"
	GYP_DEFINES="${GYP_DEFINES} use_system_libvpx=1"
	GYP_DEFINES="${GYP_DEFINES} use_system_xdg_utils=1"
	GYP_DEFINES="${GYP_DEFINES} use_system_flac=1"
	#GYP_DEFINES="${GYP_DEFINES} use_system_libwebp=$(USE_SYSTEM_LIBWEBP)"
	GYP_DEFINES="${GYP_DEFINES} use_system_speex=1"
	GYP_DEFINES="${GYP_DEFINES} linux_link_libspeechd=1"

	# Use pulseaudio
	GYP_DEFINES="${GYP_DEFINES} use_pulseaudio=1"

	# strip binary
	GYP_DEFINES="${GYP_DEFINES} linux_strip_binary=1"
}

set_stable_defines () {
	#http://anonscm.debian.org/gitweb/?p=pkg-chromium/pkg-chromium.git;a=blob_plain;f=debian/rules;hb=HEAD

	# Disable SSE2
	GYP_DEFINES="disable_sse2=1"

	#Debian Chromium Api Key
	#GYP_DEFINES="${GYP_DEFINES} google_api_key=''"
	#GYP_DEFINES="${GYP_DEFINES} google_default_client_id=''"
	#GYP_DEFINES="${GYP_DEFINES} google_default_client_secret=''"

	# Enable all codecs for HTML5 in chromium, depending on which ffmpeg sumo lib
	# is installed, the set of usable codecs (at runtime) will still vary
	GYP_DEFINES="${GYP_DEFINES} proprietary_codecs=1"

	# enable compile-time dependency on gnome-keyring
	GYP_DEFINES="${GYP_DEFINES} use_gnome_keyring=1 linux_link_gnome_keyring=1"

	# controlling the use of GConf (the classic GNOME configuration
	# and GIO, which contains GSettings (the new GNOME config system)
	GYP_DEFINES="${GYP_DEFINES} use_gconf=1 use_gio=1"

	# disable native client (nacl)
	GYP_DEFINES="${GYP_DEFINES} disable_nacl=1"

	# do not use embedded third_party/gold as the linker.
	GYP_DEFINES="${GYP_DEFINES} linux_use_gold_binary=0 linux_use_gold_flags=0"

	# disable tcmalloc
	GYP_DEFINES="${GYP_DEFINES} linux_use_tcmalloc=0"

	# Use explicit library dependencies instead of dlopen.
	# This makes breakages easier to detect by revdep-rebuild.
	GYP_DEFINES="${GYP_DEFINES} linux_link_gsettings=1"

	GYP_DEFINES="${GYP_DEFINES} disable_nacl=1"
	GYP_DEFINES="${GYP_DEFINES} linux_use_tcmalloc=0"
	GYP_DEFINES="${GYP_DEFINES} enable_webrtc=0"
	GYP_DEFINES="${GYP_DEFINES} use_cups=1"

	if [ "x${deb_arch}" = "xarmhf" ] ; then
		GYP_DEFINES="${GYP_DEFINES} sysroot=/"
		GYP_DEFINES="${GYP_DEFINES} target_arch=arm"
		GYP_DEFINES="${GYP_DEFINES} -DUSE_EABI_HARDFLOAT"
		GYP_DEFINES="${GYP_DEFINES} v8_use_arm_eabi_hardfloat=true"
		GYP_DEFINES="${GYP_DEFINES} arm_fpu=vfpv3"
		GYP_DEFINES="${GYP_DEFINES} arm_float_abi=hard"
		GYP_DEFINES="${GYP_DEFINES} arm_thumb=1"
		GYP_DEFINES="${GYP_DEFINES} armv7=1"
		GYP_DEFINES="${GYP_DEFINES} arm_neon=0"
	fi

	GYP_DEFINES="${GYP_DEFINES} library=shared_library"

	# Always ignore compiler warnings
	GYP_DEFINES="${GYP_DEFINES} werror="

	# FFmpeg-mt
	#ifeq (1,$(USE_SYSTEM_FFMPEG))
	#GYP_DEFINES="${GYP_DEFINES} build_ffmpegsumo=0"
	#else
	GYP_DEFINES="${GYP_DEFINES} ffmpeg_branding=Chrome"
	#endif

	#$USE_SYSTEM_LIBWEBP := $(shell pkg-config 'libwebp >= 0.3.0' && echo 1 || echo 0)
	#USE_SYSTEM_LIBWEBP := 0

	# System libs
	GYP_DEFINES="${GYP_DEFINES} use_system_bzip2=1"
	GYP_DEFINES="${GYP_DEFINES} use_system_libjpeg=1"
	GYP_DEFINES="${GYP_DEFINES} use_system_libpng=1"
	#sqlite3 >= 3.6.1
	#fails with jessie: 31.0.1650.69
	#GYP_DEFINES="${GYP_DEFINES} use_system_sqlite=1"
	GYP_DEFINES="${GYP_DEFINES} use_system_libxml=1"
	GYP_DEFINES="${GYP_DEFINES} use_system_libxslt=1"
	GYP_DEFINES="${GYP_DEFINES} use_system_zlib=1"
	GYP_DEFINES="${GYP_DEFINES} use_system_libevent=1"
	GYP_DEFINES="${GYP_DEFINES} use_system_icu=0"
	GYP_DEFINES="${GYP_DEFINES} use_system_yasm=1"
	#GYP_DEFINES="${GYP_DEFINES} use_system_ffmpeg=$(USE_SYSTEM_FFMPEG)"
	GYP_DEFINES="${GYP_DEFINES} use_system_libvpx=1"
	GYP_DEFINES="${GYP_DEFINES} use_system_xdg_utils=1"
	GYP_DEFINES="${GYP_DEFINES} use_system_flac=1"
	#GYP_DEFINES="${GYP_DEFINES} use_system_libwebp=$(USE_SYSTEM_LIBWEBP)"
	GYP_DEFINES="${GYP_DEFINES} use_system_speex=1"
	GYP_DEFINES="${GYP_DEFINES} linux_link_libspeechd=1"

	# Use pulseaudio
	GYP_DEFINES="${GYP_DEFINES} use_pulseaudio=1"

	# strip binary
	GYP_DEFINES="${GYP_DEFINES} linux_strip_binary=1"
}

dl_chrome () {
	if [ ! -d /opt/chrome-src/ ] ; then
		sudo mkdir /opt/chrome-src/
		sudo chown -R $USER:$USER /opt/chrome-src
	fi

	cd /opt/chrome-src/
	wget -c http://gsdview.appspot.com/chromium-browser-official/chromium-${chrome_version}.tar.xz
	if [ -d /opt/chrome-src/src/ ] ; then
		rm -rf /opt/chrome-src/src/ || true
	fi
	tar xf chromium-${chrome_version}.tar.xz
	mv /opt/chrome-src/chromium-${chrome_version} /opt/chrome-src/src/
}

patch_chrome () {
	cd /opt/chrome-src/src/

	#https://code.launchpad.net/~chromium-team/chromium-browser/trusty-working
	patch -p1 < "${DIR}/patches/arm-crypto.patch"
	patch -p2 < "${DIR}/patches/title-bar-default-system.patch"
	patch -p2 < "${DIR}/patches/third-party-cookies-off-by-default.patch"
	patch -p2 < "${DIR}/patches/arm.patch"

	#patch -p2 < "${DIR}/patches/arm-webrtc-fix.patch"
	patch -p0 < "${DIR}/patches/skia.patch"
}

build_chrome () {
	cd /opt/chrome-src/src/
	echo "Building with: [${GYP_DEFINES}]"
	export GYP_DEFINES="${GYP_DEFINES}"

	./build/gyp_chromium
	ninja -C out/Release chrome chrome_sandbox
	#test via:
	#sudo chown root:root chrome_sandbox && sudo chmod 4755 chrome_sandbox && export CHROME_DEVEL_SANDBOX="$PWD/chrome_sandbox"
	#./chrome
}

package_chrome () {
	pkgdir="/opt/chrome-src/chromium-${chrome_version}-${deb_arch}"
	sudo mkdir -p $pkgdir || true
	cd /opt/chrome-src/src/

	sudo strip --strip-unneeded /opt/chrome-src/src/out/Release/chrome
	sudo install -D /opt/chrome-src/src/out/Release/chrome "$pkgdir/usr/lib/chromium/chromium"

	sudo install -Dm4755 -o root -g root /opt/chrome-src/src/out/Release/chrome_sandbox "$pkgdir/usr/lib/chromium/chrome-sandbox"

	sudo cp /opt/chrome-src/src/out/Release/*.pak "$pkgdir/usr/lib/chromium/"
	sudo cp /opt/chrome-src/src/out/Release/libffmpegsumo.so "$pkgdir/usr/lib/chromium/"

	sudo cp -a /opt/chrome-src/src/out/Release/locales "$pkgdir/usr/lib/chromium/"

	sudo install -Dm644 /opt/chrome-src/src/out/Release/chrome.1 "$pkgdir/usr/share/man/man1/chromium.1"

	for size in 22 24 48 64 128 256; do
		sudo install -Dm644 "/opt/chrome-src/src/chrome/app/theme/chromium/product_logo_$size.png" "$pkgdir/usr/share/icons/hicolor/${size}x${size}/apps/chromium.png"
	done

	for size in 16 32; do
		sudo install -Dm644 "/opt/chrome-src/src/chrome/app/theme/default_100_percent/chromium/product_logo_$size.png" "$pkgdir/usr/share/icons/hicolor/${size}x${size}/apps/chromium.png"
	done

	sudo install -D "${DIR}/3rdparty/chromium" "$pkgdir/usr/bin/chromium"
	sudo install -Dm644 "${DIR}/3rdparty/default" "$pkgdir/etc/chromium/default"
	sudo install -Dm644 "${DIR}/3rdparty/chromium.desktop" "$pkgdir/usr/share/applications/chromium.desktop"

	deb_arch=$(LC_ALL=C dpkg --print-architecture)
	cd $pkgdir
	sudo LANG=C tar --numeric-owner -cf /opt/chrome-src/chromium-${chrome_version}-${deb_arch}.tar .
	cd /opt/chrome-src/
	sudo chown -R $USER:$USER /opt/chrome-src/chromium-${chrome_version}-${deb_arch}.tar
	xz -z -7 -v chromium-${chrome_version}-${deb_arch}.tar
}

check_dependencies
if [ "x${use_testing}" = "xenable" ] ; then
	set_testing_defines
else
	set_stable_defines
fi
dl_chrome
patch_chrome
build_chrome
if [ -f /opt/chrome-src/src/out/Release/chrome ] ; then
	package_chrome
fi
#
