#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

@class WPAccount;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const JetpackServiceErrorDomain;

typedef NS_ENUM(NSInteger, JetpackError) {
    JetpackErrorNone,
    JetpackErrorDisabled,
    JetpackErrorSiteInaccessible
};



@interface JetpackService : LocalCoreDataService

- (void)validateAndLoginWithUsername:(NSString *)username
                            password:(NSString *)password
                     multifactorCode:(NSString * _Nullable)multifactorCode
                              siteID:(NSNumber *)siteID
                             success:(void (^)(WPAccount *account))success
                             failure:(void (^)(NSError *error))failure;

- (void)checkSiteIsJetpack:(NSURL *)siteURL
                   success:(void (^)(BOOL isJetpack, NSError * _Nullable error))success
                   failure:(void (^)(NSError * error))failure;

@end

NS_ASSUME_NONNULL_END
