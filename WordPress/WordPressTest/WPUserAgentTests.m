#import <XCTest/XCTest.h>

#import "WPUserAgent.h"

static NSString* const WPUserAgentKeyUserAgent = @"UserAgent";

@interface WPUserAgentTests : XCTestCase
@end

@implementation WPUserAgentTests

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
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *customAgent = [NSString stringWithFormat:@"wp-iphone/%@", appVersion];

    XCTAssertTrue([[WPUserAgent wordPressUserAgent] containsString:customAgent]);
}

- (void)testUseWordPressUserAgentInUIWebViews
{
    NSString *defaultUA = [WPUserAgent defaultUserAgent];
    NSString *wordPressUA = [WPUserAgent wordPressUserAgent];

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WPUserAgentKeyUserAgent];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{WPUserAgentKeyUserAgent: defaultUA}];

    XCTAssertTrue([[self currentUserAgentFromUserDefaults] isEqualToString:defaultUA]);
    XCTAssertTrue([[self currentUserAgentFromUIWebView] isEqualToString:defaultUA]);

    [WPUserAgent useWordPressUserAgentInUIWebViews];
    
    XCTAssertTrue([[self currentUserAgentFromUserDefaults] isEqualToString:wordPressUA]);
    XCTAssertTrue([[self currentUserAgentFromUIWebView] isEqualToString:wordPressUA]);
}

@end
