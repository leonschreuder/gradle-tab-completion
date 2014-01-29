_gradle()
{
  local cur=${COMP_WORDS[COMP_CWORD]}
  local gradle_cmd='gradle'
  if [[ -f ./gradlew ]]; then
    gradle_cmd='./gradlew'
  fi
  if [[ -f ../gradlew ]]; then
    gradle_cmd='../gradlew'
  fi

  local commands=''
  local cache_dir="$HOME/.gradle_tabcompletion"
  mkdir -p $cache_dir

  # TODO: include the gradle version in the checksum?  It's kinda slow
  #local gradle_version=$($gradle_cmd --version --quiet --no-color | grep '^Gradle ' | sed 's/Gradle //g')

  local gradle_files_checksum=$(md5 -q -s "$(md5 -q $(find . -name build.gradle))")
  if [[ -f $cache_dir/$gradle_files_checksum ]]; then # cached! yay!
    commands=$(cat $cache_dir/$gradle_files_checksum)
  else # not cached! boo-urns!
    commands=$($gradle_cmd --no-color --quiet tasks | grep ' - ' | awk '{print $1}' | tr '\n' ' ')
    echo $commands > $cache_dir/$gradle_files_checksum
  fi
  COMPREPLY=( $(compgen -W "$commands" -- $cur) )
}
complete -F _gradle gradle