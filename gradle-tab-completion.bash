export CASHE_FILE="$HOME/.gradle/.gradle_completion_cash"

getGradleCommand() {
    local gradle_cmd='gradle'
    if [[ -x ./gradlew ]]; then
        gradle_cmd='./gradlew'
    fi
    echo $gradle_cmd
}

requestTasksFromGradle() {
    local gradle_cmd=$(getGradleCommand)
    commands=$($gradle_cmd tasks --console plain --quiet --offline | sed -n s/\ -\ .*//p | tr '\n' ' ')
    echo $commands
}

getGradleTasksFromCache() {
    cache=$(readCacheForCwd)
    if [[ $cache != '' ]]; then
        IFS='|' read -ra resultArray <<< "$cache"

        # Return the tasks only if the cache is up to date
        currentHash=$(getGradleChangesHash)
        if [ ${resultArray[1]} == $currentHash ]; then
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
                #overwrite the line
                sed -i '' "${i}s:.*:${newLine}:" $CASHE_FILE
                return 0
            fi
        done <$CASHE_FILE
    fi
    # If there was no file or the file did not have a cache for this dir, we add it here
    echo $newLine >> $CASHE_FILE
}

getGradleChangesHash() {
    if hash md5 2>/dev/null; then
        # use md5 for hashing (Mac OS X)
        find . -name build.gradle -exec md5 {} \; | md5
    else
        # use md5sum for hashing (Linux)
        find . -name build.gradle -exec md5sum {} \; | md5sum | cut -f1 -d' '
    fi
}

_gradle() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    local gradle_cmd=$(getGradleCommand)

    local commands=$(getGradleTasksFromCache)

    if [[ $commands == '' ]]; then
        commands=$(requestTasksFromGradle)
        writeTasksToCache $commands
    fi

    COMPREPLY=( $(compgen -W "${commands}" -- $cur) )
}
complete -F _gradle gradle
complete -F _gradle gradlew
complete -F _gradle ./gradlew
