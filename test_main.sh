#!/usr/bin/env bash

LOCAL_GRADLE_REPO=""

setup() {
    ORIG_WD=$(pwd)
    source ./gradle-tab-completion.bash
    CASHE_FILE="testCache"
    if [[ $LOCAL_GRADLE_REPO == "" ]];then
        echo INITIALISATION FAIL:
        echo LOCAL_GRADLE_REPO not set
        exit 1
    fi
}

teardown() {
    cd $ORIG_WD
    rm -f ./gradlew
    rm -f ./build.gradle
    rm -f $CASHE_FILE
}

test__should_support_default_gradle_installation() {

    local result=$(getGradleCommand)

    assertEquals 'gradle' $result
}

test__should_support_gradle_wrapper() {
    touch ./gradlew
    chmod +x ./gradlew

    local result=$(getGradleCommand)

    assertEquals './gradlew' $result
}

testLarge__should_allow_requesting_tasks_from_gradle() {
    cd $LOCAL_GRADLE_REPO

    result=$(requestTasksFromGradle)

    assertEquals 'assemble build buildDependents buildNeeded classes clean jar testClasses init wrapper javadoc buildEnvironment components dependencies dependencyInsight dependentComponents help model projects properties tasks check test' "$result"
}

test__should_get_tasks_from_a_heading_in_task_output() {
    result=$(parseGradleTaskOutput "$(cat ./t/tasks-one-heading.out)")

    assertEquals 'assemble build buildDependents buildNeeded classes clean j9Classes jar testClasses' "$result"
}

test__should_handle_multiple_headings_and_noise_in_task_output() {
    result=$(parseGradleTaskOutput "$(cat ./t/tasks-full.out)")

    exp='assemble build buildDependents buildNeeded classes clean j9Classes jar testClasses init wrapper javadoc buildEnvironment components dependencies dependencyInsight dependentComponents help model projects properties tasks cleanEclipse cleanIdea eclipse idea uploadArchives check test backport compressTests deploy deployDownloadedArtifacts deploySpeechAdi deploySpeechRevo dialogTests'
    if [[ $result != $exp ]]; then
        fail "expected: '$exp'\n    got: '$result'"
    fi
}

test__should_be_able_to_read_values_from_cache() {
    cd $LOCAL_GRADLE_REPO
    local cwd=$(pwd)
    local hashString=$(getGradleChangesHash)
    local tasks="tasks build etc"
    echo "$cwd|$hashString|$commands" > $CASHE_FILE
    # Add another line with the same hash to make sure the dir is respected
    echo "./other/dir|$hashString|$commands" >> $CASHE_FILE

    local result=$(readCacheForCwd)

    IFS='|' read -ra resultArray <<< "$result"
    assertEquals $cwd ${resultArray[0]}
    assertEquals $hashString ${resultArray[1]}
    assertEquals $commands ${resultArray[2]}
}

test_readCacheForCwd_shouldReturnEmptyOnError() {
    local result=$(readCacheForCwd)

    assertEquals '' $result
}

test_should_read_and_write_from_cache_correctly() {
    tasks='testA testB btest module:project'
    writeTasksToCache $tasks

    result=$(getGradleTasksFromCache)

    assertEquals "$tasks" "$result"
}

test__should_overwrite_cache_with_the_same_path() {
    touch ./build.gradle
    tasks="testA testB btest"

    writeTasksToCache $tasks
    writeTasksToCache $tasks

    local cwd=$(pwd)
    local pathCount=0
    while read cacheLine || [[ -n $cacheLine ]]; do
        if [[ $cacheLine == "$cwd"* ]]; then
            ((pathCount++))
        fi
    done <<< $CASHE_FILE

    if [[ $pathCount > 1 ]]; then
        fail "expectedc 1 cache recort, got '$pathCount'"
    fi
}

test_should_invalidate_cache_when_file_content_changes() {
    touch ./build.gradle
    writeTasksToCache "testA testB btest"

    echo "//something" >> ./build.gradle # changing file content which should invalidate the cache
    result=$(getGradleTasksFromCache)

    assertEquals '' "$result"
}
