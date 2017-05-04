#import "MenusServiceRemote.h"
#import "Blog.h"
#import "RemoteMenu.h"
#import "RemoteMenuItem.h"
#import "RemoteMenuLocation.h"
#import "WordPress-Swift.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const MenusRemoteKeyID = @"id";
NSString * const MenusRemoteKeyMenu = @"menu";
NSString * const MenusRemoteKeyMenus = @"menus";
NSString * const MenusRemoteKeyLocations = @"locations";
NSString * const MenusRemoteKeyContentID = @"content_id";
NSString * const MenusRemoteKeyDescription = @"description";
NSString * const MenusRemoteKeyLinkTarget = @"link_target";
NSString * const MenusRemoteKeyLinkTitle = @"link_title";
NSString * const MenusRemoteKeyName = @"name";
NSString * const MenusRemoteKeyType = @"type";
NSString * const MenusRemoteKeyTypeFamily = @"type_family";
NSString * const MenusRemoteKeyTypeLabel = @"type_label";
NSString * const MenusRemoteKeyURL = @"url";
NSString * const MenusRemoteKeyItems = @"items";
NSString * const MenusRemoteKeyDeleted = @"deleted";
NSString * const MenusRemoteKeyLocationDefaultState = @"defaultState";
NSString * const MenusRemoteKeyClasses = @"classes";

@implementation MenusServiceRemote

#pragma mark - Remote queries: Creating and modifying menus

- (void)createMenuWithName:(NSString *)menuName
                      blog:(Blog *)blog
                   success:(nullable MenusServiceRemoteMenuRequestSuccessBlock)success
                   failure:(nullable MenusServiceRemoteFailureBlock)failure
{
    NSNumber *blogId = [blog dotComID];
    NSParameterAssert([blogId isKindOfClass:[NSNumber class]]);
    NSParameterAssert([menuName isKindOfClass:[NSString class]]);
    
    NSString *path = [NSString stringWithFormat:@"sites/%@/menus/new", blogId];
    NSString *requestURL = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    
    [self.wordPressComRestApi POST:requestURL
        parameters:@{MenusRemoteKeyName: menuName}
           success:^(id  _Nonnull responseObject, NSHTTPURLResponse *httpResponse) {
               void(^responseFailure)() = ^() {
                   NSString *message = NSLocalizedString(@"An error occurred creating the Menu.", @"An error description explaining that a Menu could not be created.");
                   [self handleResponseErrorWithMessage:message url:requestURL failure:failure];
               };
               NSNumber *menuID = [responseObject numberForKey:MenusRemoteKeyID];
               if (!menuID) {
                   responseFailure();
                   return;
               }
               if (success) {
                   RemoteMenu *menu = [RemoteMenu new];
                   menu.menuID = menuID;
                   menu.name = menuName;
                   success(menu);
               }
           } failure:^(NSError * _Nonnull error, NSHTTPURLResponse *httpResponse) {
               if (failure) {
                   failure(error);
               }
           }];
}

- (void)updateMenuForID:(NSNumber *)menuID
                   blog:(Blog *)blog
               withName:(nullable NSString *)updatedName
          withLocations:(nullable NSArray <NSString *> *)locationNames
              withItems:(nullable NSArray <RemoteMenuItem *> *)updatedItems
                success:(nullable MenusServiceRemoteMenuRequestSuccessBlock)success
                failure:(nullable MenusServiceRemoteFailureBlock)failure
{
    NSNumber *blogId = [blog dotComID];
    NSParameterAssert([blogId isKindOfClass:[NSNumber class]]);
    NSParameterAssert([menuID isKindOfClass:[NSNumber class]]);
    
    NSString *path = [NSString stringWithFormat:@"sites/%@/menus/%@", blogId, menuID];
    NSString *requestURL = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    
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
    [params setObject:menuID forKey:MenusRemoteKeyID];
    
    [self.wordPressComRestApi POST:requestURL
        parameters:params
           success:^(id  _Nonnull responseObject, NSHTTPURLResponse *httpResponse) {
               void(^responseFailure)() = ^() {
                   NSString *message = NSLocalizedString(@"An error occurred updating the Menu.", @"An error description explaining that a Menu could not be updated.");
                   [self handleResponseErrorWithMessage:message url:requestURL failure:failure];
               };
               if (![responseObject isKindOfClass:[NSDictionary class]]) {
                   responseFailure();
                   return;
               }
               RemoteMenu *menu = [self menuFromJSONDictionary:[responseObject dictionaryForKey:MenusRemoteKeyMenu]];
               if (!menu) {
                   responseFailure();
                   return;
               }
               if (success) {
                   success(menu);
               }
           } failure:^(NSError * _Nonnull error, NSHTTPURLResponse *httpResponse) {
               if (failure) {
                   failure(error);
               }
           }];
}

