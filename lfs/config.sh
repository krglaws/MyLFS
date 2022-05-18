_PHASESCOUNT=5
#_PHASES=(phase1, phase2, phase3, phase4, phase5)

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
    local FILES=$(find ./$EXTENSIONNAME/static | grep ./$EXTENSIONNAME/static/ | sed "s/\.\/$EXTENSIONNAME\/static\///g");
    for i in ${FILES[@]}; do
        local FULLPATH="$LFS/$i";
        mkdir -p $(dirname $FULLPATH) 
        if ! [ -d $FULLPATH ]; then      
            cp -f ./$EXTENSIONNAME/static/$i $FULLPATH
        fi
    done
    #Copy Templates Files
    local FILES=$(find ./$EXTENSIONNAME/templates | grep ./$EXTENSIONNAME/templates/ | sed "s/\.\/$EXTENSIONNAME\/templates\///g");
    for i in ${FILES[@]}; do
        local FULLPATH="$LFS/$i";
        mkdir -p $(dirname $FULLPATH) 
        if ! [ -d $FULLPATH ]; then      
            cat ./$EXTENSIONNAME/templates/$i | envsubst > $FULLPATH
        fi
    done
}

function run_after_phase3 {
    rm -rf $LFS/usr/share/{info,man,doc}/*
    find $LFS/usr/{lib,libexec} -name \*.la -delete
    rm -rf $LFS/tools
}

function run_after_phase5 {
    # final cleanup
   rm -rf $LFS/tmp/*
   find $LFS/usr/lib $LFS/usr/libexec -name \*.la -delete
   find $LFS/usr -depth -name $LFS_TGT\* | xargs rm -rf
   rm -rf $LFS/home/tester
   sed -i 's/^.*tester.*$//' $LFS/etc/{passwd,group}
}