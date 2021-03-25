#import <XCTest/XCTest.h>
#import "WordPress-Swift.h"

@interface ObjcUserSettingsTests : XCTestCase

@end

@implementation ObjcUserSettingsTests

- (void)setUp {
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:bundleID];
}

- (void)testDefaultDotComUUID {
    NSString *testUUID = [[NSUUID UUID] UUIDString];

    /// Verify that the default is `nil` (ie – the user is logged out)
    XCTAssertNil([UserSettings defaultDotComUUID]);

    /// Test that the UUID is set correctly
    [UserSettings setDefaultDotComUUID:testUUID];
    XCTAssertEqual([UserSettings defaultDotComUUID], testUUID);

    /// Test that the UUID can be removed
    [UserSettings setDefaultDotComUUID:nil];
    XCTAssertNil([UserSettings defaultDotComUUID]);
}

@end
