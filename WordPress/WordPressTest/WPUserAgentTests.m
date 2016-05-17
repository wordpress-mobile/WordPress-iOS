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

- (void)testThatOriginalRemovalOfWPUseKeyUserAgentDoesntWork {
    // get the original user agent
    NSString *originalUserAgent = [self currentUserAgentFromUIWebView];
    NSLog(@"OriginalUserAgent: %@", originalUserAgent);
    // set a new one
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{WPUserAgentKeyUserAgent:@"new user agent"}];
    NSString *changedUserAgent = [self currentUserAgentFromUIWebView];
    NSLog(@"changedUserAgent: %@", changedUserAgent);

    // try to remove it using old method
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{}];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WPUserAgentKeyUserAgent];
    NSString *shouldBeOriginal = [self currentUserAgentFromUIWebView];
    NSLog(@"shouldBeOriginal: %@", shouldBeOriginal);
    XCTAssertNotEqualObjects(originalUserAgent, shouldBeOriginal, "This agent should be the same");
}

- (void)testThatCallingFromAnotherThreadWorks {
    // get the original user agent
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        XCTAssertNoThrow([WPUserAgent wordPressUserAgent], @"Being called from out of main thread should work");
    });
}

- (void)testThatRegistarDefaultJustAdds {
    NSDictionary * registrationDomain = [[NSUserDefaults standardUserDefaults] volatileDomainForName:NSRegistrationDomain];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{WPUserAgentKeyUserAgent: @(0)}];
    NSDictionary * changedRegistrationDomain = [[NSUserDefaults standardUserDefaults] volatileDomainForName:NSRegistrationDomain];

    XCTAssertTrue((registrationDomain.count == changedRegistrationDomain.count) || ((registrationDomain.count +1) == changedRegistrationDomain.count), "It should add or reset");
}


@end
