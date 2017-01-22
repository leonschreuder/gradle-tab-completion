export CASHE_FILE="$HOME/.gradle/.gradle_completion_cash"

#TODO:
# - commandline flags support https://gist.github.com/Ea87/46401a96df31cd208a87
# - gitbash & cygwin support
# - module support

getGradleCommand() {
    local gradle_cmd='gradle'
    if [[ -x ./gradlew ]]; then
        gradle_cmd='./gradlew'
    fi
    echo $gradle_cmd
}

requestTasksFromGradle() {
    local gradle_cmd=$(getGradleCommand)
    local taskCommandOutput=$($gradle_cmd tasks --console plain --quiet --offline)
    echo $(parseGradleTaskOutput "$taskCommandOutput")
}

parseGradleTaskOutput() {
    local commands=''
    local readingTasks=0
    local lastLineEmpty=1 # The command output has a title that starts with a line of dashes
    while read -r line || [[ -n $line ]]; do
        if [[ $line == "--"* && $lastLineEmpty == 0 ]]; then
            readingTasks=1
        elif [[ $line == '' ]]; then
            readingTasks=0
            lastLineEmpty=1
        else
            lastLineEmpty=0
            if [[ $readingTasks == 1 ]]; then
                if [[ $line != "Pattern:"* ]]; then
                    commands="$commands $(trim ${line%\ -\ *})"
                fi
            fi
        fi
    done <<< "$@"

    echo $commands
}

#credit: http://stackoverflow.com/a/33248547/3968618
trim() {
    local s2 s="$*"
    # note: the brackets in each of the following two lines contain one space
    # and one tab
    until s2="${s#\ \t]}"; [ "$s2" = "$s" ]; do s="$s2"; done
    until s2="${s%\ \t]}"; [ "$s2" = "$s" ]; do s="$s2"; done
    echo "$s"
}

getGradleTasksFromCache() {
    cache=$(readCacheForCwd)
    if [[ $cache != '' ]]; then
        IFS='|' read -ra resultArray <<< "$cache"

        # Return the tasks only if the cache is up to date
        currentHash=$(getGradleChangesHash)
        if [[ ${resultArray[1]} == $currentHash ]]; then
            echo ${resultArray[2]}
        fi
    fi
}

readCacheForCwd() {
    local cwd=$(pwd)
    if [ -s $CASHE_FILE ]; then
        while read cacheLine || [[ -n $cacheLine ]]; do
            if [[ $cacheLine == "$cwd"* ]]; then
                echo $cacheLine
                return 0
            fi
        done <$CASHE_FILE
    fi
}

writeTasksToCache() {
    local newLine="$(pwd)|$(getGradleChangesHash)|$@"
    if [ -s $CASHE_FILE ]; then
        # we have a cache already. Read it and replace the existing cache for this dir
        local i=0
        while read cacheLine || [[ -n $cacheLine ]]; do
            local i=$((i+1))
            if [[ $cacheLine == "$cwd"* ]]; then
                replaceLineNumberInFileWith $i $CASHE_FILE "$newLine"
                return 0
            fi
        done <<< $CASHE_FILE
    fi
    # If there was no file or the file did not have a cache for this dir, we add it here
    echo $newLine >> $CASHE_FILE
}

replaceLineNumberInFileWith() {
    if echo "$(sed -i 2>&1 )" | grep -q "option requires an argument"; then
        # That's BSD sed, the osx default
        sed -i '' "${1}s#.*#$3#" $2
    else
        sed -i "${1}s#.*#$3#" $2
    fi
}

getGradleChangesHash() {
    if hash git 2>/dev/null; then
        find . -name build.gradle 2> /dev/null \
            | xargs cat \
            | git hash-object --stdin
    elif hash md5 2>/dev/null; then
        # use md5 for hashing (Mac OS X)
        find . -name build.gradle 2> /dev/null \
            | xargs cat \
            | md5
    else
        # use md5sum for hashing (Linux)
        find . -name build.gradle 2> /dev/null \
            | xargs cat \
            | md5sum \
            | cut -f1 -d' '
    fi
}

_gradle() {
    local gradle_cmd=$(getGradleCommand)

    local commands=$(getGradleTasksFromCache)

    if [[ $commands == '' ]]; then
        commands=$(requestTasksFromGradle)
        writeTasksToCache $commands
    fi

    COMPREPLY=()
    local cur=${COMP_WORDS[COMP_CWORD]}
    colonprefixes=${cur%"${cur##*:}"}
    COMPREPLY=( $(compgen -W "${commands}"  -- $cur))
    local i=${#COMPREPLY[*]}
    while [ $((--i)) -ge 0 ]; do
        COMPREPLY[$i]=${COMPREPLY[$i]#"$colonprefixes"}
    done
}

complete -F _gradle gradle
complete -F _gradle gradlew
complete -F _gradle ./gradlew
