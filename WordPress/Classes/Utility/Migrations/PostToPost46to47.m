#import "PostToPost46to47.h"
#import "Post.h"

@implementation PostToPost46to47

- (BOOL)beginEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    DDLogInfo(@"%@ %@ (%@ -> %@)", self, NSStringFromSelector(_cmd), [mapping sourceEntityName], [mapping destinationEntityName]);
    return YES;
}

- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sourceInstance
                                      entityMapping:(NSEntityMapping *)mapping
                                            manager:(NSMigrationManager *)manager
                                              error:(NSError *__autoreleasing *)error
{
    NSMutableArray *sourceKeys = [sourceInstance.entity.attributesByName.allKeys mutableCopy];
    NSDictionary *sourceValues = [sourceInstance dictionaryWithValuesForKeys:sourceKeys];
    NSManagedObject *destinationInstance = [NSEntityDescription insertNewObjectForEntityForName:mapping.destinationEntityName
                                                                         inManagedObjectContext:manager.destinationContext];
    NSArray *destinationKeys = destinationInstance.entity.attributesByName.allKeys;
    for (NSString *key in destinationKeys) {
        id value = [sourceValues valueForKey:key];
        // Avoid NULL values
        if (value && ![value isEqual:[NSNull null]]) {
            [destinationInstance setValue:value forKey:key];
        }
    }
    
    // Set the default postType for a Post instance as "post".
    [destinationInstance setValue:PostTypeDefaultIdentifier forKey:@"postType"];
    
    [manager associateSourceInstance:sourceInstance
             withDestinationInstance:destinationInstance
                    forEntityMapping:mapping];
    return YES;
}

- (BOOL)endEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError *__autoreleasing *)error
{
    DDLogInfo(@"%@ %@ (%@ -> %@)", self, NSStringFromSelector(_cmd), [mapping sourceEntityName], [mapping destinationEntityName]);
    return YES;
}

@end
