#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "WordPress-Swift.h"


@interface PushNotificationsManagerTests : XCTestCase

@end

@implementation PushNotificationsManagerTests

- (void)testDeviceTokenAndDeviceIdentifierArePersistedAcrossSessions
{
    // Store
    PushNotificationsManager *manager = [PushNotificationsManager new];
    manager.deviceId = @"1234";
    manager.deviceToken = @"4567";
    
    // Verify persistance
    manager = [PushNotificationsManager new];
    XCTAssertEqualObjects(manager.deviceId, @"1234");
    XCTAssertEqualObjects(manager.deviceToken, @"4567");
    
    // Nuke
    manager.deviceId = nil;
    manager.deviceToken = nil;
    
    // Verify persistance
    manager = [PushNotificationsManager new];
    XCTAssert([manager.deviceId isEmpty]);
    XCTAssert([manager.deviceToken isEmpty]);
}


- (void)testPushNotificationsDisabledInSettingsWhenRegisteredTypeIsNone
{
    id mockSettings = [OCMockObject partialMockForObject:[[UIApplication sharedApplication] currentUserNotificationSettings]];
    [[[mockSettings stub] andReturnValue:OCMOCK_VALUE(UIUserNotificationTypeNone)] types];
    
    id mockApplication = [OCMockObject partialMockForObject:[UIApplication sharedApplication]];
    [[[mockApplication stub] andReturn:mockSettings] currentUserNotificationSettings];
    
    id mockManager = [OCMockObject partialMockForObject:[PushNotificationsManager sharedInstance]];
    [[[mockManager stub] andReturn:mockApplication] sharedApplication];

    XCTAssertFalse([mockManager notificationsEnabledInDeviceSettings]);
}

- (void)testPushNotificationsEnabledInSettingsWhenRegisteredTypeIsAlert
{
    id mockSettings = [OCMockObject partialMockForObject:[[UIApplication sharedApplication] currentUserNotificationSettings]];
    [[[mockSettings stub] andReturnValue:OCMOCK_VALUE(UIUserNotificationTypeAlert)] types];
    
    id mockApplication = [OCMockObject partialMockForObject:[UIApplication sharedApplication]];
    [[[mockApplication stub] andReturn:mockSettings] currentUserNotificationSettings];
    
    id mockManager = [OCMockObject partialMockForObject:[PushNotificationsManager sharedInstance]];
    [[[mockManager stub] andReturn:mockApplication] sharedApplication];
    
    XCTAssertTrue([mockManager notificationsEnabledInDeviceSettings]);
}

- (void)testRegisterForPushNotificationsCallsSharedApplicationRegisterForRemoteNotifications
{
    // Note:
    // PushNotifications registration methods don't crash the sim, anymore, as per iOS 9.
    // We'll override the check just for evil unit testing purposes.
    
    id mockApplication = [OCMockObject partialMockForObject:[UIApplication sharedApplication]];
    [[mockApplication expect] registerForRemoteNotifications];
    
    [[[mockApplication stub] andReturnValue:OCMOCK_VALUE(false)] isRunningSimulator];
    
    id mockManager = [OCMockObject partialMockForObject:[PushNotificationsManager sharedInstance]];
    [[[mockManager stub] andReturn:mockApplication] sharedApplication];
    
    [mockManager registerForRemoteNotifications];
    [mockApplication verify];
}

@end
