#import <XCTest/XCTest.h>
#import "TestContextManager.h"

@interface Blog_ObjcTests : XCTestCase
@property (strong, nonatomic) TestContextManager *contextManager;
@end

@implementation Blog_ObjcTests

- (void)setUp {
    self.contextManager = [TestContextManager new];
    [super setUp];
}

- (void)tearDown {
    [self.contextManager tearDown];
    [super tearDown];
}

- (void)testThatNilBlogIDDoesNotCrashWhenCreatingPredicate {
    NSNumber *number = nil;
    Blog *blog = [Blog lookupWithID:number in:self.contextManager.mainContext];
    XCTAssertNil(blog);
}

@end
