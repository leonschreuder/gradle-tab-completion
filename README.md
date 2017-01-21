
A Gradle tab completion script for Bash
================================================================================

Do you use gradle from the commandline and sometimes find yourself staring
dreamily into the distance at the thought of just pressing tab to see which
tasks you can execute?

Well now you can!

Usage
--------------------------------------------------------------------------------

Look at how we get propositions for every task in your gradle project:

```
    $ gradle [TAB]
androidDependencies      check                    init                     properties
assemble                 clean                    installDebug             signingReport
assembleDebug            connectedCheck           installDebugTest         tasks
assembleDebugTest        connectedInstrumentTest  installRelease           uninstallAll
assembleRelease          dependencies             lint                     uninstallDebug
build                    dependencyInsight        lintDebug                uninstallDebugTest
buildDependents          deviceCheck              lintRelease              uninstallRelease
buildNeeded              help                     projects                 wrapper
```

You can even use sub-selection:

```
    $ ./gradlew c[TAB]
check                    clean                    connectedCheck           connectedInstrumentTest
```

The tab completions asks Gradle for its tasks - which might have you waiting
the first time - but the script caches it (magically) so you have the
lighting-speed completion you always dreamed of after that! It will also track
changes in your build.gradle scripts, so it knows when tasks are added or
removed\*.


\* It just saves a hash of the build.gradle files in your project. So don't go
around sprinkeling task related gradle-magic around in other files.


Install
--------------------------------------------------------------------------------

```
curl -L -s https://raw.githubusercontent.com/meonlol/gradle-tab-completion/master/gradle-tab-completion.bash \
  -o ~/gradle-tab-completion.bash
```

Then add this to your `~/.bash_profile`:

```
source ~/gradle-tab-completion.bash
```

Credit
--------------------------------------------------------------------------------

This script was forked from [@nolanlawson](https://github.com/nolanlawson) here
https://gist.github.com/nolanlawson/8694399/ . He did all the hard work of
scripting the logic. He again thanks [@ligi](https://github.com/ligi) for Linux
support. Credit where credit is due.

### My improvements:

#### Smarter cache

Original caching only saved the tasks from one 'gradle tasks' run. The improved
caching saves a cache instance for every directory, and is therefore unique for
every repository.


#### Major refactoring && adding tests

The original script resisted my Linux machine with a passion, so initially I
just wanted to fix that. Since I'm a typically lazy developer when it comes to
manually testing my code in different circumstances, I spent WAAAY to much time
writing tests for all the logic, and ended up adding some improvements.

