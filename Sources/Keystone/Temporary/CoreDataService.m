#import "CoreDataService.h"

@import WordPressDataObjC;

@implementation CoreDataService

- (instancetype)initWithCoreDataStack:(id<CoreDataStack>)coreDataStack
{
    self = [super init];
    if (self) {
        _coreDataStack = coreDataStack;
    }
    return self;
}

@end
