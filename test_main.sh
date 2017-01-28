#!/usr/bin/env bash

LOCAL_GRADLE_REPO='/Users/leonmoll/repos/java/code-wars/'
LOCAL_TASKS='init wrapper buildEnvironment components dependencies dependencyInsight dependentComponents help model projects properties tasks'
LOCAL_FLAGS='-? -h --help -a --no-rebuild -b --build-file -c --settings-file --configure-on-demand --console --continue -D --system-prop -d --debug --daemon --foreground -g --gradle-user-home --gui -I --init-script -i --info --include-build -m --dry-run --max-workers --no-daemon --offline -P --project-prop -p --project-dir --parallel --profile --project-cache-dir -q --quiet --recompile-scripts --refresh-dependencies --rerun-tasks -S --full-stacktrace -s --stacktrace --status --stop -t --continuous -u --no-search-upward -v --version -x --exclude-task'


setup() {
    ORIG_WD=$(pwd)
    source ./gradle-tab-completion.bash
    CASHE_FILE="testCache"
    if [[ $LOCAL_GRADLE_REPO == "" || $LOCAL_TASKS == "" || $LOCAL_FLAGS == "" ]];then
        printf "INITIALISATION FAIL:\nLocal test varibles not set" && exit 1
    fi
}

teardown() {
    rm -f $CASHE_FILE

    # dont remove dummy files if we changed into the local repo
    if [[ $CHANGED_DIR == false ]]; then
        rm -f ./gradlew
        rm -f ./build.gradle
    fi
    cd $ORIG_WD
    CHANGED_DIR=false
}

testLarge__should_request_commands_from_gradle_when_no_cache_available() {
    lcd $LOCAL_GRADLE_REPO

    result=$(getCommandsForCurrentPrefix)

    assertEquals "$LOCAL_TASKS $LOCAL_FLAGS" "$result"
}

testLarge__should_read_commands_from_cache_when_available() {
    tasks='testA testB btest module:project'
    writeTasksToCache "$tasks"

    result=$(getCommandsForCurrentPrefix)

    assertEquals "$tasks" "$result"
}

test__should_hide_commands_with_dash() {
    tasks='testA testB btest module:project'
    commands="$tasks -h -? --help --version"
    writeTasksToCache "$commands"

    result=$(getCommandsForCurrentPrefix)

    assertEquals "$tasks" "$result"
}

test__should_hide_double_dash_commands_when_current_prefix_is_dash() {
    commands='testA btest module:project -h -? --help --version testB'
    writeTasksToCache "$commands"

    result=$(getCommandsForCurrentPrefix '-')

    assertEquals "-h -?" "$result"
}


test_should_read_and_write_from_cache_correctly() {
    tasks='testA testB btest module:project'
    writeTasksToCache $tasks

    result=$(getCommandsFromCache)

    assertEquals "$tasks" "$result"
}

test_should_invalidate_cache_when_file_content_changes() {
    touch ./build.gradle
    writeTasksToCache "testA testB btest"

    echo "//something" >> ./build.gradle # changing file content which should invalidate the cache
    result=$(getCommandsFromCache)

    assertEquals '' "$result"
}

test__should_be_able_to_read_values_from_cache() {
    lcd $LOCAL_GRADLE_REPO
    local cwd=$(pwd)
    local hashString=$(getGradleChangesHash)
    local tasks="tasks build etc"
    local flags="-h -f"
    local doubleFlags="--help --file"
    echo "$cwd|$hashString|$tasks|$flags|$doubleFlags" > $CASHE_FILE
    # Add another line with the same hash to make sure the dir is respected
    echo "./other/dir|$hashString|$tasks" >> $CASHE_FILE

    local result=$(readCacheForCwd)

    IFS='|' read -ra resultArray <<< "$result"
    assertEquals "$cwd" "${resultArray[0]}"
    assertEquals "$hashString" "${resultArray[1]}"
    assertEquals "$tasks" "${resultArray[2]}"
    assertEquals "$flags" "${resultArray[3]}"
    assertEquals "$doubleFlags" "${resultArray[4]}"
}

test__reading_from_empty_cache_should_return_empty_string() {
    local result=$(readCacheForCwd)

    assertEquals '' $result
}


testLarge__should_allow_requesting_tasks_from_gradle() {
    lcd $LOCAL_GRADLE_REPO

    result=$(requestTasksFromGradle)

    assertEquals "$LOCAL_TASKS" "$result"
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

test__should_get_tasks_from_output_with_simple_block() {
    result=$(parseGradleTaskOutput "$(cat ./t/tasks-one-heading.out)")

    assertEquals 'assemble build buildDependents buildNeeded classes clean j9Classes jar testClasses' "$result"
}

test__should_get_tasks_from_output_with_multiple_headings_and_noise() {
    result=$(parseGradleTaskOutput "$(cat ./t/tasks-full.out)")

    exp='assemble build buildDependents buildNeeded classes clean j9Classes jar testClasses init wrapper javadoc buildEnvironment components dependencies dependencyInsight dependentComponents help model projects properties tasks cleanEclipse cleanIdea eclipse idea uploadArchives check test backport compressTests deploy deployDownloadedArtifacts deploySpeechAdi deploySpeechRevo dialogTests'
    if [[ $result != $exp ]]; then
        fail "expected: '$exp'\n    got: '$result'"
    fi
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

testLarge__should_be_able_to_request_possible_flags_from_gradle() {
    lcd $LOCAL_GRADLE_REPO

    result=$(requestFlagsFromGradle)

    assertEquals '-? -h --help -a --no-rebuild -b --build-file -c --settings-file --configure-on-demand --console --continue -D --system-prop -d --debug --daemon --foreground -g --gradle-user-home --gui -I --init-script -i --info --include-build -m --dry-run --max-workers --no-daemon --offline -P --project-prop -p --project-dir --parallel --profile --project-cache-dir -q --quiet --recompile-scripts --refresh-dependencies --rerun-tasks -S --full-stacktrace -s --stacktrace --status --stop -t --continuous -u --no-search-upward -v --version -x --exclude-task' "$result"
}

test__should_get_cmdline_flags_from_help_string() {
    input="
    --continue              Continues task execution after a task failure.
    -D, --system-prop       Set system property of the JVM (e.g. -Dmyprop=myvalue).
    -?, -h, --help          Shows this help message.
    "
    result=$(parseGradleHelpOutput "$input")

    assertEquals '--continue -D --system-prop -? -h --help' "$result"
}

test__should_get_cmdline_flags_from_complete_help_output() {

    result=$(parseGradleHelpOutput "$(cat ./t/help.out)")

    assertEquals '-? -h --help -a --no-rebuild -b --build-file -c --settings-file --configure-on-demand --console --continue -D --system-prop -d --debug --daemon --foreground -g --gradle-user-home --gui -I --init-script -i --info --include-build -m --dry-run --max-workers --no-daemon --offline -P --project-prop -p --project-dir --parallel --profile --project-cache-dir -q --quiet --recompile-scripts --refresh-dependencies --rerun-tasks -S --full-stacktrace -s --stacktrace --status --stop -t --continuous -u --no-search-upward -v --version -x --exclude-task' "$result"
}

lcd() {
    export CHANGED_DIR=true
    cd $1
}