- (void)deleteMenuForID:(NSNumber *)menuID
                   blog:(Blog *)blog
                success:(nullable MenusServiceRemoteSuccessBlock)success
                failure:(nullable MenusServiceRemoteFailureBlock)failure
{
    NSNumber *blogId = [blog dotComID];
    NSParameterAssert([blogId isKindOfClass:[NSNumber class]]);
    NSParameterAssert([menuID isKindOfClass:[NSNumber class]]);
    
    NSString *path = [NSString stringWithFormat:@"sites/%@/menus/%@/delete", blogId, menuID];
    NSString *requestURL = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    [self.wordPressComRestApi POST:requestURL
        parameters:nil
           success:^(id  _Nonnull responseObject, NSHTTPURLResponse *httpResponse) {
               void(^responseFailure)() = ^() {
                   NSString *message = NSLocalizedString(@"An error occurred deleting the Menu.", @"An error description explaining that a Menu could not be deleted.");
                   [self handleResponseErrorWithMessage:message url:requestURL failure:failure];
               };
               if (![responseObject isKindOfClass:[NSDictionary class]]) {
                   responseFailure();
                   return;
               }
               BOOL deleted = [[responseObject numberForKey:MenusRemoteKeyDeleted] boolValue];
               if (deleted) {
                   if (success) {
                       success();
                   }
               } else {
                   responseFailure();
               }
           } failure:^(NSError * _Nonnull error, NSHTTPURLResponse *httpResponse) {
               if (failure) {
                   failure(error);
               }
           }];
}

#pragma mark - Remote queries: Getting menus

- (void)getMenusForBlog:(Blog *)blog
                success:(nullable MenusServiceRemoteMenusRequestSuccessBlock)success
                failure:(nullable MenusServiceRemoteFailureBlock)failure
{
    NSNumber *blogId = [blog dotComID];
    NSParameterAssert([blogId isKindOfClass:[NSNumber class]]);
    
    NSString *path = [NSString stringWithFormat:@"sites/%@/menus", blogId];
    NSString *requestURL = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    
    [self.wordPressComRestApi GET:requestURL
       parameters:nil
          success:^(id  _Nonnull responseObject, NSHTTPURLResponse *httpResponse) {
              if (![responseObject isKindOfClass:[NSDictionary class]]) {
                  NSString *message = NSLocalizedString(@"An error occurred fetching the Menus.", @"An error description explaining that Menus could not be fetched.");
                  [self handleResponseErrorWithMessage:message url:requestURL failure:failure];
                  return;
              }
              if (success) {
                  NSArray *menus = [self remoteMenusFromJSONArray:[responseObject arrayForKey:MenusRemoteKeyMenus]];
                  NSArray *locations = [self remoteMenuLocationsFromJSONArray:[responseObject arrayForKey:MenusRemoteKeyLocations]];
                  success(menus, locations);
              }
              
          } failure:^(NSError * _Nonnull error, NSHTTPURLResponse *httpResponse) {
              if (failure) {
                  failure(error);
              }
          }];
}

