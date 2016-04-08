#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "Blog.h"
#import "ContextManager.h"
#import "MenusServiceRemote.h"
#import "TestContextManager.h"
#import "WordPressComApi.h"
#import "RemoteMenu.h"

@interface MenusServicRemoteTests : XCTestCase

@end

@implementation MenusServicRemoteTests

- (void)testThatCreateMenuWithNameWorks
{
    Blog *blog = OCMStrictClassMock([Blog class]);
    OCMStub([blog dotComID]).andReturn(@10);
    
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    MenusServiceRemote *service = nil;
    
    RemoteMenu *menu = OCMClassMock([RemoteMenu class]);
    OCMStub([menu menuId]).andReturn(@"MenuId");
    OCMStub([menu name]).andReturn(@"Name");

    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/menus/new", [blog dotComID]];
    NSString *name = @"SomeName";
    
    BOOL (^parametersCheckBlock)(id obj) = ^BOOL(NSDictionary *parameters) {
        
        return ([parameters isKindOfClass:[NSDictionary class]]
                && [[parameters objectForKey:@"name"] isEqualToString:name]);
    };
    
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg checkWithBlock:parametersCheckBlock]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[MenusServiceRemote alloc] initWithApi:api]);
    
    [service createMenuWithName:name
                           blog:blog
                        success:^(RemoteMenu *menu) {}
                        failure:^(NSError *error) {}];
}

- (void)testThatUpdateMenuWorks
{
    Blog *blog = OCMStrictClassMock([Blog class]);
    OCMStub([blog dotComID]).andReturn(@10);
    
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    MenusServiceRemote *service = nil;
    
    RemoteMenu *menu = OCMClassMock([RemoteMenu class]);
    OCMStub([menu menuId]).andReturn(@"MenuId");
    OCMStub([menu name]).andReturn(@"Name");
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/menus/%@", [blog dotComID], menu.menuId];
    
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isKindOfClass:[NSDictionary class]]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[MenusServiceRemote alloc] initWithApi:api]);

    [service updateMenuForId:menu.menuId
                        blog:blog
                    withName:menu.name
               withLocations:nil
                   withItems:nil
                     success:^(RemoteMenu *menu) {}
                     failure:^(NSError *error) {}];
}

- (void)testThatDeleteMenuWorks
{
    Blog *blog = OCMStrictClassMock([Blog class]);
    OCMStub([blog dotComID]).andReturn(@10);
    
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    MenusServiceRemote *service = nil;
    
    RemoteMenu *menu = OCMClassMock([RemoteMenu class]);
    OCMStub([menu menuId]).andReturn(@"MenuId");
    OCMStub([menu name]).andReturn(@"Name");
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/menus/%@/delete", [blog dotComID], menu.menuId];
    
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[MenusServiceRemote alloc] initWithApi:api]);
    
    [service deleteMenuForId:menu.menuId
                        blog:blog
                    success:^{}
                    failure:^(NSError *error) {}];
}

- (void)testThatGetMenusWorks
{
    Blog *blog = OCMStrictClassMock([Blog class]);
    OCMStub([blog dotComID]).andReturn(@10);
    
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    MenusServiceRemote *service = nil;
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/menus", [blog dotComID]];
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[MenusServiceRemote alloc] initWithApi:api]);
    
    [service getMenusForBlog:blog
                     success:^(NSArray<RemoteMenu *> *menus, NSArray<RemoteMenuLocation *> *locations) {}
                     failure:^(NSError *error) {}];
}

@end
