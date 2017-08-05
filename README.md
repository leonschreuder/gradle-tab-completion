[![Build Status](https://travis-ci.org/meonlol/gradle-tab-completion.svg?branch=master)](https://travis-ci.org/meonlol/gradle-tab-completion)

A Gradle tab completion script for Bash
================================================================================

Do you use gradle from the commandline and sometimes find yourself staring
dreamily into the distance at the thought of just pressing tab to see which
tasks you can execute?

Well now you can!

**Edit:**  
Well apparently someone had built this already, and gradle even made it
repo-official: https://github.com/gradle/gradle-completion

I lost all motivation after I discovered my
let's-google-if-someone-already-built-this skills where in need of some
polishing, but as I found that the aforementioned official gradle-completion
was a bit over the top for my taste, I decided to finish my own version anyway.  
Chef's Recommendations: tryout both and see which you prefer.

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

You can even use sub-selection...

```
    $ ./gradlew c[TAB]
check                    clean                    connectedCheck           connectedInstrumentTest
```

And flags are supported too...

```
    $ ./gradlew -[TAB]
-?  -D  -I  -P  -S  -a  -b  -c  -d  -g  -h  -i  -m  -p  -q  -s  -t  -u  -v  -x

    $ ./gradlew --p[TAB]
--parallel           --profile            --project-cache-dir  --project-dir        --project-prop
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

chmod +x ~/gradle-tab-completion.bash
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

### Adding commandline flags

`-[TAB]` and `--[TAB]` are now also supported. To prevent to much output, the flags
are hidden by default, when using `-[TAB]` only single flags are completed and
with `--[TAB]` the multicharacter flags are also shown.
