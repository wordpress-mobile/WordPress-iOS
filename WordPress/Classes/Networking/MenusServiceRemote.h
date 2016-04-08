#import "ServiceRemoteREST.h"

extern NSString * const MenusRemoteKeyID;
extern NSString * const MenusRemoteKeyMenu;
extern NSString * const MenusRemoteKeyMenus;
extern NSString * const MenusRemoteKeyLocations;
extern NSString * const MenusRemoteKeyContentID;
extern NSString * const MenusRemoteKeyDescription;
extern NSString * const MenusRemoteKeyLinkTarget;
extern NSString * const MenusRemoteKeyLinkTitle;
extern NSString * const MenusRemoteKeyName;
extern NSString * const MenusRemoteKeyType;
extern NSString * const MenusRemoteKeyTypeFamily;
extern NSString * const MenusRemoteKeyTypeLabel;
extern NSString * const MenusRemoteKeyURL;
extern NSString * const MenusRemoteKeyItems;
extern NSString * const MenusRemoteKeyDeleted;
extern NSString * const MenusRemoteKeyLocationDefaultState;

@class Blog;
@class RemoteMenu;
@class RemoteMenuItem;
@class RemoteMenuLocation;

typedef void(^MenusServiceRemoteSuccessBlock)();
typedef void(^MenusServiceRemoteMenuRequestSuccessBlock)(RemoteMenu *menu);
typedef void(^MenusServiceRemoteMenusRequestSuccessBlock)(NSArray<RemoteMenu *> *menus, NSArray<RemoteMenuLocation *> *locations);
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
          withLocations:(NSArray<NSString *> *)locationNames
              withItems:(NSArray<RemoteMenuItem *> *)updatedItems
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

@end
