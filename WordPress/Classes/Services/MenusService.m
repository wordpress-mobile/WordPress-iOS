#import "MenusService.h"
#import "BasePost.h"
#import "Blog.h"
#import "MenusServiceRemote.h"
#import "Menu.h"
#import "MenuItem.h"
#import "MenuLocation.h"
#import "RemoteMenu.h"
#import "RemoteMenuItem.h"
#import "RemoteMenuLocation.h"
#import "ContextManager.h"
#import "PostService.h"
#import "WordPress-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@implementation MenusService

#pragma mark - Menus availability

- (BOOL)blogSupportsMenusCustomization:(Blog *)blog
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    return [blog supports:BlogFeatureMenus];
}

#pragma mark - Remote queries: Getting menus

- (void)syncMenusForBlog:(Blog *)blog
                 success:(nullable MenusServiceSuccessBlock)success
                 failure:(nullable MenusServiceFailureBlock)failure
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSAssert([self blogSupportsMenusCustomization:blog], @"Do not call this method on unsupported blogs, check with blogSupportsMenusCustomization first.");

    if (blog.wordPressComRestApi == nil) {
        return;
    }

    MenusServiceRemote *remote = [[MenusServiceRemote alloc] initWithWordPressComRestApi:blog.wordPressComRestApi];
    [remote getMenusForBlog:blog
                    success:^(NSArray<RemoteMenu *> * _Nullable remoteMenus, NSArray<RemoteMenuLocation *> * _Nullable remoteLocations) {
        
                        [self.managedObjectContext performBlock:^{
                            
                            NSArray *locations = nil;
                            if (remoteLocations.count) {
                                locations = [self menuLocationsFromRemoteMenuLocations:remoteLocations];
                            }
                            NSArray *menus = [remoteMenus wp_map:^Menu *(RemoteMenu *remoteMenu) {
                                Menu *menu = [self menuFromRemoteMenu:remoteMenu];
                                [self refreshLocationsForMenu:menu
                                  matchingRemoteLocationNames:remoteMenu.locationNames
                                           availableLocations:locations];
                                return menu;
                            }];
                            
                            // Create a new default menu.
                            Menu *defaultMenu = [Menu newDefaultMenu:self.managedObjectContext];
                            // Ensure the default menu is the first menu in the list of menus.
                            NSMutableArray *mutableMenus = [NSMutableArray arrayWithArray:menus];
                            [mutableMenus insertObject:defaultMenu atIndex:0];
                            menus = mutableMenus;
                            
                            // Set the default menu to locations, if needed.
                            for (MenuLocation *location in locations) {
                                if (location.menu) {
                                    continue;
                                }
                                location.menu = defaultMenu;
                            }
                            
                            blog.menuLocations = [NSOrderedSet orderedSetWithArray:locations];
                            blog.menus = [NSOrderedSet orderedSetWithArray:menus];
                            
                            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
                            
                            if (success) {
                                success();
                            }
                        }];
                    }
                    failure:failure];
}

#pragma mark - Creating and updating menus

- (void)createMenuWithName:(NSString *)menuName
                      blog:(Blog *)blog
                   success:(nullable MenusServiceCreateMenuRequestSuccessBlock)success
                   failure:(nullable MenusServiceFailureBlock)failure
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSAssert([self blogSupportsMenusCustomization:blog], @"Do not call this method on unsupported blogs, check with blogSupportsMenusCustomization first.");
    
    if (blog.wordPressComRestApi == nil) {
        return;
    }

    MenusServiceRemote *remote = [[MenusServiceRemote alloc] initWithWordPressComRestApi:blog.wordPressComRestApi];
    [remote createMenuWithName:menuName
                          blog:blog
                       success:^(RemoteMenu * _Nonnull remoteMenu) {
                           [self.managedObjectContext performBlock:^{
                               if (success) {
                                   success(remoteMenu.menuID);
                               }
                           }];
                       }
                       failure:failure];
}

- (void)updateMenu:(Menu *)menu
           forBlog:(Blog *)blog
           success:(nullable MenusServiceUpdateMenuRequestSuccessBlock)success
           failure:(nullable MenusServiceFailureBlock)failure
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSParameterAssert([menu isKindOfClass:[Menu class]]);
    NSAssert([self blogSupportsMenusCustomization:blog], @"Do not call this method on unsupported blogs, check with blogSupportsMenusCustomization first.");
    
    if (blog.wordPressComRestApi == nil) {
        return;
    }

    NSMutableArray *locationNames = nil;
    if (menu.locations.count) {
        locationNames = [NSMutableArray arrayWithCapacity:menu.locations.count];
        for (MenuLocation *location in menu.locations) {
            if (location.name.length) {
                [locationNames addObject:location.name];
            }
        }
    }
    
    NSArray *remoteItems = nil;
    if (menu.items.count) {
        remoteItems = [self remoteItemsFromMenuItems:menu.items];
    }
    
    MenusServiceRemote *remote = [[MenusServiceRemote alloc] initWithWordPressComRestApi:blog.wordPressComRestApi];
    [remote updateMenuForID:menu.menuID
                       blog:blog
                   withName:menu.name
              withLocations:locationNames
                  withItems:remoteItems
                    success:^(RemoteMenu * _Nonnull remoteMenu) {
                        [self.managedObjectContext performBlock:^{
                            /*
                             Update the local menu with the fresh MenuItems from remote.
                             We need to replace the MenuItems as it's difficult to keep track of
                             which items are equal to one another, especially when a menuID is unknown.
                             */
                            menu.items = nil;
                            for (RemoteMenuItem *remoteItem in remoteMenu.items) {
                                [self addMenuItemFromRemoteMenuItem:remoteItem forMenu:menu];
                            }
                            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
                            if (success) {
                                success();
                            }
                        }];
                    }
                    failure:failure];
}

