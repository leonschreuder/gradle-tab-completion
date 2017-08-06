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

It is just autocompletion dummy. How did you think you where going to use it?

```
    $ ./gradlew c[TAB]
check                    clean                    connectedCheck           connectedInstrumentTest
```

Okay, here it starts getting interesting: sub-projects are now also supported...

```
    $ ./gradlew proj[TAB]
proj:check               proj:clean               proj:connectedCheck      proj:connectedInstrumentTest
```

...and of course: flags. Flags expecting files or paths just work like you'd expect them to.

```
    $ ./gradlew --p[TAB]
--parallel           --profile            --project-cache-dir  --project-dir        --project-prop

    $ ./gradlew --project-cache-dir [TAB]
dir1                dir2
```


### Note on cache:
Results are cached on first run and completion is fast after that. Caches are
invalidated by changes in your *.gradle scripts, so tasks that are added or
removed are reflected instantly as well.

Installation
--------------------------------------------------------------------------------

### The easy way
Install in your user-home with something copy-past-able:
```
curl -L \
  -s https://raw.githubusercontent.com/meonlol/gradle-tab-completion/master/gradle-tab-completion.bash \
  -o ~/gradle-tab-completion.bash
chmod +x ~/gradle-tab-completion.bash
LINE="source ~/gradle-tab-completion.bash"; [[ -e ~/.bash_profile ]] && echo $LINE >> ~/.bash_profile || echo $LINE >> ~/.bashrc
```

### The 'correct' way
Download the script file and put it one of the standard locations for completion scripts:
- `/etc/bash_completion.d`  -  for all users,
- `/usr/local/etc/bash_completion.d` -  for you
- `~/bash_completion.d` - Also for you, but grouped in a neat directory.

The script will then be automatically loaded.

Credit
--------------------------------------------------------------------------------

This script was initially forked from [this script](https://gist.github.com/nolanlawson/8694399/) by
[@nolanlawson](https://github.com/nolanlawson). Also, after find out he'd
already built this, I sometimes looked at what
[@eriwen](https://github.com/eriwen) did in [his
script](https://github.com/eriwen/gradle-completion).
