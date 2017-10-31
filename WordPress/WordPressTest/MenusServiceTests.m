#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "MenusService.h"
#import "Blog.h"
#import "Menu.h"
#import "MenuLocation.h"
#import "MenuItem.h"
#import "TestContextManager.h"
#import "WordPressTest-Swift.h"

@interface WPAccount ()
@property (nonatomic, readwrite) WordPressComRestApi *wordPressComRestApi;
@end

@interface MenusServiceTests : XCTestCase
@property (nonatomic, strong) TestContextManager *manager;
@end

@implementation MenusServiceTests

- (void)setUp
{
    [super setUp];
    self.manager = [TestContextManager new];
}

- (void)tearDown
{
    self.manager = nil;
    [super tearDown];
}

- (void)testThatWordPressBlogSupportsMenusServices
{
    NSManagedObjectContext *context = self.manager.mainContext;
    Blog *blog = [ModelTestHelper insertDotComBlogWithContext:context];
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    blog.account.wordPressComRestApi = api;
    blog.dotComID = @1;
    blog.isAdmin = YES;

    MenusService *service = [[MenusService alloc] initWithManagedObjectContext:context];
    BOOL blogSupportsMenus = NO;
    
    XCTAssertNoThrow(blogSupportsMenus = [service blogSupportsMenusCustomization:blog]);
    XCTAssertTrue(blogSupportsMenus);
}

- (void)testThatWordPressBlogDoesNotSupportMenusServices
{
    NSManagedObjectContext *context = self.manager.mainContext;
    Blog *blog = [ModelTestHelper insertDotComBlogWithContext:context];
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    blog.account.wordPressComRestApi = api;
    blog.dotComID = @1;
    blog.isAdmin = NO;
    
    MenusService *service = [[MenusService alloc] initWithManagedObjectContext:context];
    BOOL blogSupportsMenus = NO;
    
    XCTAssertNoThrow(blogSupportsMenus = [service blogSupportsMenusCustomization:blog]);
    XCTAssertFalse(blogSupportsMenus);
}

- (void)testThatSyncMenusForBlogWorks
{
    NSManagedObjectContext *context = self.manager.mainContext;
    Blog *blog = [ModelTestHelper insertDotComBlogWithContext:context];
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    blog.account.wordPressComRestApi = api;
    blog.dotComID = @1;
    blog.isAdmin = YES;

    NSString* url = [NSString stringWithFormat:@"rest/v1.1/sites/%@/menus", [blog dotComID]];
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);

    MenusService *service = nil;
    XCTAssertNoThrow(service = [[MenusService alloc] initWithManagedObjectContext:context]);
    XCTAssertNoThrow([service syncMenusForBlog:blog
                                       success:^(){}
                                       failure:^(NSError *error) {}]);
}

- (void)testThatCreateMenuWithNameWorks
{
    NSManagedObjectContext *context = self.manager.mainContext;
    Blog *blog = [ModelTestHelper insertDotComBlogWithContext:context];
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    blog.account.wordPressComRestApi = api;
    blog.dotComID = @1;
    blog.isAdmin = YES;
    
    NSString* url = [NSString stringWithFormat:@"rest/v1.1/sites/%@/menus/new", [blog dotComID]];
    NSString *name = @"SomeName";
    Menu *menu = [NSEntityDescription insertNewObjectForEntityForName:[Menu entityName] inManagedObjectContext:context];
    menu.name = name;
    menu.menuID = @0;

    BOOL (^parametersCheckBlock)(id obj) = ^BOOL(NSDictionary *parameters) {
        return ([parameters isKindOfClass:[NSDictionary class]]
                && [[parameters objectForKey:@"name"] isEqualToString:name]);
    };
    
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg checkWithBlock:parametersCheckBlock]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    MenusService *service = nil;
    XCTAssertNoThrow(service = [[MenusService alloc] initWithManagedObjectContext:context]);
    XCTAssertNoThrow([service createOrUpdateMenu:menu
                                            forBlog:blog
                                         success:^(void) {}
                                         failure:^(NSError *error) {}]);
}

