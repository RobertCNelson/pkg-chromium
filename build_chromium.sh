#!/bin/bash -e
#
# Copyright (c) 2014-2015 Robert Nelson <robertcnelson@gmail.com>
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
chrome_version="40.0.2214.91"

unset use_testing
if [ -f ${DIR}/testing ] ; then
	chrome_version="40.0.2214.91"
	use_testing=enable
	testing_label="40"
fi

check_dpkg () {
	LC_ALL=C dpkg --list | awk '{print $2}' | grep "^${pkg}$" >/dev/null || deb_pkgs="${deb_pkgs}${pkg} "
}

check_dependencies () {
	unset deb_pkgs
	pkg="bison"
	check_dpkg
	pkg="build-essential"
	check_dpkg
	pkg="clang"
	check_dpkg
	pkg="gperf"
	check_dpkg
	pkg="libgtk2.0-dev"
	check_dpkg

	pkg="libgconf2-dev"
	check_dpkg
	pkg="libgcrypt11-dev"
	check_dpkg
	pkg="libgnome-keyring-dev"
	check_dpkg
	pkg="libpci-dev"
	check_dpkg
	pkg="libkrb5-dev"
	check_dpkg
	pkg="libspeechd-dev"
	check_dpkg
	pkg="pkg-config"
	check_dpkg
	pkg="yasm"
	check_dpkg

	deb_arch=$(LC_ALL=C dpkg --print-architecture)
	pkg="libasound2-dev:${deb_arch}"
	check_dpkg
	pkg="libudev-dev:${deb_arch}"
	check_dpkg
	pkg="libpulse-dev:${deb_arch}"
	check_dpkg
	pkg="libxml2-dev:${deb_arch}"
	check_dpkg
	pkg="libxss-dev:${deb_arch}"
	check_dpkg
	pkg="libxtst-dev:${deb_arch}"
	check_dpkg

	#chrome_version="32.0.1700.76"
	pkg="libcap-dev:${deb_arch}"
	check_dpkg

	#chrome_version="33.0.1750.112"
	pkg="jython"
	check_dpkg

	#chrome_version="34.0.1847.116"
	pkg="libexif-dev"
	check_dpkg

	deb_distro=$(lsb_release -cs | sed 's/\//_/g')
	case "${deb_distro}" in
	jessie|sid)
		pkg="libcups2-dev:${deb_arch}"
		check_dpkg
		#chrome_version="32.0.1700.76"
		pkg="libdrm-dev:${deb_arch}"
		check_dpkg

		pkg="libnss3-dev:${deb_arch}"
		check_dpkg
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
# treat all warnings as errors
defines="werror= "

# use clang instead of gcc
defines+="clang=1 "
defines+="clang_use_chrome_plugins= "

# disabled features
defines+="use_ozone=0 \
use_gconf=0 \
use_allocator=none \
linux_breakpad=0 \
linux_use_libgps=0 \
linux_use_gold_flags=0 \
linux_use_bundled_gold=0 \
linux_use_bundled_binutils=0 \
remoting=0 \
disable_nacl=1 \
enable_remoting_host=0 "

# enabled features
defines+="enable_webrtc=1 \
use_gio=1 \
use_pulseaudio=1 \
use_gnome_keyring=1 \
linux_link_libpci=1 \
linux_link_gsettings=1 \
linux_link_libspeechd=1 \
linux_link_gnome_keyring=1 "

# system libraries to use
defines+="use_system_re2=1 \
use_system_yasm=1 \
use_system_opus=1 \
use_system_zlib=1 \
use_system_speex=1 \
use_system_expat=1 \
use_system_snappy=1 \
use_system_libpng=1 \
use_system_libxml=1 \
use_system_libjpeg=1 \
use_system_libwebp=1 \
use_system_libxslt=1 \
use_system_libsrtp=1 \
use_system_jsoncpp=1 \
use_system_libevent=1 \
use_system_harfbuzz=1 \
use_system_xdg_utils=1 "

# enable proprietary codecs
defines+="proprietary_codecs=1 \
ffmpeg_branding=Chrome "

# use embedded protobuf for now (bug #764911)
defines+="use_system_protobuf=0 "

# icu
defines+="use_system_icu=0 "
#icu_use_data_file_flag=0 \
#want_separate_host_toolset=0 \

defines+="sysroot=/ \
target_arch=arm \
use_cups=1 \
arm_version=7 \
arm_neon=1 \
arm_float_abi=hard \
arm_thumb=1 \
library=shared_library "

defines+="enable_background=0 \
enable_google_now=0 \
enable_hangout_services_extension=0 "

}

