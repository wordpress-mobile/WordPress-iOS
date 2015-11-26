#import "ServiceRemoteREST.h"

@class Blog;
@class RemoteTheme;

typedef void(^ThemeServiceRemoteSuccessBlock)();
typedef void(^ThemeServiceRemoteThemeRequestSuccessBlock)(RemoteTheme *theme);
typedef void(^ThemeServiceRemoteThemesRequestSuccessBlock)(NSArray<RemoteTheme *> *themes, BOOL hasMore);
typedef void(^ThemeServiceRemoteThemeIdentifiersRequestSuccessBlock)(NSArray *themeIdentifiers);
typedef void(^ThemeServiceRemoteFailureBlock)(NSError *error);

@interface ThemeServiceRemote : ServiceRemoteREST

#pragma mark - Getting themes

/**
 *  @brief      Gets the active theme for a specific blog.
 *
 *  @param      blogId      The ID of the blog to get the active theme for.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 *  @returns    The asynch operation triggered by this call.
 */
- (NSOperation *)getActiveThemeForBlogId:(NSNumber *)blogId
                                 success:(ThemeServiceRemoteThemeRequestSuccessBlock)success
                                 failure:(ThemeServiceRemoteFailureBlock)failure;

/**
 *  @brief      Gets the list of purchased-theme-identifiers for a blog.
 *
 *  @param      blogId      The ID of the blog to get the themes for.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 *  @returns    The asynch operation triggered by this call.
 */
- (NSOperation *)getPurchasedThemesForBlogId:(NSNumber *)blogId
                                     success:(ThemeServiceRemoteThemeIdentifiersRequestSuccessBlock)success
                                     failure:(ThemeServiceRemoteFailureBlock)failure;

/**
 *  @brief      Gets information for a specific theme.
 *
 *  @param      themeId     The identifier of the theme to request info for.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 *  @returns    The asynch operation triggered by this call.
 */
- (NSOperation *)getThemeId:(NSString*)themeId
                    success:(ThemeServiceRemoteThemeRequestSuccessBlock)success
                    failure:(ThemeServiceRemoteFailureBlock)failure;

/**
 *  @brief      Gets the list of WP.com available themes.
 *  @details    Includes premium themes even if not purchased.  Don't call this method if the list
 *              you want to retrieve is for a specific blog.  Use getThemesForBlogId instead.
 *
 *  @param      page        Results page to return.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 *  @returns    The asynch operation triggered by this call.
 */
- (NSOperation *)getThemesPage:(NSInteger)page
                       success:(ThemeServiceRemoteThemesRequestSuccessBlock)success
                       failure:(ThemeServiceRemoteFailureBlock)failure;

/**
 *  @brief      Gets the list of available themes for a blog.
 *  @details    Includes premium themes even if not purchased.  The only difference with the
 *              regular getThemes method is that legacy themes that are no longer available to new
 *              blogs, can be accessible for older blogs through this call.  This means that
 *              whenever we need to show the list of themes a blog can use, we should be calling
 *              this method and not getThemes.
 *
 *  @param      blogId      The ID of the blog to get the themes for.  Cannot be nil.
 *  @param      page        Results page to return.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 *  @returns    The asynch operation triggered by this call.
 */
- (NSOperation *)getThemesForBlogId:(NSNumber *)blogId
                               page:(NSInteger)page
                            success:(ThemeServiceRemoteThemesRequestSuccessBlock)success
                            failure:(ThemeServiceRemoteFailureBlock)failure;

#pragma mark - Activating themes

/**
 *  @brief      Activates the specified theme for the specified blog.
 *
 *  @param      themeId     The ID of the theme to activate.  Cannot be nil.
 *  @param      blogId      The ID of the target blog.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 *  @returns    The asynch operation triggered by this call.
 */
- (NSOperation *)activateThemeId:(NSString*)themeId
                       forBlogId:(NSNumber *)blogId
                         success:(ThemeServiceRemoteThemeRequestSuccessBlock)success
                         failure:(ThemeServiceRemoteFailureBlock)failure;

@end
