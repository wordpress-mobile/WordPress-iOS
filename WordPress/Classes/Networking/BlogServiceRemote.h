#import <Foundation/Foundation.h>

@class RemoteBlogSettings;
@class RemotePostType;

typedef void (^SettingsHandler)(RemoteBlogSettings *settings);
typedef void (^OptionsHandler)(NSDictionary *options);
typedef void (^PostTypesHandler)(NSArray <RemotePostType *> *postTypes);
typedef void (^PostFormatsHandler)(NSDictionary *postFormats);
typedef void (^MultiAuthorCheckHandler)(BOOL isMultiAuthor);
typedef void (^SuccessHandler)();

@protocol BlogServiceRemote <NSObject>

/**
 *  @brief      Checks if a blog has multiple authors.
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)checkMultiAuthorWithSuccess:(MultiAuthorCheckHandler)success
                            failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Synchronizes a blog's options.
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)syncOptionsWithSuccess:(OptionsHandler)success
                       failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Synchronizes a blog's post types.
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)syncPostTypesWithSuccess:(PostTypesHandler)success
                           failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Synchronizes a blog's post formats.
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)syncPostFormatsWithSuccess:(PostFormatsHandler)success
                           failure:(void (^)(NSError *error))failure;


/**
 *  @brief      Synchronizes a blog's settings.
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)syncSettingsWithSuccess:(SettingsHandler)success
                        failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Updates the blog settings.
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)updateBlogSettings:(RemoteBlogSettings *)remoteBlogSettings
                   success:(SuccessHandler)success
                   failure:(void (^)(NSError *error))failure;

@end
