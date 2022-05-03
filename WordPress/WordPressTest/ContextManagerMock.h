#import "ContextManager.h"
#import <XCTest/XCTest.h>


NS_ASSUME_NONNULL_BEGIN

@protocol ManagerMock
@property (nonatomic, readwrite, strong) NSManagedObjectContext         *mainContext;
@property (nonatomic, readwrite, strong) NSManagedObjectModel           *managedObjectModel;
@property (nonatomic, readwrite, strong) NSPersistentStoreCoordinator   *persistentStoreCoordinator;
@property (nonatomic, readonly,  strong) NSPersistentStoreCoordinator   *standardPSC;
@property (nonatomic, readonly,  strong) NSURL                          *storeURL;
@end

/**
 *  @class      ContextManagerMock
 *  @brief      This class overrides standard ContextManager functionality, for testing purposes.
 *  @details    The SQLite-Backed PSC is replaced by an InMemory store. This allows us to easily reset
 *              the contents of the database, without even hitting the filesystem.
 */
@interface ContextManagerMock : ContextManager <ManagerMock, CoreDataStack>


/**
 *  @brief      Loads the contents of any given JSON file into a new NSManagedObject instance
 *  @details    This helper method is useful for Unit Testing scenarios.
 *
 *  @param      entityName  The name of the entity to be inserted.
 *  @param      filename    The name of the JSON file to be loaded.
 */
- (NSManagedObject *)loadEntityNamed:(NSString *)entityName withContentsOfFile:(NSString *)filename;
- (NSDictionary *)objectWithContentOfFile:(NSString *)filename;

@end

NS_ASSUME_NONNULL_END
