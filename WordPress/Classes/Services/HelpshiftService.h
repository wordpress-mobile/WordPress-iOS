#import <Foundation/Foundation.h>

@protocol HelpshiftService

- (BOOL)isHelpshiftEnabled;

@end

@interface HelpshiftService : NSObject <HelpshiftService>

@end
