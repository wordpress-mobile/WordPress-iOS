#import <CoreData/CoreData.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "LocalCoreDataService.h"

@interface LocalCoreDataServiceTests : XCTestCase
@end

@implementation LocalCoreDataServiceTests

- (void)testThatInitWorks
{
    NSManagedObjectContext *context = OCMClassMock([NSManagedObjectContext class]);
    
    LocalCoreDataService *service = nil;
    
    XCTAssertNoThrow(service = [[LocalCoreDataService alloc] initWithManagedObjectContext:context]);
    XCTAssertNotNil(service);
    XCTAssert(context == service.managedObjectContext);
}

- (void)testThatInitThrowsExceptionWithoutContext
{
    NSManagedObjectContext *context = nil;
    LocalCoreDataService *service = nil;
    
    XCTAssertThrows(service = [[LocalCoreDataService alloc] initWithManagedObjectContext:context]);
}

@end
