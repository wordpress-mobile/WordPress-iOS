# NSLogger-CocoaLumberjack-connector #

This is a bridge for the projects

* http://github.com/robbiehanson/CocoaLumberjack
(A general purpose superfast logging framework)

and

* http://github.com/fpillet/NSLogger
(send logs to a client app via network)


Just add this code to the logger initializer in your app delegate:

`[DDLog addLogger:[DDNSLoggerLogger sharedInstance]];`


Don't forget to 

`git submodules init
git submodules update`