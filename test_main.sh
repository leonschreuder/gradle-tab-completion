#!/usr/bin/env bash

setup() {
    source ./gradle-tab-completion.bash
}

teardown() {
    rm -f ./gradlew
}

test_getGradleCommand_ShouldDefaultToGradleInstallation() {

    result=$(getGradleCommand)

    exp='gradle'
    if [[ $result != $exp ]]; then
        fail "expected '$exp', got '$result'"
    fi
}

test_getGradleCommand_ShouldSupportLocalGradleWrapper() {
    touch ./gradlew
    chmod +x ./gradlew

    result=$(getGradleCommand)

    exp='./gradlew'
    if [[ $result != $exp ]]; then
        fail "expected '$exp', got '$result'"
    fi
}
