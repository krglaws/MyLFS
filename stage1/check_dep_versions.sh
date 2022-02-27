#!/usr/bin/bash
# Script to check build dependencies
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# This is likely to break on many machines.
# If it does, just manually check that you have
# the right dependencies and versions according
# to the listing in LFS 11.0, Chapter 2.2.

EXIT_STATUS=0

function compare_version {
    local MINVERS=$1
    local CURRVERS=$2
    local NDIGS=$(echo $MINVERS | tr . ' ' | wc -w)

    for ((FIELD=1; FIELD < NDIGS; FIELD++))
    do
        MINDIGIT=$(echo $MINVERS | cut -d"." -f$FIELD)
        CURRDIGIT=$(echo $CURRVERS | cut -d"." -f$FIELD)
        if [ "$CURRDIGIT" -gt "$MINDIGIT" ]
        then
            return 0
        elif [ "$CURRDIGIT" -eq "$MINDIGIT" ]
        then
            continue
        else
            return -1
        fi
    done

    return 0
}

function check_dependency {
    local PROG=$1
    local MINVERS=$2
    local CURRVERSFIELD=$3

    if ! command -v $PROG 1>/dev/null
    then
        echo "ERROR: '$PROG' not found"
        return -1
    fi

    CURRVERS=$($PROG --version 2>&1 | head -n1 | cut -d" " -f$CURRVERSFIELD | cut -d"(" -f1 | cut -d"," -f1 | cut -d"-" -f1)
    CURRVERS=${CURRVERS%"${CURRVERS##*[0-9]}"}

    if ! compare_version "$MINVERS" "$CURRVERS"
    then
        echo "ERROR: $PROG $CURRVERS does not satisfy minimum version $MINVERS"
    else
        echo "$PROG $CURRVERS"
    fi
}

if ! check_dependency bash       3.2     4; then EXIT_STATUS=-1; fi
if ! check_dependency ld         2.25    7; then EXIT_STATUS=-1; fi  # binutils
if ! check_dependency bison      2.7     4; then EXIT_STATUS=-1; fi
if ! check_dependency bzip2      1.0.4   8; then EXIT_STATUS=-1; fi
if ! check_dependency chown      6.9     4; then EXIT_STATUS=-1; fi  # coreutils
if ! check_dependency diff       2.8.1   4; then EXIT_STATUS=-1; fi
if ! check_dependency find       4.2.31  4; then EXIT_STATUS=-1; fi
if ! check_dependency gawk       4.0.1   3; then EXIT_STATUS=-1; fi
if ! check_dependency gcc        6.2     4; then EXIT_STATUS=-1; fi
if ! check_dependency g++        6.2     4; then EXIT_STATUS=-1; fi
if ! check_dependency ldd        2.11    5; then EXIT_STATUS=-1; fi  # glibc
if ! check_dependency grep       1.3.12  4; then EXIT_STATUS=-1; fi
if ! check_dependency gzip       1.3.12  2; then EXIT_STATUS=-1; fi
if ! check_dependency m4         1.4.10  4; then EXIT_STATUS=-1; fi
if ! check_dependency make       4.0     3; then EXIT_STATUS=-1; fi
if ! check_dependency patch      2.5.4   3; then EXIT_STATUS=-1; fi
if ! check_dependency python3    3.4     2; then EXIT_STATUS=-1; fi
if ! check_dependency sed        4.1.5   4; then EXIT_STATUS=-1; fi
if ! check_dependency tar        1.22    4; then EXIT_STATUS=-1; fi
if ! check_dependency makeinfo   4.7     4; then EXIT_STATUS=-1; fi  # texinfo
if ! check_dependency xz         5.0.0   4; then EXIT_STATUS=-1; fi

# check that yacc is a link to bison
if [ ! -h /usr/bin/yacc -a "$(readlink -f /usr/bin/yacc)"="/usr/bin/bison.yacc" ]
then
    echo "ERROR: /usr/bin/yacc needs to be a link to /usr/bin/bison.yacc"
    EXIT_STATUS=-1
else
    echo "/usr/bin/yacc -> /usr/bin/bison.yacc"
fi

# check that awk is a link to gawk
if [ ! -h /usr/bin/awk -a "$(readlink -f /usr/bin/awk)"="/usr/bin/gawk" ]
then
    echo "ERROR: /usr/bin/awk needs to be a link to /usr/bin/gawk"
    EXIT_STATUS=-1
else
    echo "/usr/bin/awk -> /usr/bin/gawk"
fi

# check linux version
MIN_LINUX_VERS=3.2
LINUX_VERS=$(cat /proc/version | head -n1 | cut -d" " -f3 | cut -d"-" -f1)
if ! compare_version "$MIN_LINUX_VERSION" "$LINUX_VERS"
then
    echo "ERROR: Linux kernel version '$LINUX_VERS' does not satisfy minium version $MIN_LINUX_VERS"
    EXIT_STATUS=-1
else
    echo "Linux kernel version $LINUX_VERS"
fi

# check perl version
MIN_PERL_VERS=5.8.8
PERL_VERS=$(perl -V:version | cut -d"'" -f2)
if ! compare_version "$MIN_PERL_VERS" "$PERL_VERS"
then
    echo "ERROR: Perl version '$PERL_VERS' does not satisfy minium version $MIN_PERL_VERS"
    EXIT_STATUS=-1
else
    echo "Perl version $PERL_VERS"
fi

# check G++ compilation
echo 'int main(){}' > dummy.c && g++ -o dummy dummy.c
if [ -x dummy ]
then
    echo "g++ compilation OK"
else
    echo "ERROR: g++ compilation failed"
    EXIT_STATUS=-1
fi
rm -f dummy.c dummy

exit $EXIT_STATUS
