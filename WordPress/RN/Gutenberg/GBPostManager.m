
//#import "WordPress-Swift.h"

// CalendarManagerBridge.m
#import <React/RCTBridgeModule.h>


@interface RCT_EXTERN_MODULE(GBPostManager, NSObject)
RCT_EXTERN_METHOD(savePost:(NSString *)content)
RCT_EXTERN_METHOD(close)
@end
