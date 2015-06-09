#import "PostToPost30To31.h"
#import "AbstractPost.h"

@implementation PostToPost30To31

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

    // Sets the new meta publish immediately property value.
    id value = [sourceInstance valueForKey:@"date_created_gmt"];
    id metaValue = (!value || [value isEqual:[NSNull null]]) ? @YES : @NO;
    [destinationInstance setValue:metaValue forKey:@"metaPublishImmediately"];

    // Sets the new meta is local property value.
    value = [sourceInstance valueForKey:@"remoteStatusNumber"];
    metaValue = [value isEqualToNumber:@2]? @YES : @NO;
    [destinationInstance setValue:metaValue forKey:@"metaIsLocal"];

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
