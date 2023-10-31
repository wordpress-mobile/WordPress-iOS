#import <XCTest/XCTest.h>
#import "UnitTests-Swift.h"

@interface Blog_ObjcTests : XCTestCase
@property (strong, nonatomic) id<CoreDataStack> contextManager;
@end

@implementation Blog_ObjcTests

- (void)setUp {
    self.contextManager = [self coreDataStackForTesting];
    [super setUp];
}

- (void)testThatNilBlogIDDoesNotCrashWhenCreatingPredicate {
    NSNumber *number = nil;
    Blog *blog = [Blog lookupWithID:number in:self.contextManager.mainContext];
    XCTAssertNil(blog);
}

@end
