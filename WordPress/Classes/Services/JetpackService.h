#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

@class WPAccount;

NS_ASSUME_NONNULL_BEGIN

@interface JetpackService : LocalCoreDataService

- (void)validateAndLoginWithUsername:(NSString *)username
                            password:(NSString *)password
                     multifactorCode:(NSString * _Nullable)multifactorCode
                              siteID:(NSNumber *)siteID
                             success:(void (^)(WPAccount *account))success
                             failure:(void (^)(NSError *error))failure;

- (void)checkSiteHasJetpack:(NSURL *)siteURL
                    success:(void (^)(BOOL hasJetpack))success
                    failure:(void (^)(NSError * error))failure;

@end

NS_ASSUME_NONNULL_END
