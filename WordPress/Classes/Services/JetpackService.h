#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

@class WPAccount;

@interface JetpackService : LocalCoreDataService

- (void)validateAndLoginWithUsername:(NSString *)username
                            password:(NSString *)password
                     multifactorCode:(NSString *)multifactorCode
                              siteID:(NSNumber *)siteID
                             success:(void (^)(WPAccount *account))success
                             failure:(void (^)(NSError *error))failure;

@end