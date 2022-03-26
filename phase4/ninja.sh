#!/usr/bin/env bash
# Ninja Stage 6
# ~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep NINJA $PACKAGE_LIST)"
PKG_NINJA=$(basename $PKG_NINJA)

tar -xf $PKG_NINJA
cd ${PKG_NINJA%.tar*}

sed -i '/int Guess/a \
  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
' src/ninja.cc

python3 configure.py --bootstrap

if $RUN_TESTS
then
    set +e
    ./ninja ninja_test
    ./ninja_test --gtest_filter=-SubprocessTest.SetWithLots &> $TESTLOG_DIR/ninja.log
    set -e
fi

install -m755 ninja /usr/bin/
install -Dm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -Dm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja

cd /sources
rm -rf ${PKG_NINJA%.tar*}