set_stable_defines () {
# treat all warnings as errors
defines="werror= "

# use clang instead of gcc
defines+="clang=1 "
defines+="clang_use_chrome_plugins= "

# disabled features
defines+="use_ozone=0 \
use_gconf=0 \
use_allocator=none \
linux_breakpad=0 \
linux_use_libgps=0 \
linux_use_gold_flags=0 \
linux_use_bundled_gold=0 \
linux_use_bundled_binutils=0 \
remoting=0 \
disable_nacl=1 \
enable_remoting_host=0 "

# enabled features
defines+="enable_webrtc=1 \
use_gio=1 \
use_pulseaudio=1 \
use_gnome_keyring=1 \
linux_link_libpci=1 \
linux_link_gsettings=1 \
linux_link_libspeechd=1 \
linux_link_gnome_keyring=1 "

# system libraries to use
defines+="use_system_re2=1 \
use_system_yasm=1 \
use_system_opus=1 \
use_system_zlib=1 \
use_system_speex=1 \
use_system_expat=1 \
use_system_snappy=1 \
use_system_libpng=1 \
use_system_libxml=1 \
use_system_libjpeg=1 \
use_system_libwebp=1 \
use_system_libxslt=1 \
use_system_libsrtp=1 \
use_system_jsoncpp=1 \
use_system_libevent=1 \
use_system_harfbuzz=1 \
use_system_xdg_utils=1 "

# enable proprietary codecs
defines+="proprietary_codecs=1 \
ffmpeg_branding=Chrome "

# use embedded protobuf for now (bug #764911)
defines+="use_system_protobuf=0 "

# icu
defines+="use_system_icu=0 "
#icu_use_data_file_flag=0 \
#want_separate_host_toolset=0 \

defines+="sysroot=/ \
target_arch=arm \
use_cups=1 \
arm_version=7 \
arm_neon=1 \
arm_float_abi=hard \
arm_thumb=1 \
library=shared_library "

defines+="enable_background=0 \
enable_google_now=0 \
enable_hangout_services_extension=0 "

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

	#chrome_version="33.0.1750.112"
	#patch -p1 < "${DIR}/patches/arm-crypto.patch"

	#patch -p2 < "${DIR}/patches/third-party-cookies-off-by-default.patch"
	#patch -p2 < "${DIR}/patches/arm.patch"

	#chrome_version="32.0.1700.76"
	#patch -p0 < "${DIR}/patches/skia.patch"

	#chrome_version="33.0.1750.112"
	#patch -p1 < "${DIR}/patches/fix-build-gyp_chromium-rungn.patch"
}

build_chrome () {
	if [ ! -d /run/shm ] ; then
		mkdir -p /run/shm
	fi

	#chrome_version="32.0.1700.76"
	sudo mount -t tmpfs shmfs -o size=256M /dev/shm

	cd /opt/chrome-src/src/

	echo "GYP_DEFINES=\"${defines}\""

	GYP_DEFINES="${defines}" ./build/gyp_chromium

	ninja -C out/Release chrome chrome_sandbox chromedriver
	#test via:
	#sudo chown root:root chrome_sandbox && sudo chmod 4755 chrome_sandbox && export CHROME_DEVEL_SANDBOX="$PWD/chrome_sandbox"
	#./chrome

	#chrome_version="32.0.1700.76"
	sudo umount -l /dev/shm || true
}

package_chrome () {
	deb_arch=$(LC_ALL=C dpkg --print-architecture)
	if [ -f /opt/chrome-src/chromium-${chrome_version}-${deb_arch}.tar ] ; then
		sudo rm -f /opt/chrome-src/chromium-${chrome_version}-${deb_arch}.tar || true
	fi

	if [ -f /opt/chrome-src/chromium-${chrome_version}-${deb_arch}.tar.xz ] ; then
		sudo rm -f /opt/chrome-src/chromium-${chrome_version}-${deb_arch}.tar.xz || true
	fi

	if [ -f /opt/chrome-src/chromium-${chrome_version}-${deb_arch}-${testing_label}.tar.xz ] ; then
		sudo rm -f /opt/chrome-src/chromium-${chrome_version}-${deb_arch}-${testing_label}.tar.xz || true
	fi

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

	cd $pkgdir
	sudo LANG=C tar --numeric-owner -cf /opt/chrome-src/chromium-${chrome_version}-${deb_arch}.tar .
	cd /opt/chrome-src/
	sudo chown -R $USER:$USER /opt/chrome-src/chromium-${chrome_version}-${deb_arch}.tar
	xz -z -7 -v chromium-${chrome_version}-${deb_arch}.tar

	if [ "x${use_testing}" = "xenable" ] ; then
		mv chromium-${chrome_version}-${deb_arch}.tar.xz chromium-${chrome_version}-${deb_arch}-${testing_label}.tar.xz
	fi
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
