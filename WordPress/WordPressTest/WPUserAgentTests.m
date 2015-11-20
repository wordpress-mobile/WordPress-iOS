#import <XCTest/XCTest.h>

#import "WPUserAgent.h"

static NSString* const WPUserAgentKeyUserAgent = @"UserAgent";
static NSString* const WPUserAgentKeyDefaultUserAgent = @"DefaultUserAgent";
static NSString* const WPUserAgentKeyWordPressUserAgent = @"AppUserAgent";

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
    
    NSString *userAgent = [[[UIWebView alloc] init] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
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

- (void)testUseDefaultUserAgent
{
    NSString *defaultUA = [self defaultUserAgent];
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
    
    [userAgent useWordPressUserAgent];
    
    XCTAssertTrue([[userAgent currentUserAgent] isEqualToString:wordPressUA]);
}

@end
