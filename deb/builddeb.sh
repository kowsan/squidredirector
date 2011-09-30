#!/bin/sh
sudo checkinstall --install=no  --pkgname=squidredirector --pkgversion=0.1 --pkglicense=LGPL --pkggroup=petrosoft --pakdir=deb --nodoc --strip=yes --requires="libqt4-sql-psql" --arch=i386 --maintainer=dev@petrosoft.su --pkgrelease=0.1
