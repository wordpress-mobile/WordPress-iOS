#import <Foundation/Foundation.h>

@class RemoteBlogSettings;
@class Publicizer;

typedef void (^SettingsHandler)(RemoteBlogSettings *settings);
typedef void (^OptionsHandler)(NSDictionary *options);
typedef void (^PostFormatsHandler)(NSDictionary *postFormats);
typedef void (^ConnectionsHandler)(NSArray *connections);
typedef void (^AuthorizationHandler)(NSArray *accounts);
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
- (void)checkMultiAuthorForBlogID:(NSNumber *)blogID
                          success:(MultiAuthorCheckHandler)success
                          failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Synchronizes a blog's options.
 *
 *  @param      blog        The blog to synchronize.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)syncOptionsForBlogID:(NSNumber *)blogID
                     success:(OptionsHandler)success
                     failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Synchronizes a blog's post formats.
 *
 *  @param      blog        The blog to synchronize.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)syncPostFormatsForBlogID:(NSNumber *)blogID
                         success:(PostFormatsHandler)success
                         failure:(void (^)(NSError *error))failure;


/**
 *  @brief      Synchronizes a blog's settings.
 *
 *  @param      blog        The blog to synchronize.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)syncSettingsForBlogID:(NSNumber *)blogID
                      success:(SettingsHandler)success
                      failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Updates the blog settings.
 *
 *  @param      blog        The blog to update.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)updateBlogSettings:(RemoteBlogSettings *)remoteBlogSettings
                 forBlogID:(NSNumber *)blogID
                   success:(SuccessHandler)success
                   failure:(void (^)(NSError *error))failure;

@end