- (void)testThatUpdateMenuWorks
{
    NSManagedObjectContext *context = self.manager.mainContext;
    Blog *blog = [ModelTestHelper insertDotComBlogWithContext:context];
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    blog.account.wordPressComRestApi = api;
    blog.dotComID = @1;
    blog.isAdmin = YES;
    
    MenuLocation *location = [NSEntityDescription insertNewObjectForEntityForName:[MenuLocation entityName] inManagedObjectContext:context];
    location.name = @"name";
    NSSet *locations = [NSSet setWithObject:location];
    
    MenuItem *item = [NSEntityDescription insertNewObjectForEntityForName:[MenuItem entityName] inManagedObjectContext:context];
    item.itemID = @1;
    item.contentID = @1;
    item.details = @"item details";
    item.linkTarget = MenuItemLinkTargetBlank;
    item.linkTitle = @"Item";
    item.name = @"name";
    item.type = MenuItemTypePage;
    item.typeFamily = MenuItemTypePage;
    item.typeLabel = @"Page";
    item.urlStr = @"http://wordpress.com/";
    item.classes = @[@"special_class", @"extra_special_class"];
    item.children = nil;
    item.parent = nil;
    NSOrderedSet *items = [NSOrderedSet orderedSetWithObject:item];
    
    Menu *menu = [NSEntityDescription insertNewObjectForEntityForName:[Menu entityName] inManagedObjectContext:context];
    menu.menuID = @1;
    menu.locations = locations;
    menu.name = @"name";
    menu.items = items;

    NSString* url = [NSString stringWithFormat:@"rest/v1.1/sites/%@/menus/%@", [blog dotComID], menu.menuID];
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isKindOfClass:[NSDictionary class]]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    MenusService *service = nil;
    XCTAssertNoThrow(service = [[MenusService alloc] initWithManagedObjectContext:context]);
    XCTAssertNoThrow([service createOrUpdateMenu:menu
                                 forBlog:blog
                                 success:^(){}
                                 failure:^(NSError *error) {}]);
}

- (void)testThatDeleteMenuWithIdWorks
{
    NSManagedObjectContext *context = self.manager.mainContext;
    Blog *blog = [ModelTestHelper insertDotComBlogWithContext:context];
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    blog.account.wordPressComRestApi = api;
    blog.dotComID = @1;
    blog.isAdmin = YES;

    Menu *menu = [NSEntityDescription insertNewObjectForEntityForName:[Menu entityName] inManagedObjectContext:context];
    menu.menuID = @1;

    NSString* url = [NSString stringWithFormat:@"rest/v1.1/sites/%@/menus/%@/delete", [blog dotComID], menu.menuID];
    
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    MenusService *service = nil;
    XCTAssertNoThrow(service = [[MenusService alloc] initWithManagedObjectContext:context]);
    XCTAssertNoThrow([service deleteMenu:menu
                                 forBlog:blog
                                 success:^(){}
                                 failure:^(NSError *error) {}]);
}

- (void)testThatDeleteMenuWithoutIdWorks
{
    NSManagedObjectContext *context = self.manager.mainContext;
    Blog *blog = [ModelTestHelper insertDotComBlogWithContext:context];
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    blog.account.wordPressComRestApi = api;
    blog.dotComID = @1;
    blog.isAdmin = YES;

    Menu *menu = [NSEntityDescription insertNewObjectForEntityForName:[Menu entityName] inManagedObjectContext:context];
    menu.menuID = nil;

    NSString* url = [NSString stringWithFormat:@"rest/v1.1/sites/%@/menus/%@/delete", [blog dotComID], menu.menuID];
    
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    MenusService *service = nil;
    XCTAssertNoThrow(service = [[MenusService alloc] initWithManagedObjectContext:context]);
    XCTAssertNoThrow([service deleteMenu:menu
                                 forBlog:blog
                                 success:^(){}
                                 failure:^(NSError *error) {}]);
}

@end
