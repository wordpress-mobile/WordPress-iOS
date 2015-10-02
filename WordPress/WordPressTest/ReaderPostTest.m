#import <XCTest/XCTest.h>
#import "ReaderPost.h"
#import "NSString+Helpers.h"
#import "TestContextManager.h"

@interface ReaderPostTest : XCTestCase
@end

@implementation ReaderPostTest

- (void)testBlavatarForSize
{
    NSManagedObjectContext *context = [[TestContextManager sharedInstance] mainContext];
    ReaderPost *post = [NSEntityDescription insertNewObjectForEntityForName:@"ReaderPost"
                                         inManagedObjectContext:context];

    post.blogURL = @"http://blog.example.com/";
    NSString *hash = [@"blog.example.com" md5];
    NSURL *blavatarURL = [post siteIconForDisplayOfSize:50];

    XCTAssertNotNil(blavatarURL);
    XCTAssertNotNil([blavatarURL absoluteString]);
    XCTAssertTrue([[blavatarURL host] isEqualToString:@"secure.gravatar.com"]);

    NSString *path = [NSString stringWithFormat:@"/blavatar/%@", hash];
    XCTAssertTrue([[blavatarURL path] isEqualToString:path]);
    XCTAssertTrue([[blavatarURL absoluteString] rangeOfString:@"s=50"].location != NSNotFound);
}

@end
