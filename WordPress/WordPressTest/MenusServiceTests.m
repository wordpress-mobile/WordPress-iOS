#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "MenusService.h"
#import "Blog.h"
#import "Menu.h"
#import "MenuLocation.h"
#import "MenuItem.h"

@interface MenuForStubbing : Menu
@property (nullable, nonatomic, strong) NSNumber *menuID;
@property (nullable, nonatomic, strong) NSString *name;
@property (nullable, nonatomic, strong) NSSet<MenuLocation *> *locations;
@property (nullable, nonatomic, strong) NSOrderedSet<MenuItem *> *items;
@end

@implementation MenuForStubbing
@synthesize name;
@synthesize menuID;
@synthesize locations;
@synthesize items;
@end

@interface MenuLocationForStubbing : MenuLocation
@property (nullable, nonatomic, retain) NSString *name;
@end

@implementation MenuLocationForStubbing
@synthesize name;
@end

@interface MenuItemForStubbing : MenuItem
@property (nullable, nonatomic, strong) NSNumber *itemID;
@property (nullable, nonatomic, strong) NSNumber *contentID;
@property (nullable, nonatomic, strong) NSString *details;
@property (nullable, nonatomic, strong) NSString *linkTarget;
@property (nullable, nonatomic, strong) NSString *linkTitle;
@property (nullable, nonatomic, strong) NSString *name;
@property (nullable, nonatomic, strong) NSString *type;
@property (nullable, nonatomic, strong) NSString *typeFamily;
@property (nullable, nonatomic, strong) NSString *typeLabel;
@property (nullable, nonatomic, strong) NSString *urlStr;
@property (nullable, nonatomic, strong) NSSet<MenuItem *> *children;
@property (nullable, nonatomic, strong) MenuItem *parent;
@end
@implementation MenuItemForStubbing
@synthesize itemID;
@synthesize contentID;
@synthesize details;
@synthesize linkTarget;
@synthesize linkTitle;
@synthesize name;
@synthesize type;
@synthesize typeFamily;
@synthesize typeLabel;
@synthesize urlStr;
@synthesize children;
@synthesize parent;
@end

@interface MenusServiceTests : XCTestCase

@end

@implementation MenusServiceTests

- (void)testThatWordPressBlogSupportsMenusServices
{
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    
    Blog *blog = OCMStrictClassMock([Blog class]);
    
    OCMStub([blog wordPressComRestApi]).andReturn(api);
    OCMStub([blog dotComID]).andReturn(@1);
    OCMStub([blog supports:BlogFeatureMenus]).andReturn(YES);
    
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    
    MenusService *service = [[MenusService alloc] initWithManagedObjectContext:context];
    BOOL blogSupportsMenus = NO;
    
    XCTAssertNoThrow(blogSupportsMenus = [service blogSupportsMenusCustomization:blog]);
    XCTAssertTrue(blogSupportsMenus);
}

- (void)testThatWordPressBlogDoesNotSupportMenusServices
{
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    
    Blog *blog = OCMStrictClassMock([Blog class]);
    
    OCMStub([blog wordPressComRestApi]).andReturn(api);
    OCMStub([blog dotComID]).andReturn(@1);
    OCMStub([blog supports:BlogFeatureMenus]).andReturn(NO);
    
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    
    MenusService *service = [[MenusService alloc] initWithManagedObjectContext:context];
    BOOL blogSupportsMenus = NO;
    
    XCTAssertNoThrow(blogSupportsMenus = [service blogSupportsMenusCustomization:blog]);
    XCTAssertFalse(blogSupportsMenus);
}

- (void)testThatSyncMenusForBlogWorks
{
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    
    Blog *blog = OCMStrictClassMock([Blog class]);
    
    OCMStub([blog wordPressComRestApi]).andReturn(api);
    OCMStub([blog dotComID]).andReturn(@1);
    OCMStub([blog supports:BlogFeatureMenus]).andReturn(YES);
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/menus", [blog dotComID]];
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    
    MenusService *service = nil;
    XCTAssertNoThrow(service = [[MenusService alloc] initWithManagedObjectContext:context]);
    XCTAssertNoThrow([service syncMenusForBlog:blog
                                       success:^(){}
                                       failure:^(NSError *error) {}]);
}