- (void)deleteMenu:(Menu *)menu
           forBlog:(Blog *)blog
           success:(nullable MenusServiceSuccessBlock)success
           failure:(nullable MenusServiceFailureBlock)failure
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSParameterAssert([menu isKindOfClass:[Menu class]]);
    NSAssert([self blogSupportsMenusCustomization:blog], @"Do not call this method on unsupported blogs, check with blogSupportsMenusCustomization first.");
    
    if (blog.wordPressComRestApi == nil) {
        return;
    }

    void(^completeMenuDeletion)() = ^() {
        [self.managedObjectContext performBlock:^{
            [self.managedObjectContext deleteObject:menu];
            [self.managedObjectContext processPendingChanges];
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
            if (success) {
                success();
            }
        }];
    };
    
    if (!menu.menuID.integerValue) {
        // Menu was only created locally, no need to delete remotely.
        completeMenuDeletion();
        return;
    }
    
    MenusServiceRemote *remote = [[MenusServiceRemote alloc] initWithWordPressComRestApi:blog.wordPressComRestApi];
    [remote deleteMenuForID:menu.menuID
                       blog:blog
                    success:completeMenuDeletion
                    failure:failure];
}

- (void)generateDefaultMenuItemsForBlog:(Blog *)blog
                                success:(nullable void(^)(NSArray <MenuItem *> * _Nullable defaultItems))success
                                failure:(nullable MenusServiceFailureBlock)failure
{
    // Get the latest list of Pages available to the site.
    PostServiceSyncOptions *options = [[PostServiceSyncOptions alloc] init];
    options.statuses = @[PostStatusPublish];
    options.order = PostServiceResultsOrderAscending;
    options.orderBy = PostServiceResultsOrderingByTitle;
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:self.managedObjectContext];
    [postService syncPostsOfType:PostServiceTypePage
                     withOptions:options
                         forBlog:blog
                         success:^(NSArray *pages) {
                             [self.managedObjectContext performBlock:^{
                                 
                                 if (!pages.count) {
                                     success(nil);
                                     return;
                                 }
                                 NSMutableArray *items = [NSMutableArray arrayWithCapacity:pages.count];
                                 // Create menu items for the top parent pages.
                                 for (Page *page in pages) {
                                     if ([page.parentID integerValue] > 0) {
                                         continue;
                                     }
                                     MenuItem *pageItem = [NSEntityDescription insertNewObjectForEntityForName:[MenuItem entityName] inManagedObjectContext:self.managedObjectContext];
                                     pageItem.contentID = page.postID;
                                     pageItem.name = page.titleForDisplay;
                                     pageItem.type = MenuItemTypePage;
                                     [items addObject:pageItem];
                                 }
                                 
                                 [[ContextManager sharedInstance] saveContext:self.managedObjectContext];

                                 if (success) {
                                     success(items);
                                 }
                             }];
                         }
                         failure:failure];
}

#pragma mark - Menu managed objects from RemoteMenu objects

- (Menu *)menuFromRemoteMenu:(RemoteMenu *)remoteMenu
{
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[Menu entityName]
                                                         inManagedObjectContext:self.managedObjectContext];
    
    Menu *menu = [[Menu alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:self.managedObjectContext];
    menu.name = remoteMenu.name;
    menu.details = remoteMenu.details;
    menu.menuID = remoteMenu.menuID;
    for (RemoteMenuItem *remoteItem in remoteMenu.items) {
        [self addMenuItemFromRemoteMenuItem:remoteItem forMenu:menu];
    }
    
    return menu;
}

#pragma mark - MenuItem managed objects via RemoteMenuItem objects

- (MenuItem *)addMenuItemFromRemoteMenuItem:(RemoteMenuItem *)remoteMenuItem forMenu:(Menu *)menu
{
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[MenuItem entityName]
                                                         inManagedObjectContext:self.managedObjectContext];
    
    MenuItem *item = [[MenuItem alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:self.managedObjectContext];
    item.itemID = remoteMenuItem.itemID;
    item.contentID = remoteMenuItem.contentID;
    item.details = remoteMenuItem.details;
    item.linkTarget = remoteMenuItem.linkTarget;
    item.linkTitle = remoteMenuItem.linkTitle;
    item.name = remoteMenuItem.name;
    item.type = remoteMenuItem.type;
    item.typeFamily = remoteMenuItem.typeFamily;
    item.typeLabel = remoteMenuItem.typeLabel;
    item.urlStr = remoteMenuItem.urlStr;
    item.menu = menu;
    
    if (remoteMenuItem.children) {
        
        for (RemoteMenuItem *childRemoteItem in remoteMenuItem.children) {
            MenuItem *childItem = [self addMenuItemFromRemoteMenuItem:childRemoteItem forMenu:menu];
            childItem.parent = item;
        }
    }
    
    return item;
}

