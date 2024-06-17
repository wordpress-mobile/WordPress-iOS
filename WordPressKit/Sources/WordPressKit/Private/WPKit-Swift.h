// Import this header instead of <WordPressKit/WordPressKit-Swift.h>
// This allows the pod to be built as a static or dynamic framework
// See https://github.com/CocoaPods/CocoaPods/issues/7594
#if __has_include("WordPressKit-Swift.h")
    #import "WordPressKit-Swift.h"
#else
    #import <WordPressKit/WordPressKit-Swift.h>
#endif
