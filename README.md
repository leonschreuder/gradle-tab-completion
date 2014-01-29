Gradle tab completion script for Bash
====================

A quick-and-dirty tab completion script that works for Bash on the Mac.  Relies on the BSD ```md5``` command so it might not work out-of-the-box on Linux.  (Pull requests welcome!)

Usage
-----

Type ```$ gradle [TAB]```

Get: 

```
androidDependencies      assembleRelease          check                    dependencies             init                     lint                     properties               uninstallDebug
assemble                 build                    clean                    dependencyInsight        installDebug             lintDebug                signingReport            uninstallDebugTest
assembleDebug            buildDependents          connectedCheck           deviceCheck              installDebugTest         lintRelease              tasks                    uninstallRelease
assembleDebugTest        buildNeeded              connectedInstrumentTest  help
```

Type ```$ gradle c[TAB]```

Get:

```check                    clean                    connectedCheck           connectedInstrumentTest```

Gives tab completions relevent to the current gradle project (if any).

Install
--------

```
curl -s https://gist.github.com/nolanlawson/8694399/raw/gradle-tab-completion.bash -o ~/gradle-tab-completion.bash
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