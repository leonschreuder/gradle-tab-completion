Gradle tab completion script for Bash
====================

A tab completion script that works for Bash on Mac OS X.  Relies on the BSD ```md5``` command, so it might not work out-of-the-box on Linux.  (Pull requests welcome!)

Usage
-----

```$ gradle [TAB]```

```
androidDependencies      connectedInstrumentTest  lintRelease
assemble                 dependencies             projects
assembleDebug            dependencyInsight        properties
assembleDebugTest        deviceCheck              signingReport
assembleRelease          help                     tasks
build                    init                     uninstallAll
buildDependents          installDebug             uninstallDebug
buildNeeded              installDebugTest         uninstallDebugTest
check                    installRelease           uninstallRelease
clean                    lint                     wrapper
connectedCheck           lintDebug
```

```$ gradle c[TAB]```

```
check                    connectedCheck
clean                    connectedInstrumentTest
```

Gives tab completions relevent to the current gradle project (if any).

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

It will be super slow the first time you use it, but after that it'll be super fast, because it's cached based on the md5sum of your ```build.gradle``` files.


TODOs
------

* zsh support
* Linux support