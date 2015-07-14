#import "LocalCoreDataService.h"

@interface LocalCoreDataService ()
@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;
@end

@implementation LocalCoreDataService

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    NSParameterAssert([context isKindOfClass:[NSManagedObjectContext class]]);
    
    self = [super init];
    if (self) {
        _managedObjectContext = context;
    }
    
    return self;
}

@end
