#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "Blog.h"
#import "ContextManager.h"
#import "MenusServiceRemote.h"
#import "RemoteMenu.h"

@interface MenusServicRemoteTests : XCTestCase

@end

@implementation MenusServicRemoteTests

- (void)testThatCreateMenuWithNameWorks
{
    NSNumber *dotComID = @10;
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    MenusServiceRemote *service = nil;
    
    RemoteMenu *menu = OCMClassMock([RemoteMenu class]);
    OCMStub([menu menuID]).andReturn(@(1));
    OCMStub([menu name]).andReturn(@"Name");

    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/menus/new", dotComID];
    NSString *name = @"SomeName";
    
    BOOL (^parametersCheckBlock)(id obj) = ^BOOL(NSDictionary *parameters) {
        
        return ([parameters isKindOfClass:[NSDictionary class]]
                && [[parameters objectForKey:@"name"] isEqualToString:name]);
    };
    
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg checkWithBlock:parametersCheckBlock]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[MenusServiceRemote alloc] initWithWordPressComRestApi:api]);
    
    [service createMenuWithName:name
                         siteID:dotComID
                        success:^(RemoteMenu *menu) {}
                        failure:^(NSError *error) {}];
}

- (void)testThatUpdateMenuWorks
{
    NSNumber *dotComID = @10;
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    MenusServiceRemote *service = nil;
    
    RemoteMenu *menu = OCMClassMock([RemoteMenu class]);
    OCMStub([menu menuID]).andReturn(@(1));
    OCMStub([menu name]).andReturn(@"Name");
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/menus/%@", dotComID, menu.menuID];
    
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isKindOfClass:[NSDictionary class]]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[MenusServiceRemote alloc] initWithWordPressComRestApi:api]);

    [service updateMenuForID:menu.menuID
                        siteID:dotComID
                    withName:menu.name
               withLocations:nil
                   withItems:nil
                     success:^(RemoteMenu *menu) {}
                     failure:^(NSError *error) {}];
}

- (void)testThatDeleteMenuWorks
{
    NSNumber *dotComID = @10;
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    MenusServiceRemote *service = nil;
    
    RemoteMenu *menu = OCMClassMock([RemoteMenu class]);
    OCMStub([menu menuID]).andReturn(@(1));
    OCMStub([menu name]).andReturn(@"Name");
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/menus/%@/delete", dotComID, menu.menuID];
    
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[MenusServiceRemote alloc] initWithWordPressComRestApi:api]);
    
    [service deleteMenuForID:menu.menuID
                      siteID:dotComID
                    success:^{}
                    failure:^(NSError *error) {}];
}

- (void)testThatGetMenusWorks
{
    NSNumber *dotComID = @10;
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    MenusServiceRemote *service = nil;
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/menus", dotComID];
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[MenusServiceRemote alloc] initWithWordPressComRestApi:api]);
    
    [service getMenusForSiteID:dotComID
                       success:^(NSArray<RemoteMenu *> *menus, NSArray<RemoteMenuLocation *> *locations) {}
                       failure:^(NSError *error) {}];
}

@end
