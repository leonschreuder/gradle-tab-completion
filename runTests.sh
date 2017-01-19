#!/usr/bin/env bash

callEveryTest() {

    suiteFailed=false

    for test_file in ./test_*
    do
        log "running $test_file"
        # Load the test files in a sub-shell, to prevent redefinition problems
        (
            testFileFailed=false
            source $test_file

            callIfExists setup

            for t in `compgen -A function`
            do
                if [[ $t == "test_"* ]]; then
                    log "  $t"
                    eval $t

                    if [ $? != 0 ]; then
                        testFileFailed=true
                        break
                    fi
                fi
            done

            callIfExists teardown

            if [ $testFileFailed == true ]; then
                echo "FAIL!!"
                exit 1
            fi

        )
        if [ $? != 0 ]; then
            suiteFailed=true
            break
        fi
    done

    if [ $suiteFailed == true ]; then
        echo suite failed
    else
        echo suite successfull
    fi


}

# Helper functions

callIfExists() {
    declare -F -f $1 > /dev/null
    if [ $? == 0 ]; then
        $1
    fi
}

fail() {
    echo "FAIL: ${FUNCNAME[1]} >"
    echo "   $1"
    callIfExists teardown
    exit 1
}

log() {
    if [ $VERBOSE ]; then
        echo "$1"
    fi
}

usage() {
    echo "This script loads all files in this folder that are "
    echo "prefixed with 'test_', and then executes all        "
    echo "functions that are prefixed with 'test_' in those   "
    echo "files.                                              "
    echo ""
    echo "Usage:"
    echo "-h    Print this help"
    echo "-v    verbose"
    exit
}


# Main
#============================================================

# adding : behind the command will require arguments
while getopts "vh" opt; do
    case $opt in
        h)
            usage
            ;;
        v)
            export VERBOSE=true
            ;;
        *)
            usage
            ;;
    esac
done

callEveryTest
