#import "ServiceRemoteREST.h"

@class Blog;
@class RemoteMenu;
@class RemoteMenuItem;

typedef void(^MenusServiceRemoteSuccessBlock)();
typedef void(^MenusServiceRemoteMenuRequestSuccessBlock)(RemoteMenu *menu);
typedef void(^MenusServiceRemoteMenusRequestSuccessBlock)(NSArray *menus, NSArray *locations);
typedef void(^MenusServiceRemoteFailureBlock)(NSError *error);

@interface MenusServiceRemote : ServiceRemoteREST

#pragma mark - Remote queries: Creating and modifying menus

/**
 *  @brief      Create a new menu on a blog.
 *
 *  @param      menuName    The name of the new menu to be created.  Cannot be nil.
 *  @param      blog        The blog to create the menu on.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 */
- (void)createMenuWithName:(NSString *)menuName
                      blog:(Blog *)blog
                   success:(MenusServiceRemoteMenuRequestSuccessBlock)success
                   failure:(MenusServiceRemoteFailureBlock)failure;

/**
 *  @brief      Update a menu on a blog.
 *
 *  @param      menu        The updated menu object to update remotely.  Cannot be nil.
 *  @param      blog        The blog to update the menu on.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 */
- (void)updateMenuForId:(NSString *)menuId
                   blog:(Blog *)blog
               withName:(NSString *)updatedName
              withItems:(NSArray <RemoteMenuItem *> *)updatedItems
           success:(MenusServiceRemoteMenuRequestSuccessBlock)success
           failure:(MenusServiceRemoteFailureBlock)failure;

/**
 *  @brief      Delete a menu from a blog.
 *
 *  @param      menuId      The menuId of the menu to delete remotely.  Cannot be nil.
 *  @param      blog        The blog to delete the menu from.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 */
- (void)deleteMenuForId:(NSString *)menuId
              blog:(Blog *)blog
           success:(MenusServiceRemoteSuccessBlock)success
           failure:(MenusServiceRemoteFailureBlock)failure;

#pragma mark - Remote queries: Getting menus

/**
 *  @brief      Gets the available menus for a specific blog.
 *
 *  @param      blog        The blog to get the available menus for.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 */
- (void)getMenusForBlog:(Blog *)blog
                success:(MenusServiceRemoteMenusRequestSuccessBlock)success
                failure:(MenusServiceRemoteFailureBlock)failure;

/**
 *  @brief      Gets a single menu for a specific blog.
 *
 *  @param      menuId      The id of the specific menu.  Cannot be nil.
 *  @param      blog        The blog to get the specific menu for.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 */
- (void)getMenuForId:(NSString *)menuId
                 blog:(Blog *)blog
              success:(MenusServiceRemoteMenuRequestSuccessBlock)success
              failure:(MenusServiceRemoteFailureBlock)failure;

@end
