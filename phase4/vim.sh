# Vim Phase 4
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h

./configure --prefix=/usr

make

if $RUN_TESTS
then
    set +e
    chown -R tester .
    sed '/test_plugin_glvs/d' -i src/testdir/Make_all.mak
    su tester -c "TERM=xterm-256color LANG=en_US.UTF-8 make -j1 test" \
       &> vim-test.log
    set -e
fi

make install

ln -sv ../vim/vim91/doc /usr/share/doc/vim-9.1.1629
