# Email Checker for Android and iOS

## Introduction

This library helps to catch simple email domain typos. Its intended to
be used as a hint when a user have to enter an email address.

The library is written in C++ and is inspired by the algorithm
described here: http://norvig.com/spell-correct.html (Warning, it's
not the exact same algo).

## How to use it in an Android project

Currently gradle doesn't support NDK, so we used a trick to make it
work: it generates a temporary .jar file containing .so, this file is
used as a jar dependency for the final .aar file.

If you want to use it in your Android project, your can add it as a
library in your build.gradle file, for instance:

    dependencies {
        compile 'org.wordpress:emailchecker:0.1'
    }

Sample usage:

    String emailToCheck = "salut@gmial.com";
    String suggest = (new EmailChecker()).suggestDomainCorrection(email);
    if (suggest.compareTo(email) != 0) {
        Log.v("FIXME", "did you mean: " + suggest + " ?");
    }

## How to use it in an iOS project

If you use [CocoaPods][1], you just have to add the following pod to
your dependency list:

    pod 'EmailChecker', :podspec => 'https://raw.github.com/wordpress-mobile/EmailChecker/master/ios/EmailChecker.podspec'

Sample usage:

    NSString *emailToCheck = @"salut@gmial.com";
    NSString *suggestedEmail = [EmailChecker suggestDomainCorrection: @"salut@gmial.com"];
    if (![suggestedEmail isEqualToString:emailToCheck]) {
        NSLog(@"Did you mean: %@", suggestedEmail);
    }

## Directory structure

    |-- common                  # common native code
    |-- android
    |   |-- jni                 # android specific native code
    |   `-- src                 # android specific java code
    `-- ios
        |-- EmailChecker        # ios specific code
        `-- EmailCheckerTests   # tests

## Apps that use this library

### [WordPress for Android][2]

![Screenshot from WordPress Android](https://i.cloudup.com/rUxkHNsm5c.png)

### [WordPress for iOS][3]

![Screenshot from WordPress Android](https://i.cloudup.com/2Smrv9VYbJ.png)

## LICENSE

This library is dual licensed unded MIT and GPL v2.

[1]: http://cocoapods.org
[2]: https://github.com/wordpress-mobile/WordPress-Android
[3]: https://github.com/wordpress-mobile/WordPress-iOS
