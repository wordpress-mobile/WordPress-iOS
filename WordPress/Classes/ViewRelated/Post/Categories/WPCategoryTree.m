#import "WPCategoryTree.h"

@implementation WPCategoryTree

- (id)initWithParent:(PostCategory *)parent
{
    if (self = [super init]) {
        self.parent = parent;
        self.children = [NSMutableArray array];
    }

    return self;
}

- (void)getChildrenFromObjects:(NSArray *)collection
{
    NSUInteger count = [collection count];

    for (NSUInteger i = 0; i < count; i++) {
        PostCategory *category = [collection objectAtIndex:i];

        // self.parent can be nil, so compare int values to avoid badness
        if ([category.parentID intValue] == [self.parent.categoryID intValue]) {
            WPCategoryTree *child = [[WPCategoryTree alloc] initWithParent:category];
            [child getChildrenFromObjects:collection];
            [self.children addObject:child];
        }
    }
}

- (NSArray *)getAllObjects
{
    NSMutableArray *allObjects = [NSMutableArray array];
    NSUInteger count = [self.children count];

    if (self.parent) {
        [allObjects addObject:self.parent];
    }

    for (NSUInteger i = 0; i < count; i++) {
        [allObjects addObjectsFromArray:[[self.children objectAtIndex:i] getAllObjects]];
    }

    return allObjects;
}

@end
