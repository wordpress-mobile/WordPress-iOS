/// Due to a known issue, the compiler produces warnings on the Swift code that an intent definition file generates.
/// Ref: https://developer.apple.com/forums/thread/686448
/// As a workaround, we ignore all multiple method declarations warnings when importing WordPress-Swift.h
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wduplicate-method-match"
#import "WordPress-Swift-XcodeGenerated.h"
#pragma clang diagnostic pop
