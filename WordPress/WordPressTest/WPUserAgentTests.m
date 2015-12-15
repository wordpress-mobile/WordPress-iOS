#import <XCTest/XCTest.h>

#import "WPUserAgent.h"

static NSString* const WPUserAgentKeyUserAgent = @"UserAgent";

@interface WPUserAgentTests : XCTestCase
@end

@implementation WPUserAgentTests

/**
 *  @brief      Returns default UA for this device.
 *  @details    This method is duplicated on purpose since we want to make sure that any change to
 *              the WP UA in the app makes this test show an error unless updated.  This way we
 *              ensure the change is intentional.
 *              Also, the method temporarily unsets "UserAgent" from registered
 *              user defaults so that we always get the default value,
 *              independently from what's currently set as User-Agent.
 */
- (NSString *)defaultUserAgent
{
    NSDictionary *originalRegisteredDefaults = [[NSUserDefaults standardUserDefaults] volatileDomainForName:NSRegistrationDomain];
    
    NSMutableDictionary *tempRegisteredDefaults = [NSMutableDictionary dictionaryWithDictionary:originalRegisteredDefaults];
    [tempRegisteredDefaults removeObjectForKey:WPUserAgentKeyUserAgent];
    [[NSUserDefaults standardUserDefaults] registerDefaults:tempRegisteredDefaults];
    
    NSString *userAgent = [self currentUserAgentFromUIWebView];
    XCTAssertNotNil(userAgent, @"User agent shouldn't be nil");
    XCTAssertTrue([userAgent length] > 0, @"User agent shouldn't be empty");
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:originalRegisteredDefaults];
    
    return userAgent;
}

/**
 *  @brief      Calculates the wordpress UA for this device.
 *  @details    This method is duplicated on purpose since we want to make sure that any change to
 *              the WP UA in the app makes this test show an error unless updated.  This way we
 *              ensure the change is intentional.
 */
- (NSString *)wordPressUserAgent
{
    NSString *defaultUA = [self defaultUserAgent];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *userAgent = [NSString stringWithFormat:@"%@ wp-iphone/%@", defaultUA, appVersion];
    
    return userAgent;
}

- (NSString *)currentUserAgentFromUserDefaults
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:WPUserAgentKeyUserAgent];
}

- (NSString *)currentUserAgentFromUIWebView
{
    return [[[UIWebView alloc] init] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
}

- (void)testWordPressUserAgent
{
    NSString *wordPressUA = [self wordPressUserAgent];
    WPUserAgent *userAgent = nil;
    
    XCTAssertNoThrow(userAgent = [[WPUserAgent alloc] init]);
    XCTAssertTrue([userAgent isKindOfClass:[WPUserAgent class]]);
    
    XCTAssertTrue([[self wordPressUserAgent] isEqualToString:wordPressUA]);
}

- (void)testUseWordPressUserAgentInUIWebViews
{
    NSString *defaultUA = [self defaultUserAgent];
    NSString *wordPressUA = [self wordPressUserAgent];
    WPUserAgent *userAgent = nil;
    
    XCTAssertNoThrow(userAgent = [[WPUserAgent alloc] init]);
    XCTAssertTrue([userAgent isKindOfClass:[WPUserAgent class]]);
    
    XCTAssertTrue([[self currentUserAgentFromUserDefaults] isEqualToString:defaultUA]);
    XCTAssertTrue([[self currentUserAgentFromUIWebView] isEqualToString:defaultUA]);
    
    [userAgent useWordPressUserAgentInUIWebViews];
    
    XCTAssertTrue([[self currentUserAgentFromUserDefaults] isEqualToString:wordPressUA]);
    XCTAssertTrue([[self currentUserAgentFromUIWebView] isEqualToString:wordPressUA]);
}

@end
