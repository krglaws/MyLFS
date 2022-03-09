#!/usr/bin/env bash
# Perl Stage 5
# ~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep PERL $PACKAGE_LIST)"
PKG_PERL=$(basename $PKG_PERL)

tar -xf $PKG_PERL
cd ${PKG_PERL%.tar*}

sh Configure -des                                        \
             -Dprefix=/usr                               \
             -Dvendorprefix=/usr                         \
             -Dprivlib=/usr/lib/perl5/5.34/core_perl     \
             -Darchlib=/usr/lib/perl5/5.34/core_perl     \
             -Dsitelib=/usr/lib/perl5/5.34/site_perl     \
             -Dsitearch=/usr/lib/perl5/5.34/site_perl    \
             -Dvendorlib=/usr/lib/perl5/5.34/vendor_perl \
             -Dvendorarch=/usr/lib/perl5/5.34/vendor_perl

make
make install

cd /sources
rm -rf ${PKG_PERL%.tar*}

