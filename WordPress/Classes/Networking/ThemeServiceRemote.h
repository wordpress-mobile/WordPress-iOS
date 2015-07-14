#import "ServiceRemoteREST.h"

typedef void(^ThemeServiceSuccessBlock)();
typedef void(^ThemeServiceThemeRequestSuccessBlock)(NSDictionary *theme);
typedef void(^ThemeServiceThemesRequestSuccessBlock)(NSArray *themes);
typedef void(^ThemeServiceFailureBlock)(NSError *error);

@class Blog;

@interface ThemeServiceRemote : ServiceRemoteREST

#pragma mark - Getting themes

/**
 *  @brief      Gets the active theme for a specific blog.
 *
 *  @param      blogId      The ID of the blog to get the active theme for.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 */
- (void)getActiveThemeForBlogId:(NSNumber *)blogId
                        success:(ThemeServiceThemeRequestSuccessBlock)success
                        failure:(ThemeServiceFailureBlock)failure;

/**
 *  @brief      Gets the list of purchased themes for a blog.
 *
 *  @param      blogId      The ID of the blog to get the themes for.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 */
- (void)getPurchasedThemesForBlogId:(NSNumber *)blogId
                            success:(ThemeServiceThemesRequestSuccessBlock)success
                            failure:(ThemeServiceFailureBlock)failure;

/**
 *  @brief      Gets information for a specific theme.
 *
 *  @param      themeId     The identifier of the theme to request info for.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 */
- (void)getThemeId:(NSString*)themeId
           success:(ThemeServiceThemeRequestSuccessBlock)success
           failure:(ThemeServiceFailureBlock)failure;

/**
 *  @brief      Gets the list of WP.com available themes.
 *  @details    Includes premium themes even if not purchased.  Don't call this method if the list
 *              you want to retrieve is for a specific blog.  Use getThemesForBlogId instead.
 *
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 */
- (void)getThemes:(ThemeServiceThemesRequestSuccessBlock)success
          failure:(ThemeServiceFailureBlock)failure;

/**
 *  @brief      Gets the list of available themes for a blog.
 *  @details    Includes premium themes even if not purchased.  The only difference with the
 *              regular getThemes method is that legacy themes that are no longer available to new
 *              blogs, can be accessible for older blogs through this call.  This means that
 *              whenever we need to show the list of themes a blog can use, we should be calling
 *              this method and not getThemes.
 *
 *  @param      blogId      The ID of the blog to get the themes for.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 */
- (void)getThemesForBlogId:(NSNumber *)blogId
                   success:(ThemeServiceThemesRequestSuccessBlock)success
                   failure:(ThemeServiceFailureBlock)failure;

#pragma mark - Activating themes

/**
 *  @brief      Activates the specified theme for the specified blog.
 *
 *  @param      themeId     The ID of the theme to activate.  Cannot be nil.
 *  @param      blogId      The ID of the target blog.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 */
- (void)activateThemeId:(NSString*)themeId
              forBlogId:(NSNumber *)blogId
                success:(ThemeServiceSuccessBlock)success
                failure:(ThemeServiceFailureBlock)failure;

@end
