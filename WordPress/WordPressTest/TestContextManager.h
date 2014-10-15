#import "ContextManager.h"
#import <XCTest/XCTest.h>

@interface TestContextManager : ContextManager

@property (nonatomic, strong) NSManagedObjectContext *mainContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) XCTestExpectation *testExpectation;

// Provides access to the standard SQLite-based Persistent Store Coordinator
@property (nonatomic, readonly, strong) NSPersistentStoreCoordinator *standardPSC;

- (NSURL *)storeURL;

@end
