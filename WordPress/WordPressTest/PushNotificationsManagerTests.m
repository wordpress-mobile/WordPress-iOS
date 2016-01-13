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
    id mockSettings = OCMPartialMock([[UIApplication sharedApplication] currentUserNotificationSettings]);
    [OCMStub([mockSettings types]) andReturnValue:OCMOCK_VALUE(UIUserNotificationTypeNone)];
    
    id mockApplication = OCMPartialMock([UIApplication sharedApplication]);
    [OCMStub([mockApplication currentUserNotificationSettings]) andReturn:mockSettings];
    
    PushNotificationsManager *manager = [PushNotificationsManager new];
    id mockManager = OCMPartialMock(manager);
    [OCMStub([mockManager sharedApplication]) andReturn:mockApplication];

    XCTAssertFalse([mockManager notificationsEnabledInDeviceSettings]);
}

- (void)testPushNotificationsEnabledInSettingsWhenRegisteredTypeIsAlert
{
    id mockSettings = OCMPartialMock([[UIApplication sharedApplication] currentUserNotificationSettings]);
    [OCMStub([mockSettings types]) andReturnValue:OCMOCK_VALUE(UIUserNotificationTypeAlert)];
    
    id mockApplication = OCMPartialMock([UIApplication sharedApplication]);
    [OCMStub([mockApplication currentUserNotificationSettings]) andReturn:mockSettings];
    
    PushNotificationsManager *manager = [PushNotificationsManager new];
    id mockManager = OCMPartialMock(manager);
    [OCMStub([mockManager sharedApplication]) andReturn:mockApplication];
    
    XCTAssertTrue([mockManager notificationsEnabledInDeviceSettings]);
}

- (void)testRegisterForPushNotificationsCallsSharedApplicationRegisterForRemoteNotifications
{
    // Note:
    // PushNotifications registration methods don't crash the sim, anymore, as per iOS 9.
    // We'll override the check just for evil unit testing purposes.
    
    id mockApplication = OCMPartialMock([UIApplication sharedApplication]);
    OCMExpect([mockApplication registerForRemoteNotifications]);
    
    [OCMStub([mockApplication isRunningSimulator]) andReturnValue:OCMOCK_VALUE(false)];
    
    PushNotificationsManager *manager = [PushNotificationsManager new];
    id mockManager = OCMPartialMock(manager);
    [OCMStub([mockManager sharedApplication]) andReturn:mockApplication];
    
    [mockManager registerForRemoteNotifications];
    OCMVerify(mockApplication);
}

- (void)testHandleNotificationUpdatesApplicationBadgeNumber
{
    NSInteger badgeCount = 5;
    NSDictionary *userInfo = @{ @"aps" : @{ @"badge" : @(badgeCount) }};
    
    id mockApplication = OCMPartialMock([UIApplication sharedApplication]);
    OCMExpect([mockApplication setApplicationIconBadgeNumber:5]);
    
    PushNotificationsManager *manager = [PushNotificationsManager new];
    id mockManager = OCMPartialMock(manager);
    [OCMStub([mockManager sharedApplication]) andReturn:mockApplication];
    [OCMStub([mockManager applicationState]) andReturnValue:OCMOCK_VALUE(UIApplicationStateActive)];
    
    [mockManager handleNotification:userInfo completionHandler:nil];
    OCMVerify(mockManager);
}

- (void)testBadgeResetNotificationDoesntAttemptToHandleAnyNotificationKind
{
    NSDictionary *userInfo = @{ @"type" : @"badge-reset"};
    PushNotificationsManager *manager = [PushNotificationsManager new];
    id mockManager = OCMPartialMock(manager);
    
    [[mockManager reject] handleAuthenticationNotification:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[mockManager reject] handleHelpshiftNotification:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[mockManager reject] handleInactiveNotification:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[mockManager reject] handleBackgroundNotification:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    
    [mockManager handleNotification:userInfo completionHandler:nil];
    OCMVerify(mockManager);
}

- (void)testHelpshiftNotificationIsProperlyHandled
{
    NSDictionary *userInfo = @{ @"origin" : @"helpshift" };
    PushNotificationsManager *manager = [PushNotificationsManager new];
    id mockManager = OCMPartialMock(manager);
    
    XCTAssertTrue([mockManager handleHelpshiftNotification:userInfo completionHandler:nil], @"Error handling Helpshift");
    XCTAssertFalse([mockManager handleAuthenticationNotification:userInfo completionHandler:nil], @"Error handling Helpshift");
    XCTAssertFalse([mockManager handleInactiveNotification:userInfo completionHandler:nil], @"Error handling Helpshift");
    XCTAssertFalse([mockManager handleBackgroundNotification:userInfo completionHandler:nil], @"Error handling Helpshift");
    
    OCMExpect([manager handleHelpshiftNotification:userInfo completionHandler:nil]);
    [mockManager handleNotification:userInfo completionHandler:nil];
    OCMVerify(mockManager);
}

- (void)testPushAuthenticationNotificationIsHandledWhileInBackgroundMode
{
    NSDictionary *userInfo = @{ @"type" : @"push_auth" };
    PushNotificationsManager *manager = [PushNotificationsManager new];
    id mockManager = OCMPartialMock(manager);
    
    XCTAssertTrue([mockManager handleAuthenticationNotification:userInfo completionHandler:nil], @"Error handling PushAuth");
    XCTAssertFalse([mockManager handleHelpshiftNotification:userInfo completionHandler:nil], @"Error handling PushAuth");
    XCTAssertFalse([mockManager handleInactiveNotification:userInfo completionHandler:nil], @"Error handling PushAuth");
    XCTAssertFalse([mockManager handleBackgroundNotification:userInfo completionHandler:nil], @"Error handling PushAuth");
    
    OCMExpect([manager handleAuthenticationNotification:userInfo completionHandler:nil]);
    [mockManager handleNotification:userInfo completionHandler:nil];
    OCMVerify(mockManager);
}
@end
