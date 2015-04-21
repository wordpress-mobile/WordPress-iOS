#import <Foundation/Foundation.h>

 /**
 *  This protocol represents a class that can determine whether Helpshift is enabled or not
 */
@protocol HelpshiftEnabledFacade

/**
 *  Indicates whether Helpshift is enabled
 *
 *  @return whether helpshift is enabled or not.
 */
- (BOOL)isHelpshiftEnabled;

@end

 /**
 *  This class can determine whether Helpshift is enabled or not
 */
@interface HelpshiftEnabledFacade : NSObject <HelpshiftEnabledFacade>

@end
