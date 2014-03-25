CrashlyticsLumberjack
=====================

CrashlyticsLumberjack is a bridge between [Crashlytics](http://support.crashlytics.com/knowledgebase/articles/92519-how-do-i-use-logging-) logging and [CocoaLumberjack](https://github.com/robbiehanson/CocoaLumberjack).


##Using
- Add `pod 'CrashlyticsLumberjack', '~>1.0.0'` to your podfile.

*OR*

- Simply add `CrashlyticsLumberjack.h` and `CrashlyticsLumberjack.m` to your project.

This code uses ARC.

#####Example:

```objective-c
#import <CrashlyticsLumberjack/CrashlyticsLogger.h>


[DDLog addLogger:[CrashlyticsLogger sharedInstance]];


```


##License

BSD 3-Clause, see http://www.opensource.org/licenses/BSD-3-Clause