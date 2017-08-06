# References
# https://gist.github.com/nolanlawson/8694399/      # Initial Gist
# https://github.com/eriwen/gradle-completion       # Other completion engine I found later

CASHE_FILE="$HOME/.gradle/.gradle_completion_cash"


#TODO:
# - test gitbash & cygwin support


# Main
#================================================================================

_gradle() {
    local cur prev commands

    _get_comp_words_by_ref -n : cur         # gets current word without being messed up by ':'
    _get_comp_words_by_ref -n : -p prev

    buildCacheIfRequired

    commands="$(getCommandsForCurrentDirFromCache $cur)"
    setCompletionFor "$prev" "$cur" "$commands"
}


setCompletionFor() {
    local prev="$1"
    local cur="$2"
    local commands="$3"

    case "$prev" in
        # Commands followed by a file-path
        -I|--init-script|-c|--settings-file|-b|--build-file)
            COMPREPLY=( $(compgen -f -- $cur))
            ;;
        # Commands followed by a folder-path
        -g|--gradle-user-home|--include-build|-p|--project-dir|--project-cache-dir)
            COMPREPLY=( $(compgen -d -- $cur))
            ;;
        --console)
            COMPREPLY=( $(compgen -W 'plain auto rich' -- $cur))
            ;;
        *)
            COMPREPLY=( $(compgen -W "${commands}"  -- $cur))
            # ;;
    esac

    # Prevents recursive completion when contains a ':' (Not available in tests)
    [[ -n "$(type -t __ltrim_colon_completions)" ]] && __ltrim_colon_completions "$cur"
}

getGradleCommand() {
    local gradle_cmd='gradle'
    if [[ -x ./gradlew ]]; then
        gradle_cmd='./gradlew'
    fi
    echo $gradle_cmd
}



# Caching
#================================================================================

buildCacheIfRequired() {
    if [[ $(hasCache) -ne 0 ]]; then

        local msg="  (Just a sec. Building cache...)"
        local msgLength=${#msg}
        backspaces=$(printf '\b%.0s' $(seq 1 $msgLength))
        spaces=$(printf ' %.0s' $(seq 1 $msgLength))

        echo -en "$msg$backspaces"      # Prints the message and moves the cursor back

        buildCache

        echo -en "$spaces$backspaces"   # Overwrites the message with spaces, moving the cursor back again
    fi
}

hasCache() {
    grep -q $(getGradleChangesHash) "$CASHE_FILE" >& /dev/null
    echo $?
}

getGradleChangesHash() {
    if hash git 2>/dev/null; then
        find . -name "*.gradle" 2> /dev/null \
            | xargs cat \
            | git hash-object --stdin
    elif hash md5 2>/dev/null; then
        # use md5 for hashing (Mac OS X)
        find . -name "*.gradle" 2> /dev/null \
            | xargs cat \
            | md5
    else
        # use md5sum for hashing (Linux)
        find . -name "*.gradle" 2> /dev/null \
            | xargs cat \
            | md5sum \
            | cut -f1 -d' '
    fi
}

# Building Cache
#------------------------------------------------------------

buildCache() {
    commands="$(requestTasksFromGradle) $(requestFlagsFromGradle)"
    writeTasksToCache $commands
}

requestTasksFromGradle() {
    local outputOfTasksCommand=$($(getGradleCommand) tasks --console plain --all --quiet --offline)
    echo $(parseOutputOfTasksCommand "$outputOfTasksCommand")
}

# Reading every line so we also catch tasks without a description
parseOutputOfTasksCommand() {
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

requestFlagsFromGradle() {
    local outputOfGradleHelp=$($(getGradleCommand) --help)
    echo $(parseOutputOfGradleHelp "$outputOfGradleHelp")
}

parseOutputOfGradleHelp() {
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

# Reading Cache
#------------------------------------------------------------

getCommandsForCurrentDirFromCache() {
    currentInput=$1
    commands=$(getCommandsFromCache)

    # Only show dash commands when expicitly typed to keep it simple
    if [[ $currentInput == "-"* ]]; then
        if [[ $currentInput != "--"* ]]; then
            commands=$(filterSingleDashCommands "$commands")
        # else
            # The user typed a double dash already, completion will filter the single-dashed results out
        fi
    else
        commands=${commands//-*/}
    fi

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

filterSingleDashCommands() {
    # couldn't find a simple cross-platform solution to filter these out, so loop to get only single dashed
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



# Define the completion
#================================================================================

complete -o bashdefault -F _gradle gradle
complete -o bashdefault -F _gradle gradlew
complete -o bashdefault -F _gradle ./gradlew

if hash gw 2>/dev/null || alias gw >/dev/null 2>&1; then
    complete -o bashdefault -F _gradle gw
fi

