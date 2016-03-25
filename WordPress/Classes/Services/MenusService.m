#import "MenusService.h"
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
#import "Page.h"

@implementation MenusService

#pragma mark - Menus availability

- (BOOL)blogSupportsMenusCustomization:(Blog *)blog
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    return blog.restApi;
}

#pragma mark - Remote queries: Getting menus

- (void)syncMenusForBlog:(Blog *)blog
                 success:(MenusServiceSuccessBlock)success
                 failure:(MenusServiceFailureBlock)failure
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSAssert([self blogSupportsMenusCustomization:blog], @"Do not call this method on unsupported blogs, check with blogSupportsMenusCustomization first.");
    
    MenusServiceRemote *remote = [[MenusServiceRemote alloc] initWithApi:blog.restApi];
    [remote getMenusForBlog:blog success:^(NSArray *remoteMenus, NSArray *remoteLocations) {
        
        [self.managedObjectContext performBlockAndWait:^{
            
            NSArray *locations = [self menuLocationsFromRemoteMenuLocations:remoteLocations];
            NSArray *menus = [remoteMenus wp_map:^Menu *(RemoteMenu *remoteMenu) {
                
                Menu *menu = [self menuFromRemoteMenu:remoteMenu];
                [self refreshLocationsForMenu:menu
                  matchingRemoteLocationNames:remoteMenu.locationNames
                           availableLocations:locations];
                
                return menu;
            }];
            
            // Create a new default menu, if needed.
            Menu *defaultMenu = [Menu defaultMenuForBlog:blog];
            if (!defaultMenu) {
                defaultMenu = [Menu newDefaultMenu:self.managedObjectContext];
            }
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
        }];
        
        if(success) {
            success();
        }
        
    } failure:failure];
}

#pragma mark - Creating and updating menus

- (void)createMenuWithName:(NSString *)menuName
                      blog:(Blog *)blog
                   success:(MenusServiceMenuRequestSuccessBlock)success
                   failure:(MenusServiceFailureBlock)failure
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSAssert([self blogSupportsMenusCustomization:blog], @"Do not call this method on unsupported blogs, check with blogSupportsMenusCustomization first.");
    
    MenusServiceRemote *remote = [[MenusServiceRemote alloc] initWithApi:blog.restApi];
    [remote createMenuWithName:menuName
                          blog:blog
                       success:^(RemoteMenu *remoteMenu) {
                           
                           [self.managedObjectContext performBlockAndWait:^{
                               
                               Menu *menu = [self menuFromRemoteMenu:remoteMenu];
                               [self refreshLocationsForMenu:menu
                                 matchingRemoteLocationNames:remoteMenu.locationNames
                                          availableLocations:[blog.menuLocations array]];
                               
                               [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
                               
                               if(success) {
                                   success(menu);
                               }
                           }];
                           
                       } failure:failure];
}

- (void)updateMenu:(Menu *)menu
           forBlog:(Blog *)blog
           success:(MenusServiceMenuRequestSuccessBlock)success
           failure:(MenusServiceFailureBlock)failure
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSParameterAssert([menu isKindOfClass:[Menu class]]);
    NSAssert([self blogSupportsMenusCustomization:blog], @"Do not call this method on unsupported blogs, check with blogSupportsMenusCustomization first.");
    
    [self.managedObjectContext performBlockAndWait:^{
        
        NSMutableArray *locationNames = [NSMutableArray arrayWithCapacity:menu.locations.count];
        for(MenuLocation *location in menu.locations) {
            if(location.name.length) {
                [locationNames addObject:location.name];
            }
        }
        
        MenusServiceRemote *remote = [[MenusServiceRemote alloc] initWithApi:blog.restApi];
        [remote updateMenuForId:menu.menuId
                           blog:blog
                       withName:menu.name
                  withLocations:locationNames
                      withItems:[self remoteItemsFromMenuItems:menu.items]
                        success:^(RemoteMenu *remoteMenu) {
                            
                            [self.managedObjectContext performBlockAndWait:^{
                                [self refreshMenu:menu withRemoteMenu:remoteMenu];
                            }];
                            
                            if(success) {
                                success(menu);
                            }
                            
                        } failure:failure];
    }];
}

- (void)deleteMenu:(Menu *)menu
           forBlog:(Blog *)blog
           success:(MenusServiceSuccessBlock)success
           failure:(MenusServiceFailureBlock)failure
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSParameterAssert([menu isKindOfClass:[Menu class]]);
    NSAssert([self blogSupportsMenusCustomization:blog], @"Do not call this method on unsupported blogs, check with blogSupportsMenusCustomization first.");
    
    MenusServiceRemote *remote = [[MenusServiceRemote alloc] initWithApi:blog.restApi];
    [remote deleteMenuForId:menu.menuId
                       blog:blog
                    success:^{
                        
                        [self.managedObjectContext performBlockAndWait:^{
                            [self.managedObjectContext deleteObject:menu];
                        }];
                        
                        success();
                        
                    } failure:failure];
}

- (void)generateDefaultMenuItemsForBlog:(Blog *)blog
                                success:(void(^)(NSArray <MenuItem *> *defaultItems))success
                                failure:(void(^)(NSError *error))failure
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
                                     pageItem.contentId = [page.postID stringValue];
                                     pageItem.name = page.titleForDisplay;
                                     pageItem.type = MenuItemTypePage;
                                     [items addObject:pageItem];
                                 }
                                 if (success) {
                                     success(items);
                                 }
                             }];
                         }
                         failure:failure];
}

#pragma mark - Menu managed objects from RemoteMenu objects

- (NSArray *)menusFromRemoteMenus:(NSArray<RemoteMenu *> *)remoteMenus
{
    NSMutableArray *menus = [NSMutableArray arrayWithCapacity:remoteMenus.count];
    for(RemoteMenu *remoteMenu in remoteMenus) {
        [menus addObject:[self menuFromRemoteMenu:remoteMenu]];
    }
    
    return [NSArray arrayWithArray:menus];
}

- (Menu *)menuFromRemoteMenu:(RemoteMenu *)remoteMenu
{
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[Menu entityName]
                                                         inManagedObjectContext:self.managedObjectContext];
    
    Menu *menu = [[Menu alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:self.managedObjectContext];
    [self refreshMenu:menu withRemoteMenu:remoteMenu];
    
    return menu;
}

#pragma mark - MenuItem managed objects via RemoteMenuItem objects

- (MenuItem *)addMenuItemFromRemoteMenuItem:(RemoteMenuItem *)remoteMenuItem forMenu:(Menu *)menu
{
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[MenuItem entityName]
                                                         inManagedObjectContext:self.managedObjectContext];
    
    MenuItem *item = [[MenuItem alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:self.managedObjectContext];
    item.itemId = remoteMenuItem.itemId;
    item.contentId = remoteMenuItem.contentId;
    item.details = remoteMenuItem.details;
    item.linkTarget = remoteMenuItem.linkTarget;
    item.linkTitle = remoteMenuItem.linkTitle;
    item.name = remoteMenuItem.name;
    item.type = remoteMenuItem.type;
    item.typeFamily = remoteMenuItem.typeFamily;
    item.typeLabel = remoteMenuItem.typeLabel;
    item.urlStr = remoteMenuItem.urlStr;
    item.menu = menu;
    
    if(remoteMenuItem.children) {
        
        for(RemoteMenuItem *childRemoteItem in remoteMenuItem.children) {
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
        for(RemoteMenuLocation *remoteMenuLocation in remoteMenuLocations) {
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

- (void)refreshMenu:(Menu *)menu withRemoteMenu:(RemoteMenu *)remoteMenu
{
    menu.name = remoteMenu.name;
    menu.details = remoteMenu.details;
    menu.menuId = remoteMenu.menuId;
    menu.items = nil;
    
    for(RemoteMenuItem *remoteItem in remoteMenu.items) {
        [self addMenuItemFromRemoteMenuItem:remoteItem forMenu:menu];
    }
}

- (void)refreshLocationsForMenu:(Menu *)menu
    matchingRemoteLocationNames:(NSArray *)remoteLocationNames
             availableLocations:(NSArray *)locations
{
    NSArray *menuLocations = nil;
    if(remoteLocationNames.count) {
        menuLocations = [locations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name IN %@", remoteLocationNames]];
    }
    
    [menu setLocations:[NSSet setWithArray:menuLocations]];
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
    for(MenuItem *item in menuItems) {
        [remoteItems addObject:[self remoteItemFromItem:item]];
    }
    
    return [NSArray arrayWithArray:remoteItems];
}

- (RemoteMenuItem *)remoteItemFromItem:(MenuItem *)item
{
    RemoteMenuItem *remoteItem = [[RemoteMenuItem alloc] init];
    remoteItem.itemId = item.itemId;
    remoteItem.contentId = item.contentId;
    remoteItem.details = item.details;
    remoteItem.linkTarget = item.linkTarget;
    remoteItem.linkTitle = item.linkTitle;
    remoteItem.name = item.name;
    remoteItem.type = item.type;
    remoteItem.typeFamily = item.typeFamily;
    remoteItem.typeLabel = item.typeLabel;
    remoteItem.urlStr = item.urlStr;
    
    if(item.children.count) {
        
        NSMutableArray *childRemoteItems = [NSMutableArray arrayWithCapacity:item.children.count];
        for(MenuItem *childItem in item.children) {
            [childRemoteItems addObject:[self remoteItemFromItem:childItem]];
        }
        remoteItem.children = childRemoteItems;
    }
    
    return remoteItem;
}

@end
