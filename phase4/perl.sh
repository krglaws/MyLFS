#!/usr/bin/env bash
# Perl Stage 6
# ~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep PERL $PACKAGE_LIST)"
PKG_PERL=$(basename $PKG_PERL)
PATCH_PERL=$(basename $PATCH_PERL)

tar -xf $PKG_PERL
cd ${PKG_PERL%.tar*}

patch -Np1 -i ../$PATCH_PERL

export BUILD_ZLIB=False
export BUILD_BZIP2=0

sh Configure -des                                         \
             -Dprefix=/usr                                \
             -Dvendorprefix=/usr                          \
             -Dprivlib=/usr/lib/perl5/5.34/core_perl      \
             -Darchlib=/usr/lib/perl5/5.34/core_perl      \
             -Dsitelib=/usr/lib/perl5/5.34/site_perl      \
             -Dsitearch=/usr/lib/perl5/5.34/site_perl     \
             -Dvendorlib=/usr/lib/perl5/5.34/vendor_perl  \
             -Dvendorarch=/usr/lib/perl5/5.34/vendor_perl \
             -Dman1dir=/usr/share/man/man1                \
             -Dman3dir=/usr/share/man/man3                \
             -Dpager="/usr/bin/less -isR"                 \
             -Duseshrplib                                 \
             -Dusethreads

make

if $RUN_TESTS
then
    set +e
    make test &> $TESTLOG_DIR/perl.log
    set -e
fi

make install

cd /sources
rm -rf ${PKG_PERL%.tar*}

