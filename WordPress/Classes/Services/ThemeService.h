#import "CoreDataService.h"

@class Blog;
@class Theme;
@class WPAccount;

typedef void(^ThemeServiceSuccessBlock)(void);
typedef void(^ThemeServiceThemeRequestSuccessBlock)(Theme *theme);
typedef void(^ThemeServiceThemesRequestSuccessBlock)(NSArray<Theme *> *themes, BOOL hasMore, NSInteger totalThemeCount);
typedef void(^ThemeServiceFailureBlock)(NSError *error);

@interface ThemeService : CoreDataService

#pragma mark - Themes availability

/**
 *  @brief      Call this method to know if a certain blog supports theme services.
 *  @details    Right now only WordPress.com blogs support theme services.
 *
 *  @param      blog        The blog to query for theme services support.  Cannot be nil.
 *
 *  @returns    YES if the blog supports theme services, NO otherwise.
 */
- (BOOL)blogSupportsThemeServices:(Blog *)blog;

#pragma mark - Remote queries: Getting theme info

/**
 *  @brief      Gets the active theme for a specific blog.
 *
 *  @param      blogId      The blog to get the active theme for.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 *  @returns    The progress object.
 */
- (NSProgress *)getActiveThemeForBlog:(Blog *)blog
                              success:(ThemeServiceThemeRequestSuccessBlock)success
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
 *  @param      page        Results page to return.
 *  @param      sync        Whether to remove unsynced results.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 *  @returns    The progress object.
 */
- (NSProgress *)getThemesForBlog:(Blog *)blog
                            page:(NSInteger)page
                            sync:(BOOL)sync
                         success:(ThemeServiceThemesRequestSuccessBlock)success
                         failure:(ThemeServiceFailureBlock)failure;

- (NSProgress *)getCustomThemesForBlog:(Blog *)blog
                                  sync:(BOOL)sync
                               success:(ThemeServiceThemesRequestSuccessBlock)success
                               failure:(ThemeServiceFailureBlock)failure;

#pragma mark - Remote queries: Activating themes

/**
 *  @brief      Activates the specified theme for the specified blog.
 *
 *  @param      themeId     The theme to activate.  Cannot be nil.
 *  @param      blogId      The target blog.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 *  @returns    The progress object.
 */
- (NSProgress *)activateTheme:(Theme *)theme
                      forBlog:(Blog *)blog
                      success:(ThemeServiceThemeRequestSuccessBlock)success
                      failure:(ThemeServiceFailureBlock)failure;

#pragma mark - Remote queries: Installing themes

/**
 *  @brief      Installs the specified theme for the specified blog.
 *
 *  @param      themeId     The theme to install.  Cannot be nil.
 *  @param      blogId      The target blog.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 *  @returns    The progress object.
 */
- (NSProgress *)installTheme:(Theme *)theme
                      forBlog:(Blog *)blog
                      success:(ThemeServiceSuccessBlock)success
                      failure:(ThemeServiceFailureBlock)failure;



@end
