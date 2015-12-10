#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "WordPress-Swift.h"


@interface PushNotificationsManagerTests : XCTestCase

@end

@implementation PushNotificationsManagerTests

- (void)testRegisterForPushNotificationsCallsSharedApplicationRegisterForRemoteNotifications
{
    // Note:
    // PushNotifications registration methods don't crash the sim, anymore, as per iOS 9.
    // We'll override the check just for evil unit testing purposes.
    
    id mockApplication = [OCMockObject partialMockForObject:[UIApplication sharedApplication]];
    [[mockApplication expect] registerForRemoteNotifications];
    [[mockApplication expect] registerUserNotificationSettings:[OCMArg isNotNil]];
    
    [[[mockApplication stub] andReturnValue:OCMOCK_VALUE(false)] isRunningSimulator];
    
    id mockManager = [OCMockObject partialMockForObject:[PushNotificationsManager sharedInstance]];
    [[[mockManager stub] andReturn:mockApplication] sharedApplication];
    
    [mockManager registerForPushNotifications];
    [mockApplication verify];
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

@end
