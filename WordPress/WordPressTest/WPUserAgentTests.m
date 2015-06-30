#import <XCTest/XCTest.h>

#import "WPUserAgent.h"

static NSString* const WPUserAgentKeyUserAgent = @"UserAgent";
static NSString* const WPUserAgentKeyDefaultUserAgent = @"DefaultUserAgent";
static NSString* const WPUserAgentKeyWordPressUserAgent = @"AppUserAgent";

@interface WPUserAgentTests : XCTestCase
@end

@implementation WPUserAgentTests

/**
 *  @brief      Calculates the wordpress UA for this device.
 *  @details    This method is duplicated on purpose since we want to make sure that any change to
 *              the WP UA in the app makes this test show an error unless updated.  This way we
 *              ensure the change is intentional.
 */
- (NSString *)wordPressUserAgent
{
    UIDevice *device = [UIDevice currentDevice];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *userAgent = [NSString stringWithFormat:@"wp-iphone/%@ (%@ %@, %@) Mobile",
                           appVersion,
                           device.systemName,
                           device.systemVersion,
                           device.model];
    
    return userAgent;
}

- (void)testUseDefaultUserAgent
{
    NSString *defaultUA = [[[UIWebView alloc] init] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    WPUserAgent *userAgent = nil;
    
    XCTAssertNoThrow(userAgent = [[WPUserAgent alloc] init]);
    XCTAssertTrue([userAgent isKindOfClass:[WPUserAgent class]]);
    
    [userAgent useDefaultUserAgent];
    
    XCTAssertTrue([[userAgent currentUserAgent] isEqualToString:defaultUA]);
}

- (void)testUseWordPressUserAgent
{
    NSString *wordPressUA = [self wordPressUserAgent];
    WPUserAgent *userAgent = nil;
    
    XCTAssertNoThrow(userAgent = [[WPUserAgent alloc] init]);
    XCTAssertTrue([userAgent isKindOfClass:[WPUserAgent class]]);
    
    [userAgent useDefaultUserAgent];
    
    XCTAssertTrue([[userAgent currentUserAgent] isEqualToString:wordPressUA]);
}

@end
