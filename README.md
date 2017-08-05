[![Build Status](https://travis-ci.org/meonlol/gradle-tab-completion.svg?branch=master)](https://travis-ci.org/meonlol/gradle-tab-completion)

A Gradle tab completion script for Bash
================================================================================

Do you use gradle from the commandline and sometimes find yourself staring
dreamily into the distance at the thought of just pressing tab to see which
tasks you can execute?

Well now you can!

**Edit:**  
Okay, well apparently someone had built this already, and gradle even made it
repo-official: https://github.com/gradle/gradle-completion

I lost all motivation after I discovered my
let's-google-if-someone-already-built-this skills where in need of some
polishing, but as I found that the aforementioned official gradle-completion is
untested and was a bit over the top for my taste, I decided to finish my own
version anyway.  

Usage
--------------------------------------------------------------------------------

It is autocompletion dummy. How did you think you where going to use it?

```
    $ ./gradlew c[TAB]
check                    clean                    connectedCheck           connectedInstrumentTest
```

Sub-projects are supported:

```
    $ ./gradlew proj[TAB]
proj:check               proj:clean               proj:connectedCheck      proj:connectedInstrumentTest
```

Flags as well:

```
    $ ./gradlew --p[TAB]
--parallel           --profile            --project-cache-dir  --project-dir        --project-prop
```

Results are cached on first run and completion is fast after that. Caches are
invalidated by changes in your build.gradle scripts, so tasks that are added or
removed are reflected instantly as well.

Installation
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

This script was initially forked from [@nolanlawson](https://github.com/nolanlawson)
here https://gist.github.com/nolanlawson/8694399/ .
