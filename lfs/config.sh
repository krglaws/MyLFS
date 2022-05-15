_PHASESCOUNT=4
#_PHASES=(phase1, phase2, phase3, phase4)

#Script will search for 2 functions:
#
#   run_before_{PHASENAME}
#   and
#   run_after_{PHASENAME}
#
#   those functions will be runned before and after each execution
#   if function is not exists - it will skip
#
function run_before_phase1 {
    #Copy Static to folder
    local FILES=$(find ./$SECTION/static | grep ./$SECTION/static/ | sed "s/\.\/$SECTION\/static\///g");
    for i in ${FILES[@]}; do
        local FULLPATH="$LFS/$i";
        mkdir -p $(dirname $FULLPATH) 
        if ! [ -d $FULLPATH ]; then      
            cp -f ./$SECTION/static/$i $FULLPATH
        fi
    done
    #Copy Templates Files
    local FILES=$(find ./$SECTION/templates | grep ./$SECTION/templates/ | sed "s/\.\/$SECTION\/templates\///g");
    for i in ${FILES[@]}; do
        local FULLPATH="$LFS/$i";
        mkdir -p $(dirname $FULLPATH) 
        if ! [ -d $FULLPATH ]; then      
            cat ./$SECTION/templates/$i | envsubst > $FULLPATH
        fi
    done
}

function run_after_phase3 {
    rm -rf $LFS/usr/share/{info,man,doc}/*
    find $LFS/usr/{lib,libexec} -name \*.la -delete
    rm -rf $LFS/tools
}
