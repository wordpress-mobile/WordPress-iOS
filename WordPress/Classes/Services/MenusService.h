#import "LocalCoreDataService.h"

NS_ASSUME_NONNULL_BEGIN

@class Blog;
@class Menu;
@class MenuLocation;
@class MenuItem;

typedef void(^MenusServiceSuccessBlock)(void);
typedef void(^MenusServiceCreateOrUpdateMenuRequestSuccessBlock)(void);
typedef void(^MenusServiceMenusRequestSuccessBlock)(NSArray<Menu *> * _Nullable menus);
typedef void(^MenusServiceLocationsRequestSuccessBlock)(NSArray<MenuLocation *> * _Nullable locations);
typedef void(^MenusServiceFailureBlock)(NSError *error);

@interface MenusService : LocalCoreDataService

#pragma mark - Menus availability

/**
 *  @brief      Call this method to know if a certain blog supports menus customization.
 *  @details    Right now only blogs with WP.com or connected via Jetpack support menus customization.
 *
 *  @param      blog        The blog to query for menus customization support.  Cannot be nil.
 *
 *  @returns    YES if the blog supports menus customization, NO otherwise.
 */
- (BOOL)blogSupportsMenusCustomization:(Blog *)blog;

#pragma mark - Getting menus and locations

/**
 *  @brief      Syncs the available menu and location objects for a specific blog.
 *
 *  @param      blog        The blog to get the available menus for.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 */
- (void)syncMenusForBlog:(Blog *)blog
                 success:(nullable MenusServiceSuccessBlock)success
                 failure:(nullable MenusServiceFailureBlock)failure;

#pragma mark - Updating menus

/**
 *  @brief      Creates or updates a menu, as needed.
 *
 *  @param      menu      The updated menu object to update with local storage and remotely.  Cannot be nil.
 *  @param      blog      The blog to update a single menu on.  Cannot be nil.
 *  @param      success   The success handler.  Can be nil.
 *  @param      failure   The failure handler.  Can be nil.
 *
 */
- (void)createOrUpdateMenu:(Menu *)menu
                   forBlog:(Blog *)blog
                   success:(nullable MenusServiceCreateOrUpdateMenuRequestSuccessBlock)success
                   failure:(nullable MenusServiceFailureBlock)failure;

/**
 *  @brief      Delete a menu.
 *
 *  @param      menu      The menu object to delete from local storage and remotely.  Cannot be nil.
 *  @param      blog      The blog to delete a single menu from.  Cannot be nil.
 *  @param      success   The success handler.  Can be nil.
 *  @param      failure   The failure handler.  Can be nil.
 *
 */
- (void)deleteMenu:(Menu *)menu
           forBlog:(Blog *)blog
           success:(nullable MenusServiceSuccessBlock)success
           failure:(nullable MenusServiceFailureBlock)failure;

/**
 *  @brief      Generate a list MenuItems from the blog's top-level pages.
 *
 *  @param      blog      The blog to use for pages.  Cannot be nil.
 *  @param      success   The success handler.  Can be nil.
 *  @param      failure   The failure handler.  Can be nil.
 *
 */
- (void)generateDefaultMenuItemsForBlog:(Blog *)blog
                                success:(nullable void(^)(NSArray <MenuItem *> * _Nullable defaultItems))success
                                failure:(nullable MenusServiceFailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
