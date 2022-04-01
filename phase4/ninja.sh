# Ninja Phase 4
export NINJAJOBS=4

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
    ./ninja_test --gtest_filter=-SubprocessTest.SetWithLots
    set -e
fi

install -m755 ninja /usr/bin/
install -Dm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -Dm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja

