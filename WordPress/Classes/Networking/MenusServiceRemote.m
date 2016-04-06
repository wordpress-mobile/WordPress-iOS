#import "MenusServiceRemote.h"
#import "Blog.h"
#import "WordPressComApi.h"
#import "RemoteMenu.h"
#import "RemoteMenuItem.h"
#import "RemoteMenuLocation.h"

static NSString * const MenusRemoteKeyID = @"id";
static NSString * const MenusRemoteKeyMenu = @"menu";
static NSString * const MenusRemoteKeyMenus = @"menus";
static NSString * const MenusRemoteKeyLocations = @"locations";
static NSString * const MenusRemoteKeyContentID = @"content_id";
static NSString * const MenusRemoteKeyDescription = @"description";
static NSString * const MenusRemoteKeyLinkTarget = @"link_target";
static NSString * const MenusRemoteKeyLinkTitle = @"link_title";
static NSString * const MenusRemoteKeyName = @"name";
static NSString * const MenusRemoteKeyType = @"type";
static NSString * const MenusRemoteKeyTypeFamily = @"type_family";
static NSString * const MenusRemoteKeyTypeLabel = @"type_label";
static NSString * const MenusRemoteKeyURL = @"url";
static NSString * const MenusRemoteKeyItems = @"items";
static NSString * const MenusRemoteKeyDeleted = @"deleted";
static NSString * const MenusRemoteKeyLocationDefaultState = @"defaultState";

@implementation MenusServiceRemote

#pragma mark - Remote queries: Creating and modifying menus

- (void)createMenuWithName:(NSString *)menuName
                      blog:(Blog *)blog
                   success:(MenusServiceRemoteMenuRequestSuccessBlock)success
                   failure:(MenusServiceRemoteFailureBlock)failure
{
    NSNumber *blogId = [blog dotComID];
    NSParameterAssert([blogId isKindOfClass:[NSNumber class]]);
    NSParameterAssert([menuName isKindOfClass:[NSString class]]);
    
    NSString *path = [NSString stringWithFormat:@"sites/%@/menus/new", blogId];
    NSString *requestURL = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api POST:requestURL
        parameters:@{MenusRemoteKeyName: menuName}
           success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
               if (success) {
                   NSAssert([responseObject isKindOfClass:[NSDictionary class]], @"Expected a dictionary");
                   
                   NSString *menuId = [responseObject stringForKey:MenusRemoteKeyID];
                   RemoteMenu *menu = nil;
                   if (menuId.length) {
                       menu = [RemoteMenu new];
                       menu.menuId = menuId;
                       menu.name = menuName;
                   }
                   
                   success(menu);
               }
           } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
               
               if (failure) {
                   failure(error);
               }
           }];
}

- (void)updateMenuForId:(NSString *)menuId
                   blog:(Blog *)blog
               withName:(NSString *)updatedName
          withLocations:(NSArray <NSString *> *)locationNames
              withItems:(NSArray <RemoteMenuItem *> *)updatedItems
                success:(MenusServiceRemoteMenuRequestSuccessBlock)success
                failure:(MenusServiceRemoteFailureBlock)failure
{
    NSNumber *blogId = [blog dotComID];
    NSParameterAssert([blogId isKindOfClass:[NSNumber class]]);
    NSParameterAssert([menuId isKindOfClass:[NSString class]]);
    
    NSString *path = [NSString stringWithFormat:@"sites/%@/menus/%@", blogId, menuId];
    NSString *requestURL = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    if (updatedName.length) {
        [params setObject:updatedName forKey:MenusRemoteKeyName];
    }
    if (updatedItems.count) {
        [params setObject:[self menuItemJSONDictionariesFromMenuItems:updatedItems] forKey:MenusRemoteKeyItems];
    }
    if (locationNames.count) {
        [params setObject:locationNames forKey:MenusRemoteKeyLocations];
    }
    
    // temporarily need to force the id for the menu update to work until fixed in Jetpack endpoints
    // Brent Coursey - 10/1/2015
    [params setObject:menuId forKey:MenusRemoteKeyID];
    
    [self.api POST:requestURL
        parameters:params
           success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
               if (success) {
                   NSAssert([responseObject isKindOfClass:[NSDictionary class]], @"Expected a dictionary...");
                   NSDictionary *menuDictionary = [responseObject dictionaryForKey:MenusRemoteKeyMenu];
                   success([self menuFromJSONDictionary:menuDictionary]);
               }
           } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
               
               if (failure) {
                   failure(error);
               }
           }];
}

- (void)deleteMenuForId:(NSString *)menuId
                   blog:(Blog *)blog
                success:(MenusServiceRemoteSuccessBlock)success
                failure:(MenusServiceRemoteFailureBlock)failure
{
    NSNumber *blogId = [blog dotComID];
    NSParameterAssert([blogId isKindOfClass:[NSNumber class]]);
    NSParameterAssert([menuId isKindOfClass:[NSString class]]);
    
    NSString *path = [NSString stringWithFormat:@"sites/%@/menus/%@/delete", blogId, menuId];
    NSString *requestURL = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    [self.api POST:requestURL
        parameters:nil
           success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
               if (success) {
                   NSAssert([responseObject isKindOfClass:[NSDictionary class]], @"Expected a dictionary");
                   
                   NSDictionary *response = responseObject;
                   BOOL deleted = [[response numberForKey:MenusRemoteKeyDeleted] boolValue];
                   if (deleted) {
                       success();
                   } else {
                       failure(nil);
                   }
               }
           } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
               
               if (failure) {
                   failure(error);
               }
           }];
}

#pragma mark - Remote queries: Getting menus

- (void)getMenusForBlog:(Blog *)blog
                success:(MenusServiceRemoteMenusRequestSuccessBlock)success
                failure:(MenusServiceRemoteFailureBlock)failure
{
    NSNumber *blogId = [blog dotComID];
    NSParameterAssert([blogId isKindOfClass:[NSNumber class]]);
    
    NSString *path = [NSString stringWithFormat:@"sites/%@/menus", blogId];
    NSString *requestURL = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api GET:requestURL
       parameters:nil
          success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
              if (success) {
                  
                  NSArray *menus = [self remoteMenusFromJSONArray:[responseObject arrayForKey:MenusRemoteKeyMenus]];
                  NSArray *locations = [self remoteMenuLocationsFromJSONArray:[responseObject arrayForKey:MenusRemoteKeyLocations]];
                  success(menus, locations);
              }
              
          } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
              
              if (failure) {
                  failure(error);
              }
          }];
}

#pragma mark - Remote Model from JSON

- (NSArray *)remoteMenusFromJSONArray:(NSArray<NSDictionary *> *)jsonMenus
{
    return [jsonMenus wp_map:^id(NSDictionary *dictionary) {
        return [self menuFromJSONDictionary:dictionary];
    }];
}

- (NSArray *)menuItemsFromJSONDictionaries:(NSArray<NSDictionary *> *)dictionaries parent:(RemoteMenuItem *)parent
{
    NSParameterAssert([dictionaries isKindOfClass:[NSArray class]]);
    
    return [dictionaries wp_map:^id(NSDictionary *dictionary) {
        
        RemoteMenuItem *item = [self menuItemFromJSONDictionary:dictionary];
        item.parentItem = parent;
        
        return item;
    }];
}

- (NSArray *)remoteMenuLocationsFromJSONArray:(NSArray<NSDictionary *> *)jsonLocations
{
    return [jsonLocations wp_map:^id(NSDictionary *dictionary) {
        return [self menuLocationFromJSONDictionary:dictionary];
    }];
}

/**
 *  @brief      Creates a remote menu object from the specified dictionary with nested menu items.
 *
 *  @param      dictionary      The dictionary containing the menu information.  Cannot be nil.
 *
 *  @returns    A remote menu object.
 */
- (RemoteMenu *)menuFromJSONDictionary:(NSDictionary *)dictionary
{
    NSParameterAssert([dictionary isKindOfClass:[NSDictionary class]]);
    
    NSString *menuId = [dictionary stringForKey:MenusRemoteKeyID];
    if (!menuId.length) {
        // empty menu dictionary
        return nil;
    }
    
    RemoteMenu *menu = [RemoteMenu new];
    menu.menuId = menuId;
    menu.details = [dictionary stringForKey:MenusRemoteKeyDescription];
    menu.name = [dictionary stringForKey:MenusRemoteKeyName];
    menu.locationNames = [dictionary arrayForKey:MenusRemoteKeyLocations];
    
    NSArray *itemDicts = [dictionary arrayForKey:MenusRemoteKeyItems];
    if (itemDicts.count) {
        menu.items = [self menuItemsFromJSONDictionaries:itemDicts parent:nil];
    }
    
    return menu;
}

/**
 *  @brief      Creates a remote menu item object from the specified dictionary along with any child items.
 *
 *  @param      dictionary      The dictionary containing the menu items.  Cannot be nil.
 *
 *  @returns    A remote menu item object.
 */
- (RemoteMenuItem *)menuItemFromJSONDictionary:(NSDictionary *)dictionary
{
    NSParameterAssert([dictionary isKindOfClass:[NSDictionary class]]);
    
    RemoteMenuItem *item = [RemoteMenuItem new];
    item.itemId = [dictionary stringForKey:MenusRemoteKeyID];
    item.contentId = [dictionary stringForKey:MenusRemoteKeyContentID];
    item.details = [dictionary stringForKey:MenusRemoteKeyDescription];
    item.linkTarget = [dictionary stringForKey:MenusRemoteKeyLinkTarget];
    item.linkTitle = [dictionary stringForKey:MenusRemoteKeyLinkTitle];
    item.name = [dictionary stringForKey:MenusRemoteKeyName];
    item.type = [dictionary stringForKey:MenusRemoteKeyType];
    item.typeFamily = [dictionary stringForKey:MenusRemoteKeyTypeFamily];
    item.typeLabel = [dictionary stringForKey:MenusRemoteKeyTypeLabel];
    item.urlStr = [dictionary stringForKey:MenusRemoteKeyURL];
    
    NSArray *itemDicts = [dictionary arrayForKey:MenusRemoteKeyItems];
    if (itemDicts.count) {
        item.children = [self menuItemsFromJSONDictionaries:itemDicts parent:item];
    }
    
    return item;
}

/**
 *  @brief      Creates a remote menu location object from the specified dictionary.
 *
 *  @param      dictionary      The dictionary containing the locations.  Cannot be nil.
 *
 *  @returns    A remote menu location object.
 */
- (RemoteMenuLocation *)menuLocationFromJSONDictionary:(NSDictionary *)dictionary
{
    NSParameterAssert([dictionary isKindOfClass:[NSDictionary class]]);
    
    RemoteMenuLocation *location = [RemoteMenuLocation new];
    location.defaultState = [dictionary stringForKey:MenusRemoteKeyLocationDefaultState];
    location.details = [dictionary stringForKey:MenusRemoteKeyDescription];
    location.name = [dictionary stringForKey:MenusRemoteKeyName];
    
    return location;
}

#pragma mark - Remote model to JSON

/**
 *  @brief      Creates remote menu item JSON dictionaries from the remote menu item objects.
 *
 *  @param      menuItems      The array containing the menu items.  Cannot be nil.
 *
 *  @returns    An array with menu item JSON dictionary representations.
 */
- (NSArray *)menuItemJSONDictionariesFromMenuItems:(NSArray<RemoteMenuItem *> *)menuItems
{
    NSMutableArray *dictionaries = [NSMutableArray arrayWithCapacity:menuItems.count];
    for (RemoteMenuItem *item in menuItems) {
        [dictionaries addObject:[self menuItemJSONDictionaryFromItem:item]];
    }
    
    return [NSArray arrayWithArray:dictionaries];
}

/**
 *  @brief      Creates a remote menu item JSON dictionary from the remote menu item object, with nested item dictionaries.
 *
 *  @param      item      The remote menu item object.  Cannot be nil.
 *
 *  @returns    A JSON dictionary representation of the menu item object.
 */
- (NSDictionary *)menuItemJSONDictionaryFromItem:(RemoteMenuItem *)item
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if (item.itemId.length) {
        dictionary[MenusRemoteKeyID] = item.itemId;
    }
    
    if (item.contentId.length) {
        dictionary[MenusRemoteKeyContentID] = item.contentId;
    }
    
    if (item.details.length) {
        dictionary[MenusRemoteKeyDescription] = item.details;
    }
    
    if (item.linkTarget.length) {
        dictionary[MenusRemoteKeyLinkTarget] = item.linkTarget;
    }
    
    if (item.linkTitle.length) {
        dictionary[MenusRemoteKeyLinkTitle] = item.linkTitle;
    }
    
    if (item.name.length) {
        dictionary[MenusRemoteKeyName] = item.name;
    }
    
    if (item.type.length) {
        dictionary[MenusRemoteKeyType] = item.type;
    }
    
    if (item.typeFamily.length) {
        dictionary[MenusRemoteKeyTypeFamily] = item.typeFamily;
    }
    
    if (item.typeLabel.length) {
        dictionary[MenusRemoteKeyTypeLabel] = item.typeLabel;
    }
    
    if (item.urlStr.length) {
        dictionary[MenusRemoteKeyURL] = item.urlStr;
    }
    
    if (item.children.count) {
        
        NSMutableArray *dictionaryItems = [NSMutableArray arrayWithCapacity:item.children.count];
        for (RemoteMenuItem *remoteItem in item.children) {
            [dictionaryItems addObject:[self menuItemJSONDictionaryFromItem:remoteItem]];
        }
        
        dictionary[MenusRemoteKeyItems] = [NSArray arrayWithArray:dictionaryItems];
    }
    
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

- (NSDictionary *)menuLocationJSONDictionaryFromLocation:(RemoteMenuLocation *)location
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:MenusRemoteKeyName forKey:location.name];
    
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

@end
