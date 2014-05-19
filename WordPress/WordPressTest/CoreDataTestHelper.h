#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataTestHelper : NSObject

+ (id)sharedHelper;

- (void)reset;

- (void)setModelName:(NSString *)modelName;
- (BOOL)migrateToModelName:(NSString *)modelName;

- (NSManagedObject *)insertEntityIntoMainContextWithName:(NSString *)entityName;
- (NSManagedObject *)insertEntityWithName:(NSString *)entityName intoContext:(NSManagedObjectContext*)context;
- (NSArray *)allObjectsInMainContextForEntityName:(NSString *)entityName;
- (NSArray *)allObjectsInContext:(NSManagedObjectContext *)context forEntityName:(NSString *)entityName;

@end
