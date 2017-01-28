export CASHE_FILE="$HOME/.gradle/.gradle_completion_cash"

#TODO:
# - gitbash & cygwin support
# - module support

_gradle() {
    COMPREPLY=()
    local cur=${COMP_WORDS[COMP_CWORD]}

    local commands="$(getCommandsForCurrentPrefix $cur)"

    colonprefixes=${cur%"${cur##*:}"}
    COMPREPLY=( $(compgen -W "${commands}"  -- $cur))
    local i=${#COMPREPLY[*]}
    while [ $((--i)) -ge 0 ]; do
        COMPREPLY[$i]=${COMPREPLY[$i]#"$colonprefixes"}
    done
}

getCommandsForCurrentPrefix() {
    currentPrefix=$1
    commands=$(getCommandsFromCache)
    if [[ $currentPrefix == "-"* ]]; then
        if [[ $currentPrefix != "--"* ]]; then
            commands=$(getSingleDashFromString "$commands")
        # else
            # we have a double dash prefix, and can leave the commands as they are
        fi
    else
        commands=${commands//-*/}
    fi

    if [[ $commands == '' ]]; then
        commands=$(requestCommandsAndUpdateCache)
    fi
    echo $commands
}

getSingleDashFromString() {
    # couldn't get a cross-platform solution to work, so filter the commands with a basic loop
    result=''
    for singleCommand in $1; do
        if [[ $singleCommand == -* &&  $singleCommand != --* ]]; then
            if [[ $result == '' ]]; then
                result="$singleCommand"
            else
                result="$result $singleCommand"
            fi
        fi
    done
    echo $result
}

requestCommandsAndUpdateCache() {
    commands="$(requestTasksFromGradle) $(requestFlagsFromGradle)"
    writeTasksToCache $commands
    echo $commands
}

getCommandsFromCache() {
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
        done < "$CASHE_FILE"
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

requestTasksFromGradle() {
    local gradle_cmd=$(getGradleCommand)
    local taskCommandOutput=$($gradle_cmd tasks --console plain --quiet --offline)
    echo $(parseGradleTaskOutput "$taskCommandOutput")
}

getGradleCommand() {
    local gradle_cmd='gradle'
    if [[ -x ./gradlew ]]; then
        gradle_cmd='./gradlew'
    fi
    echo $gradle_cmd
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
                    commands="$commands ${line%\ -\ *}"
                fi
            fi
        fi
    done <<< "$@"

    echo $commands
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

requestFlagsFromGradle() {
    local gradle_cmd=$(getGradleCommand)
    local helpCommandOutput=$($gradle_cmd --help)
    echo $(parseGradleHelpOutput "$helpCommandOutput")
}

parseGradleHelpOutput() {
    local result=''
    while read -r line || [[ -n $line ]]; do
        if [[ $line == -* ]]; then
            cmd=${line%\ \ *}   # remove suffix till multiple spaces
            cmd=${cmd//,/}      # now also remove commas
            result="$result $cmd"
        fi
    done <<< "$@"
    echo $result
}


# trigger completion on sourcing (which should be done when the bash initializes)
#--------------------------------------------------------------------------------

complete -F _gradle gradle
complete -F _gradle gradlew
complete -F _gradle ./gradlew