#pragma mark - MenuLocations managed objects from RemoteMenuLocation objects

- (NSArray *)menuLocationsFromRemoteMenuLocations:(NSArray<RemoteMenuLocation *> *)remoteMenuLocations
{
    NSMutableArray *locations = [NSMutableArray arrayWithCapacity:remoteMenuLocations.count];
    
    [self.managedObjectContext performBlockAndWait:^{
        
        // remove the current menus related to the blog
        for (RemoteMenuLocation *remoteMenuLocation in remoteMenuLocations) {
            [locations addObject:[self menuLocationFromRemoteMenuLocation:remoteMenuLocation]];
        }
    }];
    
    return [NSArray arrayWithArray:locations];
}

- (MenuLocation *)menuLocationFromRemoteMenuLocation:(RemoteMenuLocation *)remoteMenuLocation
{
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[MenuLocation entityName]
                                                         inManagedObjectContext:self.managedObjectContext];
    
    MenuLocation *location = [[MenuLocation alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:self.managedObjectContext];
    location.name = remoteMenuLocation.name;
    location.details = remoteMenuLocation.details;
    location.defaultState = remoteMenuLocation.defaultState;
    
    return location;
}

#pragma mark - Local storage

- (void)refreshLocationsForMenu:(Menu *)menu
    matchingRemoteLocationNames:(nullable NSArray *)remoteLocationNames
             availableLocations:(nullable NSArray *)locations
{
    NSArray *menuLocations = nil;
    if (remoteLocationNames.count) {
        menuLocations = [locations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name IN %@", remoteLocationNames]];
    }
    if (menuLocations.count) {
        [menu setLocations:[NSSet setWithArray:menuLocations]];
    }
}

- (Menu *)findMenuWithId:(NSString *)menuId
{
    NSParameterAssert([menuId isKindOfClass:[NSString class]]);
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[Menu entityName]];
    request.predicate = [NSPredicate predicateWithFormat:@"menuId == %@", menuId];
    
    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"Fetch request for Menu failed: %@", error);
    }
    
    Menu *menu = [results firstObject];
    return menu;
}

#pragma mark - RemoteMenu objects from Menu objects

- (NSArray *)remoteItemsFromMenuItems:(NSOrderedSet<MenuItem *> *)menuItems
{
    NSMutableArray *remoteItems = [NSMutableArray arrayWithCapacity:menuItems.count];
    for (MenuItem *item in menuItems) {
        // Only add top-level items since MenuItem keeps all associated items under it's children relationship.
        if (item.parent) {
            continue;
        }
        // Children of item will be added as remoteItem.children.
        RemoteMenuItem *remoteItem = [self remoteItemFromItem:item];
        [remoteItems addObject:remoteItem];
    }
    
    return [NSArray arrayWithArray:remoteItems];
}

- (RemoteMenuItem *)remoteItemFromItem:(MenuItem *)item
{
    RemoteMenuItem *remoteItem = [[RemoteMenuItem alloc] init];
    remoteItem.itemID = item.itemID;
    remoteItem.contentID = item.contentID;
    remoteItem.details = item.details;
    remoteItem.linkTarget = item.linkTarget;
    remoteItem.linkTitle = item.linkTitle;
    remoteItem.name = item.name;
    remoteItem.type = item.type;
    
    if (remoteItem.type) {
        // Override the type_family param based on the type.
        // This is a weird behavior of the API and is not documented.
        NSString *typeFamily = item.typeFamily;
        if ([remoteItem.type isEqualToString:MenuItemTypeCustom]) {
            typeFamily = @"custom";
        } else if ([remoteItem.type isEqualToString:MenuItemTypeTag] || [remoteItem.type isEqualToString:MenuItemTypeCategory]){
            typeFamily = @"taxonomy";
        } else {
            typeFamily = @"post_type";
        }
        if (typeFamily.length) {
            remoteItem.typeFamily = typeFamily;
        }
    }
    
    remoteItem.typeLabel = item.typeLabel;
    remoteItem.urlStr = item.urlStr;
    
    if (item.children.count) {
        NSMutableArray *childRemoteItems = [NSMutableArray arrayWithCapacity:item.children.count];
        for (MenuItem *childItem in item.children) {
            [childRemoteItems addObject:[self remoteItemFromItem:childItem]];
        }
        remoteItem.children = childRemoteItems;
    }
    
    return remoteItem;
}

@end

NS_ASSUME_NONNULL_END
