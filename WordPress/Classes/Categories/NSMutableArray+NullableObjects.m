#import "NSMutableArray+NullableObjects.h"

@implementation NSMutableArray (NullableObjects)

- (void)addNullableObject:(nullable id)anObject {
    if (anObject != nil) {
        [self addObject:anObject];
    }
}

@end
