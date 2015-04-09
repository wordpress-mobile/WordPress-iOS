#import <Foundation/Foundation.h>

@protocol HelpshiftFacade

- (BOOL)isHelpshiftEnabled;

@end

@interface HelpshiftFacade : NSObject <HelpshiftFacade>

@end
