#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "MenusServiceRemote.h"
#import "WPKit-Swift.h"

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

    XCTAssertNoThrow(service = [[MenusServiceRemote alloc] initWithWordPressComRestApi:api]);

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/menus/new", dotComID];
    NSString *url = [service pathForEndpoint:endpoint
                                 withVersion:WordPressComRESTAPIVersion_1_1];
    NSString *name = @"SomeName";
    
    BOOL (^parametersCheckBlock)(id obj) = ^BOOL(NSDictionary *parameters) {
        
        return ([parameters isKindOfClass:[NSDictionary class]]
                && [[parameters objectForKey:@"name"] isEqualToString:name]);
    };
    
    OCMStub([api post:[OCMArg isEqual:url]
           parameters:[OCMArg checkWithBlock:parametersCheckBlock]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);

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

    XCTAssertNoThrow(service = [[MenusServiceRemote alloc] initWithWordPressComRestApi:api]);

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/menus/%@", dotComID, menu.menuID];
    NSString *url = [service pathForEndpoint:endpoint
                                 withVersion:WordPressComRESTAPIVersion_1_1];

    OCMStub([api post:[OCMArg isEqual:url]
           parameters:[OCMArg isKindOfClass:[NSDictionary class]]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);

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

    XCTAssertNoThrow(service = [[MenusServiceRemote alloc] initWithWordPressComRestApi:api]);

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/menus/%@/delete", dotComID, menu.menuID];
    NSString *url = [service pathForEndpoint:endpoint
                                 withVersion:WordPressComRESTAPIVersion_1_1];

    OCMStub([api post:[OCMArg isEqual:url]
           parameters:[OCMArg isNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);

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

    XCTAssertNoThrow(service = [[MenusServiceRemote alloc] initWithWordPressComRestApi:api]);

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/menus", dotComID];
    NSString *url = [service pathForEndpoint:endpoint
                                 withVersion:WordPressComRESTAPIVersion_1_1];

    OCMStub([api get:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    

    [service getMenusForSiteID:dotComID
                       success:^(NSArray<RemoteMenu *> *menus, NSArray<RemoteMenuLocation *> *locations) {}
                       failure:^(NSError *error) {}];
}

@end
