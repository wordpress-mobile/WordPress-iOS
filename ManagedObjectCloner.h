@interface ManagedObjectCloner : NSObject {
}

+(NSManagedObject *)clone:(NSManagedObject *)source inContext:(NSManagedObjectContext *)context;

@end
