// Import this header instead of <WordPressAuthenticator/WordPressAuthenticator-Swift.h>
// This allows the pod to be built as a static or dynamic framework
// See https://github.com/CocoaPods/CocoaPods/issues/7594
#if __has_include("WordPressAuthenticator-Swift.h")
    #import "WordPressAuthenticator-Swift.h"
#else
    #import <WordPressAuthenticator/WordPressAuthenticator-Swift.h>
#endif
