#!/usr/bin/env bash
# Vim Stage 6
# ~~~~~~~~~~~
set -e

cd /sources

eval "$(grep VIM $PACKAGE_LIST)"
PKG_VIM=$(basename $PKG_VIM)

tar -xf $PKG_VIM
cd ${PKG_VIM%.tar*}

echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h

./configure --prefix=/usr

make

chown -Rv tester .

su tester -c "LANG=en_US.UTF-8 make -j1 test" &> vim-test.log

make install

cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF

cd /sources
rm -rf ${PKG_VIM%.tar*}

