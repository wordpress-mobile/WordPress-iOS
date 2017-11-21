#import <Foundation/Foundation.h>
#import "BlogServiceRemote.h"
#import "SiteServiceRemoteWordPressComREST.h"

typedef void (^BlogDetailsHandler)(RemoteBlog * _Null_unspecified remoteBlog);
typedef void (^SettingsHandler)(RemoteBlogSettings * _Null_unspecified settings);

@interface BlogServiceRemoteREST : SiteServiceRemoteWordPressComREST <BlogServiceRemote>

/**
 *  @brief      Synchronizes a blog and its top-level details.
 *
 *  @note       Requires WPCOM/Jetpack APIs.
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)syncBlogWithSuccess:(_Null_unspecified BlogDetailsHandler)success
                    failure:(void (^ _Null_unspecified)(NSError * _Null_unspecified error))failure;

/**
 *  @brief      Synchronizes a blog's settings.
 *
 *  @note       Requires WPCOM/Jetpack APIs.
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)syncBlogSettingsWithSuccess:(_Null_unspecified SettingsHandler)success
                            failure:(void (^ _Null_unspecified)(NSError * _Null_unspecified error))failure;

/**
 *  @brief      Updates the blog settings.
 *
 *  @note       Requires WPCOM/Jetpack APIs.
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)updateBlogSettings:(RemoteBlogSettings * _Null_unspecified)remoteBlogSettings
                   success:(SuccessHandler _Null_unspecified)success
                   failure:(void (^ _Null_unspecified)(NSError * _Null_unspecified error))failure;


/**
 *  @brief      Fetch site info for the specified site address.
 *
 *  @note       Uses anonymous API
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)fetchSiteInfoForAddress:(NSString * _Null_unspecified)siteAddress
                        success:(void(^ _Null_unspecified)(NSDictionary * _Null_unspecified siteInfoDict))success
                        failure:(void (^ _Null_unspecified)(NSError * _Null_unspecified error))failure;

/**
 *  @brief      Fetch timezone information
 *
 *  @note       Uses anonymous API
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */

- (void)fetchTimeZoneList:(void(^_Nullable)(NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> * _Nonnull resultDict))success
                  failure:(void (^_Nullable)(NSError * _Nullable error))failure;

@end
