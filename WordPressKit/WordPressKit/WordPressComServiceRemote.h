@import Foundation;
#import "ServiceRemoteWordPressComREST.h"

typedef NS_ENUM(NSUInteger, WordPressComServiceBlogVisibility) {
    WordPressComServiceBlogVisibilityPublic = 0,
    WordPressComServiceBlogVisibilityPrivate = 1,
    WordPressComServiceBlogVisibilityHidden = 2,
};

typedef void(^WordPressComServiceSuccessBlock)(NSDictionary *responseDictionary);
typedef void(^WordPressComServiceFailureBlock)(NSError *error);

/**
 *  @class      WordPressComServiceRemote
 *  @brief      Encapsulates exclusive WordPress.com services.
 */
@interface WordPressComServiceRemote : ServiceRemoteWordPressComREST

/**
 *  @brief      Creates a WordPress.com account with the specified parameters.
 *
 *  @param      email       The email to use for the new account.  Cannot be nil.
 *  @param      username    The username of the new account.  Cannot be nil.
 *  @param      password    The password of the new account.  Cannot be nil.
 *  @param      locale      The locale for the new account.  Cannot be nil.
 *  @param      success     The block to execute on success.  Can be nil.
 *  @param      failure     The block to execute on failure.  Can be nil.
 */
- (void)createWPComAccountWithEmail:(NSString *)email
                        andUsername:(NSString *)username
                        andPassword:(NSString *)password
                          andLocale:(NSString *)locale
                        andClientID:(NSString *)clientID
                    andClientSecret:(NSString *)clientSecret
                            success:(WordPressComServiceSuccessBlock)success
                            failure:(WordPressComServiceFailureBlock)failure;

/**
 Create a new account using Google

 @param token token provided by Google
 @param clientID wpcom client id
 @param clientSecret wpcom secret
 @param success success block
 @param failure failure block
 */
- (void)createWPComAccountWithGoogle:(NSString *)token
                           andLocale:(NSString *)locale
                         andClientID:(NSString *)clientID
                     andClientSecret:(NSString *)clientSecret
                             success:(WordPressComServiceSuccessBlock)success
                             failure:(WordPressComServiceFailureBlock)failure;

/**
 *  @brief      Validates a WordPress.com blog with the specified parameters.
 *
 *  @param      blogUrl     The url of the blog to validate.  Cannot be nil.
 *  @param      blogTitle   The title of the blog.  Can be nil.
 *  @param      success     The block to execute on success.  Can be nil.
 *  @param      failure     The block to execute on failure.  Can be nil.
 */
- (void)validateWPComBlogWithUrl:(NSString *)blogUrl
                    andBlogTitle:(NSString *)blogTitle
                   andLanguageId:(NSString *)languageId
                     andClientID:(NSString *)clientID
                 andClientSecret:(NSString *)clientSecret
                         success:(WordPressComServiceSuccessBlock)success
                         failure:(WordPressComServiceFailureBlock)failure;

/**
 *  @brief      Creates a WordPress.com blog with the specified parameters.
 *
 *  @param      blogUrl     The url of the blog to validate.  Cannot be nil.
 *  @param      blogTitle   The title of the blog.  Can be nil.
 *  @param      visibility  The visibility of the new blog.
 *  @param      success     The block to execute on success.  Can be nil.
 *  @param      failure     The block to execute on failure.  Can be nil.
 */
- (void)createWPComBlogWithUrl:(NSString *)blogUrl
                  andBlogTitle:(NSString *)blogTitle
                 andLanguageId:(NSString *)languageId
             andBlogVisibility:(WordPressComServiceBlogVisibility)visibility
                   andClientID:(NSString *)clientID
               andClientSecret:(NSString *)clientSecret
                       success:(WordPressComServiceSuccessBlock)success
                       failure:(WordPressComServiceFailureBlock)failure;

@end
