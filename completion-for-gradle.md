Gradle tab completion script for Bash
====================

A tab completion script that works for Bash on Mac OS X.  Relies on the BSD ```md5``` command, so it might not work out-of-the-box on Linux.  (Pull requests welcome!)

Usage
-----

```$ gradle [TAB]```

```
androidDependencies      check                    init                     properties
assemble                 clean                    installDebug             signingReport
assembleDebug            connectedCheck           installDebugTest         tasks
assembleDebugTest        connectedInstrumentTest  installRelease           uninstallAll
assembleRelease          dependencies             lint                     uninstallDebug
build                    dependencyInsight        lintDebug                uninstallDebugTest
buildDependents          deviceCheck              lintRelease              uninstallRelease
buildNeeded              help                     projects                 wrapper
```

```$ gradle c[TAB]```

```
check                    clean                    connectedCheck           connectedInstrumentTest
```

Gives tab completions relevent to the current Gradle project (if any).

Install
--------

```
curl -s https://gist.github.com/nolanlawson/8694399/raw/gradle-tab-completion.bash \
  -o ~/gradle-tab-completion.bash
```

Then add to your ```~/.bash_profile```:

```
source ~/gradle-tab-completion.bash
```

It will be kinda slow the first time you use it. But after that, it'll be super fast, because everything's cached based on the md5sum of your ```build.gradle``` files.


TODOs
------

* zsh support
* Linux support