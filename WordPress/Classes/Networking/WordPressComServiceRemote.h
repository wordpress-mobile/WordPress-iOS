#import "ServiceRemoteREST.h"

typedef NS_ENUM(NSUInteger, WordPressComServiceBlogVisibility) {
    WordPressComApiBlogVisibilityPublic = 0,
    WordPressComApiComBlogVisibilityPrivate = 1,
    WordPressComApiBlogVisibilityHidden = 2,
};

@interface WordPressComServiceRemote : ServiceRemoteREST

- (void)createWPComAccountWithEmail:(NSString *)email
                        andUsername:(NSString *)username
                        andPassword:(NSString *)password
                            success:(void (^)(id responseObject))success
                            failure:(void (^)(NSError *error))failure;

- (void)validateWPComBlogWithUrl:(NSString *)blogUrl
                    andBlogTitle:(NSString *)blogTitle
                   andLanguageId:(NSNumber *)languageId
                         success:(void (^)(id))success
                         failure:(void (^)(NSError *))failure;

- (void)createWPComBlogWithUrl:(NSString *)blogUrl
                  andBlogTitle:(NSString *)blogTitle
                 andLanguageId:(NSNumber *)languageId
             andBlogVisibility:(WordPressComServiceBlogVisibility)visibility
                       success:(void (^)(id))success
                       failure:(void (^)(NSError *))failure;

@end
