
@import XCTest;

#import "Blog.h"
#import "BlogSiteVisibilityHelper.h"
#import "JetpackState.h"
#import "TestContextManager.h"

@interface BlogSiteVisibilityHelperTest : XCTestCase
@end

@interface BlogSiteVisibilityHelperTest ()
@property (nonatomic, strong) TestContextManager *testContextManager;
@end

@implementation BlogSiteVisibilityHelperTest

- (void)setUp
{
    [super setUp];
    
    self.testContextManager = [TestContextManager new];
}

- (void)tearDown
{
    [super tearDown];
    
    self.testContextManager = nil;
}

- (void)testSiteVisibilityValuesForJetpackConnectedBlog
{
    Blog *blog = [self newJetpackBlog];
    
    NSArray *values = [BlogSiteVisibilityHelper siteVisibilityValuesForBlog:blog];
    NSArray *expected = @[ @(SiteVisibilityPublic), @(SiteVisibilityHidden) ];
    
    XCTAssertEqualObjects(values, expected);
}

- (void)testSiteVisibilityValuesForNonJetpackConnectedBlog
{
    Blog *blog = [self newBlog];
    
    NSArray *values = [BlogSiteVisibilityHelper siteVisibilityValuesForBlog:blog];
    NSArray *expected = @[ @(SiteVisibilityPublic), @(SiteVisibilityHidden), @(SiteVisibilityPrivate) ];
    
    XCTAssertEqualObjects(values, expected);
}

- (void)testSiteVisibilityTitlesForJetpackConnectedBlog
{
    Blog *blog = [self newJetpackBlog];
    
    NSArray *values = [BlogSiteVisibilityHelper siteVisibilityValuesForBlog:blog];
    NSArray *titles = [BlogSiteVisibilityHelper titlesForSiteVisibilityValues:values];
    NSArray *expected = @[ NSLocalizedString(@"Public", ""), NSLocalizedString(@"Hidden", @"") ];
    
    XCTAssertEqualObjects(titles, expected);
}

- (void)testSiteVisibilityTitlesForNonJetpackConnectedBlog
{
    Blog *blog = [self newBlog];
    
    NSArray *values = [BlogSiteVisibilityHelper siteVisibilityValuesForBlog:blog];
    NSArray *titles = [BlogSiteVisibilityHelper titlesForSiteVisibilityValues:values];
    NSArray *expected = @[ NSLocalizedString(@"Public", ""), NSLocalizedString(@"Hidden", @""), NSLocalizedString(@"Private", @"") ];
    
    XCTAssertEqualObjects(titles, expected);
}

- (void)testSiteVisibilityTitlesForCustomValues
{
    NSString *public  = NSLocalizedString(@"Public", "");
    NSString *hidden  = NSLocalizedString(@"Hidden", "");
    NSString *private = NSLocalizedString(@"Private", "");
    NSString *unknown = NSLocalizedString(@"Unknown", "");
    
    NSArray *values = @[ @(SiteVisibilityPublic),
                         @(SiteVisibilityHidden),
                         @(SiteVisibilityHidden),
                         @(SiteVisibilityPrivate),
                         @(SiteVisibilityUnknown),
                         @(SiteVisibilityPrivate) ];
    
    NSArray *titles = [BlogSiteVisibilityHelper titlesForSiteVisibilityValues:values];
    NSArray *expected = @[ public, hidden, hidden, private, unknown, private ];
    
    XCTAssertEqualObjects(titles, expected);
}

- (void)testSiteVisibilityHintsForJetpackConnectedBlog
{
    Blog *blog = [self newJetpackBlog];
    
    NSArray *values = [BlogSiteVisibilityHelper siteVisibilityValuesForBlog:blog];
    NSArray *hints = [BlogSiteVisibilityHelper hintsForSiteVisibilityValues:values];
    NSArray *expected = @[ [self publicHint], [self hiddenHint] ];
    
    XCTAssertEqualObjects(hints, expected);
}

- (void)testSiteVisibilityHintsForNonJetpackConnectedBlog
{
    Blog *blog = [self newBlog];
    
    NSArray *values = [BlogSiteVisibilityHelper siteVisibilityValuesForBlog:blog];
    NSArray *hints = [BlogSiteVisibilityHelper hintsForSiteVisibilityValues:values];
    NSArray *expected = @[ [self publicHint], [self hiddenHint], [self privateHint] ];
    
    XCTAssertEqualObjects(hints, expected);
}

- (void)testSiteVisibilityHintsForCustomValues
{
    NSArray *values = @[ @(SiteVisibilityHidden),
                         @(SiteVisibilityHidden),
                         @(SiteVisibilityPublic),
                         @(SiteVisibilityPrivate),
                         @(SiteVisibilityUnknown),
                         @(SiteVisibilityHidden),
                         @(SiteVisibilityPublic) ];
    
    NSArray *hints = [BlogSiteVisibilityHelper hintsForSiteVisibilityValues:values];
    NSArray *expected = @[ [self hiddenHint],
                           [self hiddenHint],
                           [self publicHint],
                           [self privateHint],
                           [self unknownHint],
                           [self hiddenHint],
                           [self publicHint] ];
    
    XCTAssertEqualObjects(hints, expected);
}

#pragma mark - Helper Methods


- (Blog *)newBlog
{
    Blog *blog = (Blog *)[NSEntityDescription insertNewObjectForEntityForName:@"Blog"
                                                       inManagedObjectContext:self.testContextManager.mainContext];
    blog.isHostedAtWPcom = YES;
    
    return blog;
}

- (Blog *)newJetpackBlog
{
    Blog *blog = [self newBlog];
    blog.isHostedAtWPcom = NO;
    
    // UI in the app hides visibility settings entirely for self-hosted non-Jetpack blogs
    // so for the purposes of these tests we can assume that if a blog is self-hosted
    // then it's also running Jetpack.
    
    return blog;
}

- (NSString *)privateHint
{
    return NSLocalizedString(@"Your site is only visible to you and users you approve.", @"");
}

- (NSString *)hiddenHint
{
    return NSLocalizedString(@"Your site is visible to everyone, but asks search engines not to index your site.", @"");
}

- (NSString *)publicHint
{
    return NSLocalizedString(@"Your site is visible to everyone, and it may be indexed by search engines.", @"");
}

- (NSString *)unknownHint
{
    return NSLocalizedString(@"Unknown", @"");
}

@end
