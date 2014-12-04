#import <Foundation/Foundation.h>

/**
 * Error returned as the domain to NSError from JetpackServiceRemote.
 */
extern NSString * const JetpackServiceRemoteErrorDomain;

/**
 * Possible NSError codes for BlogJetpackErrorDomain.
 */
typedef NS_ENUM(NSInteger, JetpackServiceRemoteErrorCore) {
    // The user doesn't have access to that specific blog
    JetpackServiceRemoteErrorNoRecordForBlog,
    // The provided username/password are invalid
    JetpackServiceRemoteErrorInvalidCredentials,
};

@interface JetpackServiceRemote : NSObject

- (void)validateJetpackUsername:(NSString *)username password:(NSString *)password forSiteID:(NSNumber *)siteID success:(void (^)())success failure:(void (^)(NSError *error))failure;

@end
