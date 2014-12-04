#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

@class WPAccount, Blog;

@interface JetpackService : NSObject<LocalCoreDataService>

- (void)validateAndLoginWithUsername:(NSString *)username
                            password:(NSString *)password
                                blog:(Blog *)blog
                             success:(void (^)(WPAccount *account))success
                             failure:(void (^)(NSError *error))failure;

@end
