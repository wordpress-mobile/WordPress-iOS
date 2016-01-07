#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "WordPress-Swift.h"


@interface InteractiveNotificationsHandlerTests : XCTestCase

@end

@implementation InteractiveNotificationsHandlerTests

- (void)testRegisterForUserNotificationsCallsSharedApplicationRegisterForUserNotifications
{
    // Note:
    // PushNotifications registration methods don't crash the sim, anymore, as per iOS 9.
    // We'll override the check just for evil unit testing purposes.
    
    id mockApplication = [OCMockObject partialMockForObject:[UIApplication sharedApplication]];
    [[mockApplication expect] registerUserNotificationSettings:[OCMArg isNotNil]];
    
    [[[mockApplication stub] andReturnValue:OCMOCK_VALUE(false)] isRunningSimulator];
    
    id mockManager = [OCMockObject partialMockForObject:[InteractiveNotificationsHandler sharedInstance]];
    [[[mockManager stub] andReturn:mockApplication] sharedApplication];
    
    [mockManager registerForUserNotifications];
    [mockApplication verify];
}

@end
