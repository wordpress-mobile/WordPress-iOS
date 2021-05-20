#import <XCTest/XCTest.h>

@interface UserSettingsTestsObjc : XCTestCase

@end

@implementation UserSettingsTestsObjc

- (void)tearDown {
    [UserSettings reset];
    [super tearDown];
}

- (void)testThatDefaultDotComUUIDDefaultsToNil {
    XCTAssertNil([UserSettings defaultDotComUUID]);
}

- (void)testThatChangingDefaultDotComUUIDWorks {
    NSString *uuid = [[NSUUID new] UUIDString];
    [UserSettings setDefaultDotComUUID:uuid];
    XCTAssertEqual([UserSettings defaultDotComUUID], uuid);
}

- (void)testThatChangingDefaultDotComUUIDToNilWorks {
    [UserSettings setDefaultDotComUUID:[[NSUUID new] UUIDString]];
    [UserSettings setDefaultDotComUUID:nil];
    XCTAssertNil([UserSettings defaultDotComUUID]);
}

@end