#pragma mark - Remote Model from JSON

- (nullable NSArray *)remoteMenusFromJSONArray:(nullable NSArray<NSDictionary *> *)jsonMenus
{
    return [jsonMenus wp_map:^id(NSDictionary *dictionary) {
        return [self menuFromJSONDictionary:dictionary];
    }];
}

- (nullable NSArray *)menuItemsFromJSONDictionaries:(nullable NSArray<NSDictionary *> *)dictionaries parent:(nullable RemoteMenuItem *)parent
{
    NSParameterAssert([dictionaries isKindOfClass:[NSArray class]]);
    return [dictionaries wp_map:^id(NSDictionary *dictionary) {
        
        RemoteMenuItem *item = [self menuItemFromJSONDictionary:dictionary];
        item.parentItem = parent;
        
        return item;
    }];
}

- (nullable NSArray *)remoteMenuLocationsFromJSONArray:(nullable NSArray<NSDictionary *> *)jsonLocations
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
- (nullable RemoteMenu *)menuFromJSONDictionary:(nullable NSDictionary *)dictionary
{
    NSParameterAssert([dictionary isKindOfClass:[NSDictionary class]]);
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSNumber *menuID = [dictionary numberForKey:MenusRemoteKeyID];
    if (!menuID.integerValue) {
        // empty menu dictionary
        return nil;
    }
    
    RemoteMenu *menu = [RemoteMenu new];
    menu.menuID = menuID;
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
- (nullable RemoteMenuItem *)menuItemFromJSONDictionary:(nullable NSDictionary *)dictionary
{
    NSParameterAssert([dictionary isKindOfClass:[NSDictionary class]]);
    if (![dictionary isKindOfClass:[NSDictionary class]] || !dictionary.count) {
        return nil;
    }
    
    RemoteMenuItem *item = [RemoteMenuItem new];
    item.itemID = [dictionary numberForKey:MenusRemoteKeyID];
    item.contentID = [dictionary numberForKey:MenusRemoteKeyContentID];
    item.details = [dictionary stringForKey:MenusRemoteKeyDescription];
    item.linkTarget = [dictionary stringForKey:MenusRemoteKeyLinkTarget];
    item.linkTitle = [dictionary stringForKey:MenusRemoteKeyLinkTitle];
    item.name = [dictionary stringForKey:MenusRemoteKeyName];
    item.type = [dictionary stringForKey:MenusRemoteKeyType];
    item.typeFamily = [dictionary stringForKey:MenusRemoteKeyTypeFamily];
    item.typeLabel = [dictionary stringForKey:MenusRemoteKeyTypeLabel];
    item.urlStr = [dictionary stringForKey:MenusRemoteKeyURL];
    item.classes = [dictionary arrayForKey:MenusRemoteKeyClasses];
    
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
- (nullable RemoteMenuLocation *)menuLocationFromJSONDictionary:(nullable NSDictionary *)dictionary
{
    NSParameterAssert([dictionary isKindOfClass:[NSDictionary class]]);
    if (![dictionary isKindOfClass:[NSDictionary class]] || !dictionary.count) {
        return nil;
    }
    
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
    
    if (item.itemID.integerValue) {
        dictionary[MenusRemoteKeyID] = item.itemID;
    }
    
    if (item.contentID.integerValue) {
        dictionary[MenusRemoteKeyContentID] = item.contentID;
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

    if (item.classes.count) {
        dictionary[MenusRemoteKeyClasses] = item.classes;
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

#pragma mark - errors

- (void)handleResponseErrorWithMessage:(NSString *)message url:(NSString *)urlStr failure:(nullable MenusServiceRemoteFailureBlock)failure
{
    DDLogError(@"%@ - URL: %@", message, urlStr);
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                         code:NSURLErrorBadServerResponse
                                     userInfo:@{NSLocalizedDescriptionKey: message}];
    if (failure) {
        failure(error);
    }
}

@end

NS_ASSUME_NONNULL_END
