#!/usr/bin/env bash

setup() {
    ORIG_WD=$(pwd)
    source ./gradle-tab-completion.bash
    CASHE_FILE="testCache"
}

teardown() {
    rm -f $CASHE_FILE

    rm -f ./gradlew
    rm -f ./build.gradle
}



# Main
#================================================================================

test__completion_should_return_all_when_empty() {
    setCompletionFor "" "" "taskA taskB Ctask"
    assertEquals 'taskA taskB Ctask' "${COMPREPLY[*]}"
}

test__completion_should_complete_from_prefix() {
    setCompletionFor "" "tas" "taska taskb ctask"
    assertEquals 'taska taskb' "${COMPREPLY[*]}"
}

test__completion_should_support_colons() {
    setCompletionFor "" ":" ":taska :taskb"
    assertEquals ':taska :taskb' "${COMPREPLY[*]}"

    setCompletionFor "" "module:" "module:taska module:taskb"
    assertEquals 'module:taska module:taskb' "${COMPREPLY[*]}"
}

test__completion_should_support_file_path_completion() {
    # listing files and dirs
    setCompletionFor "-I" "" ""
    assertEquals '.git .travis.yml gradle-tab-completion.bash README.md runTests.sh t test_gradle-tab-completion.sh' "${COMPREPLY[*]}"

    setCompletionFor "--build-file" "" ""
    assertEquals '.git .travis.yml gradle-tab-completion.bash README.md runTests.sh t test_gradle-tab-completion.sh' "${COMPREPLY[*]}"
}

test__completion_should_support_dir_path_completion() {
    # listing dirs only
    setCompletionFor "-g" "" ""
    assertEquals '.git t' "${COMPREPLY[*]}"

    setCompletionFor "--project-cache-dir" "" ""
    assertEquals '.git t' "${COMPREPLY[*]}"
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

# Caching
#================================================================================

test__should_be_able_to_see_if_has_cache() {
    assertEquals 2 $(hasCache)
    writeTasksToCache "a b"
    assertEquals 0 $(hasCache)
}

test__should_refresh_outdated_cache() {
    echo "$(pwd)|$(echo "" | git hash-object --stdin)|a b c" > $CASHE_FILE

    assertEquals 1 $(hasCache)
}

# Building Cache
#------------------------------------------------------------

test__should_get_all_commands_from_gadle_tasks_output() {
    result=$(parseOutputOfTasksCommand "$(cat ./t/tasks-full.out)")

    exp='assemble build classes compileJava processResources clean testClasses compileTestJava processTestResources init wrapper javadoc buildEnvironment module:buildEnvironment components module:components model module:model projects module:projects properties module:properties tasks module:tasks check test syntastic install justSomeTask'
    if [[ $result != $exp ]]; then
        fail "expected: '$exp'\n    got: '$result'"
    fi
}

test__should_get_cmdline_flags_from_help_string() {
    input="
    --continue              Continues task execution after a task failure.
    -D, --system-prop       Set system property of the JVM (e.g. -Dmyprop=myvalue).
    -?, -h, --help          Shows this help message.
    "
    result=$(parseOutputOfGradleHelp "$input")

    assertEquals '--continue -D --system-prop -? -h --help' "$result"
}

test__should_get_cmdline_flags_from_full_gradle_help() {

    result=$(parseOutputOfGradleHelp "$(cat ./t/help.out)")

    assertEquals '-? -h --help -a --no-rebuild -b --build-file -c --settings-file --configure-on-demand --console --continue -D --system-prop -d --debug --daemon --foreground -g --gradle-user-home --gui -I --init-script -i --info --include-build -m --dry-run --max-workers --no-daemon --offline -P --project-prop -p --project-dir --parallel --profile --project-cache-dir -q --quiet --recompile-scripts --refresh-dependencies --rerun-tasks -S --full-stacktrace -s --stacktrace --status --stop -t --continuous -u --no-search-upward -v --version -x --exclude-task' "$result"
}


test_should_ignore_cache_when_file_content_changes() {
    touch ./build.gradle
    writeTasksToCache "testA testB btest"

    echo "//something" >> ./build.gradle # changing file content which should invalidate the cache
    result=$(getCommandsFromCache)

    assertEquals '' "$result"
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
        fail "expected 1 cache record, got '$pathCount'"
    fi
}


# Reading Cache
#------------------------------------------------------------

test__should_hide_commands_with_dash__when_reading_cache_for_task() {
    tasks='testA testB btest module:project'
    commands="$tasks -h -? --help --version"
    writeTasksToCache "$commands"

    result=$(getCommandsForCurrentDirFromCache)

    assertEquals "$tasks" "$result"
}

test__should_hide_double_dash_commands_when_current_prefix_is_dash() {
    commands='testA btest module:project -h -? --help --version testB'
    writeTasksToCache "$commands"

    result=$(getCommandsForCurrentDirFromCache '-')

    assertEquals "-h -?" "$result"
}

test_should_read_and_write_from_cache_correctly() {
    tasks='testA testB btest module:project'
    writeTasksToCache $tasks

    result=$(getCommandsFromCache)

    assertEquals "$tasks" "$result"
}

test__reading_from_empty_cache_should_return_empty_string() {
    local result=$(readCacheForCwd)

    assertEquals '' $result
}
