#import "ContextManager.h"
#import "ContextManagerMock.h"
#import <XCTest/XCTest.h>

@class MockContext;

NS_ASSUME_NONNULL_BEGIN

/**
 *  @class      TestContextManager
 *  @brief      This class overrides standard ContextManager functionality, for testing purposes.
 *  @details    The SQLite-Backed PSC is replaced by an InMemory store. This allows us to easily reset
 *              the contents of the database, without even hitting the filesystem.
 */
@interface TestContextManager : NSObject <CoreDataStack>

@property (nonatomic, readwrite, strong) NSManagedObjectContext         *mainContext;
@property (nonatomic, readwrite, strong) NSManagedObjectModel           *managedObjectModel;
@property (nonatomic, readwrite, strong) NSPersistentStoreCoordinator   *persistentStoreCoordinator;
@property (nonatomic, readonly,  strong) NSPersistentStoreCoordinator   *standardPSC;
@property (nonatomic, readwrite, assign) BOOL                           requiresTestExpectation;
@property (nonatomic, readonly,  strong) NSURL                          *storeURL;
@property (nonatomic, nullable,  readwrite, strong) XCTestExpectation   *testExpectation;
@property (nonatomic, strong, nullable) id<ManagerMock, CoreDataStack>  stack;

+ (instancetype)sharedInstance;
+ (void)overrideSharedInstance:(id <CoreDataStack> _Nullable)contextManager;

@end

NS_ASSUME_NONNULL_END
