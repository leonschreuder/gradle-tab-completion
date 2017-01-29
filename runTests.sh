#!/usr/bin/env bash

callEveryTest() {

    TEST_FILE_COUNT=0
    FAILING_TESTS=0

    for test_file in ./test_*; do
        log "running $test_file"
        ((TEST_FILE_COUNT++))

        # Load the test files in a sub-shell, to prevent redefinition problems
        (
            source $test_file

            for currFunc in `compgen -A function`
            do
                if [[ $currFunc == "test_"* ]]; then
                    callTest $currFunc
                elif [[ $RUN_LARGE_TESTS && $currFunc == "testLarge_"* ]]; then
                    callTest $currFunc
                fi
            done

            # since we dont have access to the outer shell, let the return
            # code be the error count.
            exit $FAILING_TESTS_IN_FILE
        )

        failedTestReturned=$?
        if [[ $failedTestReturned > 0 ]]; then
            ((FAILING_TESTS+=$failedTestReturned))
        fi
    done

    if [[ $FAILING_TESTS > 0 ]]; then
        echo $FAILING_TESTS failing tests in $TEST_FILE_COUNT files
        echo TEST SUITE FAILED
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

callTest() {
    testFunc=$1
    log "  $testFunc"
    callIfExists setup
    eval $testFunc

    if [ $? != 0 ]; then
        ((FAILING_TESTS_IN_FILE++))
    fi
    callIfExists teardown
}

fail() {
    failFromStackDepth 1 "$1"
}

# allows specifyng the call-stack depth at which the error was thrown
failFromStackDepth() {
    printf "FAIL: $test_file(${BASH_LINENO[$1-1]}) > ${FUNCNAME[$1]}\n"
    printf "    $2\n"
    callIfExists teardown

    ((FAILING_TESTS_IN_FILE++))
}

assertEquals() {
    if [[ $1 != $2 ]]; then
        maxSizeForMultiline=30
        if [[ "${#1}" -gt $maxSizeForMultiline || ${#2} -gt $maxSizeForMultiline ]]; then
            failFromStackDepth 2 "expected: '$1'\n    got:      '$2'"
        else
            failFromStackDepth 2 "expected '$1', got '$2'"
        fi
    fi
}

log() {
    if [ $VERBOSE ]; then
        echo "$1"
    fi
}

usage() {
    echo " This script loads all files in this folder that are prefixed with "
    echo " 'test_', and then executes all functions that are prefixed with   "
    echo " 'test_' in those files. Large (intergration) tests are prefixed   "
    echo " with 'testLarge_' and are only executed with the -a flag.         "
    echo ""
    echo "Usage:"
    echo "-h    Print this help"
    echo "-v    verbose"
    echo "-a    Run all tests, including those prefixed with testLarge_"
    exit
}


# Main
#============================================================

# adding : behind the command will require arguments
while getopts "vha" opt; do
    case $opt in
        h)
            usage
            ;;
        v)
            export VERBOSE=true
            ;;
        a)
            export RUN_LARGE_TESTS=true
            ;;
        *)
            usage
            ;;
    esac
done

callEveryTest