- (void)testThatCreateMenuWithNameWorks
{
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    
    Blog *blog = OCMStrictClassMock([Blog class]);
    
    OCMStub([blog wordPressComRestApi]).andReturn(api);
    OCMStub([blog dotComID]).andReturn(@1);
    OCMStub([blog supports:BlogFeatureMenus]).andReturn(YES);
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/menus/new", [blog dotComID]];
    NSString *name = @"SomeName";
    Menu *menu = OCMStrictClassMock([MenuForStubbing class]);
    OCMStub([menu name]).andReturn(name);
    OCMStub([menu menuID]).andReturn(@(0));

    BOOL (^parametersCheckBlock)(id obj) = ^BOOL(NSDictionary *parameters) {
        return ([parameters isKindOfClass:[NSDictionary class]]
                && [[parameters objectForKey:@"name"] isEqualToString:name]);
    };
    
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg checkWithBlock:parametersCheckBlock]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    
    MenusService *service = nil;
    XCTAssertNoThrow(service = [[MenusService alloc] initWithManagedObjectContext:context]);
    XCTAssertNoThrow([service createOrUpdateMenu:menu
                                            forBlog:blog
                                         success:^(NSNumber *menuID) {}
                                         failure:^(NSError *error) {}]);
}

- (void)testThatUpdateMenuWorks
{
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    
    Blog *blog = OCMStrictClassMock([Blog class]);
    
    OCMStub([blog wordPressComRestApi]).andReturn(api);
    OCMStub([blog dotComID]).andReturn(@1);
    OCMStub([blog supports:BlogFeatureMenus]).andReturn(YES);
    
    MenuLocation *location = OCMStrictClassMock([MenuLocationForStubbing class]);
    OCMStub([location name]).andReturn(@"name");
    NSSet *locations = [NSSet setWithObject:location];
    
    MenuItem *item = OCMStrictClassMock([MenuItemForStubbing class]);
    OCMStub([item itemID]).andReturn(@(1));
    OCMStub([item contentID]).andReturn(@(1));
    OCMStub([item details]).andReturn(@"item details");
    OCMStub([item linkTarget]).andReturn(MenuItemLinkTargetBlank);
    OCMStub([item linkTitle]).andReturn(@"Item");
    OCMStub([item name]).andReturn(@"name");
    OCMStub([item type]).andReturn(MenuItemTypePage);
    OCMStub([item typeFamily]).andReturn(MenuItemTypePage);
    OCMStub([item typeLabel]).andReturn(@"Page");
    OCMStub([item urlStr]).andReturn(@"http://wordpress.com/");
    OCMStub([item children]).andReturn(nil);
    OCMStub([item parent]).andReturn(nil);
    NSOrderedSet *items = [NSOrderedSet orderedSetWithObject:item];
    
    Menu *menu = OCMStrictClassMock([MenuForStubbing class]);
    OCMStub([menu menuID]).andReturn(@(1));
    OCMStub([menu locations]).andReturn(locations);
    OCMStub([menu name]).andReturn(@"name");
    OCMStub([menu items]).andReturn(items);

    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/menus/%@", [blog dotComID], menu.menuID];
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isKindOfClass:[NSDictionary class]]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    
    MenusService *service = nil;
    XCTAssertNoThrow(service = [[MenusService alloc] initWithManagedObjectContext:context]);
    XCTAssertNoThrow([service createOrUpdateMenu:menu
                                 forBlog:blog
                                 success:^(){}
                                 failure:^(NSError *error) {}]);
}

- (void)testThatDeleteMenuWithIdWorks
{
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    
    Blog *blog = OCMStrictClassMock([Blog class]);
    
    OCMStub([blog wordPressComRestApi]).andReturn(api);
    OCMStub([blog dotComID]).andReturn(@1);
    OCMStub([blog supports:BlogFeatureMenus]).andReturn(YES);
    
    Menu *menu = OCMStrictClassMock([MenuForStubbing class]);
    OCMStub([menu menuID]).andReturn(@(1));
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/menus/%@/delete", [blog dotComID], menu.menuID];
    
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    
    MenusService *service = nil;
    XCTAssertNoThrow(service = [[MenusService alloc] initWithManagedObjectContext:context]);
    XCTAssertNoThrow([service deleteMenu:menu
                                 forBlog:blog
                                 success:^(){}
                                 failure:^(NSError *error) {}]);
}

- (void)testThatDeleteMenuWithoutIdWorks
{
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    
    Blog *blog = OCMStrictClassMock([Blog class]);
    
    OCMStub([blog wordPressComRestApi]).andReturn(api);
    OCMStub([blog dotComID]).andReturn(@1);
    OCMStub([blog supports:BlogFeatureMenus]).andReturn(YES);
    
    Menu *menu = OCMStrictClassMock([MenuForStubbing class]);
    OCMStub([menu menuID]).andReturn(nil);
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/menus/%@/delete", [blog dotComID], menu.menuID];
    
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    OCMStub([context performBlock:[OCMArg any]]).andDo(nil);
    
    MenusService *service = nil;
    XCTAssertNoThrow(service = [[MenusService alloc] initWithManagedObjectContext:context]);
    XCTAssertNoThrow([service deleteMenu:menu
                                 forBlog:blog
                                 success:^(){}
                                 failure:^(NSError *error) {}]);
}

@end
