#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataTestHelper : NSObject

+ (instancetype)sharedHelper;

- (void)reset;

- (void)setModelName:(NSString *)modelName;

- (NSManagedObject *)insertEntityIntoMainContextWithName:(NSString *)entityName;
- (NSArray *)allObjectsInMainContextForEntityName:(NSString *)entityName;

@end
