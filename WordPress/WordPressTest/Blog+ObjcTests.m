#import <XCTest/XCTest.h>
#import "TestContextManager.h"

@interface Blog_ObjcTests : XCTestCase
@property (strong, nonatomic) NSManagedObjectContext *context;
@end

@implementation Blog_ObjcTests

- (void)setUp {
    self.context = [[TestContextManager new] mainContext];
    [super setUp];
}

- (void)tearDown {
    self.context = nil;
    [super tearDown];
}

- (void)testThatNilBlogIDDoesNotCrashWhenCreatingPredicate {
    NSNumber *number = nil;
    Blog *blog = [Blog lookupWithID:number in:self.context];
    XCTAssertNil(blog);
}

@end
