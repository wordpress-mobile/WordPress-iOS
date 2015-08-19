#import <Foundation/Foundation.h>
@class RemoteBlogSettings;
@class Blog;
@class Publicizer;

typedef void (^SettingsHandler)(RemoteBlogSettings *settings);
typedef void (^OptionsHandler)(NSDictionary *options);
typedef void (^PostFormatsHandler)(NSDictionary *postFormats);
typedef void (^ConnectionsHandler)(NSArray *connections);
typedef void (^AuthorizationHandler)(NSDictionary *authorization);
typedef void (^MultiAuthorCheckHandler)(BOOL isMultiAuthor);
typedef void (^SuccessHandler)();

@protocol BlogServiceRemote <NSObject>

/**
 *  @brief      Checks if a blog has multiple authors.
 *
 *  @param      blog        The blog to check for multi-authors.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)checkMultiAuthorForBlog:(Blog *)blog
                        success:(MultiAuthorCheckHandler)success
                        failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Synchronizes a blog's options.
 *
 *  @param      blog        The blog to synchronize.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)syncOptionsForBlog:(Blog *)blog
                   success:(OptionsHandler)success
                   failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Synchronizes a blog's post formats.
 *
 *  @param      blog        The blog to synchronize.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)syncPostFormatsForBlog:(Blog *)blog
                       success:(PostFormatsHandler)success
                       failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Synchronizes a blog's 3rd party (Publicize) connections
 *
 *  @param      blog        The blog to synchronize.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)syncConnectionsForBlog:(Blog *)blog
                       success:(ConnectionsHandler)success
                       failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Check authorization for a 3rd party (Publicize) connection
 *
 *  @param      service     The service to connect.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)checkAuthorizationForPublicizer:(Publicizer *)service
                                success:(AuthorizationHandler)success
                                failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Connect a blog's 3rd party (Publicize) connection
 *
 *  @param      service       The service to connect.  Cannot be nil.
 *  @param      authorization Authorization to connect.  Cannot be nil.
 *  @param      success       The block that will be executed on success.  Can be nil.
 *  @param      failure       The block that will be executed on failure.  Can be nil.
 */
- (void)connectPublicizer:(Publicizer *)service
        withAuthorization:(NSDictionary *)token
                  success:(ConnectionsHandler)success
                  failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Disconnect a blog's 3rd party (Publicize) connection
 *
 *  @param      service     The service to disconnect.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)disconnectPublicizer:(Publicizer *)service
                     success:(ConnectionsHandler)success
                     failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Synchronizes a blog's settings.
 *
 *  @param      blog        The blog to synchronize.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)syncSettingsForBlog:(Blog *)blog
                   success:(SettingsHandler)success
                   failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Updates the blog settings.
 *
 *  @param      blog        The blog to update.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)updateSettingsForBlog:(Blog *)blog
                    success:(SuccessHandler)success
                    failure:(void (^)(NSError *error))failure;

@end
