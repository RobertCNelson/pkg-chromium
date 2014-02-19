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

chrome_version_original="32.0.1700.102"
chrome_version_delta="33.0.1750.112"

dl_chrome () {
	if [ ! -d /opt/chrome-src/ ] ; then
		sudo mkdir /opt/chrome-src/
		sudo chown -R $USER:$USER /opt/chrome-src
	fi

	cd /opt/chrome-src/
	wget -c http://gsdview.appspot.com/chromium-browser-official/chromium-${chrome_version_original}.tar.xz
	wget -c http://gsdview.appspot.com/chromium-browser-official/chromium-${chrome_version_delta}.tar.xz
	if [ -d /opt/chrome-src/delta/ ] ; then
		rm -rf /opt/chrome-src/delta/ || true
	fi
	tar xf chromium-${chrome_version_original}.tar.xz
	tar xf chromium-${chrome_version_delta}.tar.xz
	mv /opt/chrome-src/chromium-${chrome_version_original} /opt/chrome-src/delta/
	cd /opt/chrome-src/delta/
	git init .
	echo "*.xtb" > .gitignore
	echo "*.png" >> .gitignore
	git add --all
	git commit --allow-empty -a -m 'original'
	cd /opt/chrome-src/
	cp -r /opt/chrome-src/chromium-${chrome_version_delta}/* /opt/chrome-src/delta/
}

dl_chrome
