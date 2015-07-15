#import "LocalCoreDataService.h"
#import "Theme.h"

@class Blog;
@class WPAccount;

typedef void(^ThemeServiceSuccessBlock)();
typedef void(^ThemeServiceThemeRequestSuccessBlock)(Theme *theme);
typedef void(^ThemeServiceThemesRequestSuccessBlock)(NSArray *themes);
typedef void(^ThemeServiceFailureBlock)(NSError *error);

@interface ThemeService : LocalCoreDataService

#pragma mark - Themes availability

/**
 *  @brief      Call this method to know if a certain account supports theme services.
 *  @details    Right now only WordPress.com accounts support theme services.
 *
 *  @param      account     The account to query for theme services support.  Cannot be nil.
 *
 *  @returns    YES if the account supports theme services, NO otherwise.
 */
- (BOOL)accountSupportsThemeServices:(WPAccount *)account;

/**
 *  @brief      Call this method to know if a certain blog supports theme services.
 *  @details    Right now only WordPress.com blogs support theme services.
 *
 *  @param      blog        The blog to query for theme services support.  Cannot be nil.
 *
 *  @returns    YES if the blog supports theme services, NO otherwise.
 */
- (BOOL)blogSupportsThemeServices:(Blog *)blog;

#pragma mark - Getting themes

/**
 *  @brief      Gets the active theme for a specific blog.
 *
 *  @param      blogId      The blog to get the active theme for.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 *  @returns    The asynch operation triggered by this call.
 */
- (NSOperation *)getActiveThemeForBlog:(Blog *)blog
                               success:(ThemeServiceThemeRequestSuccessBlock)success
                               failure:(ThemeServiceFailureBlock)failure;

/**
 *  @brief      Gets the list of purchased themes for a blog.
 *
 *  @param      blogId      The blog to get the purchased themes for.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 *  @returns    The asynch operation triggered by this call.
 */
- (NSOperation *)getPurchasedThemesForBlog:(Blog *)blog
                                   success:(ThemeServiceThemesRequestSuccessBlock)success
                                   failure:(ThemeServiceFailureBlock)failure;


/**
 *  @brief      Gets information for a specific theme.
 *
 *  @param      themeId     The identifier of the theme to request info for.  Cannot be nil.
 *  @param      account     The account to get the theme from.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 *  @returns    The asynch operation triggered by this call.
 */
- (NSOperation *)getThemeId:(NSString*)themeId
                 forAccount:(WPAccount *)account
                    success:(ThemeServiceThemeRequestSuccessBlock)success
                    failure:(ThemeServiceFailureBlock)failure;

/**
 *  @brief      Gets the list of WP.com available themes.
 *  @details    Includes premium themes even if not purchased.  Don't call this method if the list
 *              you want to retrieve is for a specific blog.  Use getThemesForBlogId instead.
 *
 *  @param      account     The account to get the theme from.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 *  @returns    The asynch operation triggered by this call.
 */
- (NSOperation *)getThemesForAccount:(WPAccount *)account
                             success:(ThemeServiceThemesRequestSuccessBlock)success
                             failure:(ThemeServiceFailureBlock)failure;

/**
 *  @brief      Gets the list of available themes for a blog.
 *  @details    Includes premium themes even if not purchased.  The only difference with the
 *              regular getThemes method is that legacy themes that are no longer available to new
 *              blogs, can be accessible for older blogs through this call.  This means that
 *              whenever we need to show the list of themes a blog can use, we should be calling
 *              this method and not getThemes.
 *
 *  @param      blogId      The blog to get the themes for.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 *  @returns    The asynch operation triggered by this call.
 */
- (NSOperation *)getThemesForBlog:(Blog *)blog
                          success:(ThemeServiceThemesRequestSuccessBlock)success
                          failure:(ThemeServiceFailureBlock)failure;

#pragma mark - Activating themes

/**
 *  @brief      Activates the specified theme for the specified blog.
 *
 *  @param      themeId     The theme to activate.  Cannot be nil.
 *  @param      blogId      The target blog.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 *  @returns    The asynch operation triggered by this call.
 */
- (NSOperation *)activateTheme:(Theme *)theme
                       forBlog:(Blog *)blog
                       success:(ThemeServiceSuccessBlock)success
                       failure:(ThemeServiceFailureBlock)failure;

@end
