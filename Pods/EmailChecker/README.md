# Email Checker for Android and iOS

## Introduction

This library helps to catch simple email domain typos. Its intended to
be used as a hint when a user have to enter an email address.

The library is written in C++ and is inspired by the algorithm
described here: http://norvig.com/spell-correct.html (Warning, it's
not the exact same algo).

## How to use it on Android

Currently gradle doesn't support NDK, so we used a trick to make it
work: it generates a temporary .jar file containing .so, this file is
used as a jar dependency for the final .aar file.

If you want to use it in your Android project, your can add it as a
library in your build.gradle file, for instance:

    dependencies {
        compile 'org.wordpress:emailchecker:0.1'
    }

## How to use it on iOS


## Directory structure

    |-- common                  # common native code
    |-- android
    |   |-- jni                 # android specific native code
    |   `-- src                 # android specific java code
    `-- ios
        |-- EmailChecker        # ios specific code
        `-- EmailCheckerTests   # tests

## Apps that use this library

- [WordPress for Android][1]

## LICENSE

This library is dual licensed unded MIT and GPL v2.

[1]: https://github.com/wordpress-mobile/WordPress-Android
