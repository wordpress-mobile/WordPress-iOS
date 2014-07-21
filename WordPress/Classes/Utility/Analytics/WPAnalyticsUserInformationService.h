#import <Foundation/Foundation.h>

@interface WPAnalyticsUserInformationService : NSObject

+ (void)retrieveAndRegisterEmailAddressIfApplicable;
+ (void)resetEmailRetrievalCheck;

@end
