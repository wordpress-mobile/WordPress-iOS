#import "ContextManagerMock.h"

@implementation ContextManagerMock

- (instancetype)init
{
    return [super initWithModelName:ContextManagerModelNameCurrent storeURL:[NSURL fileURLWithPath:@"/dev/null"]];
}

- (void)saveContextAndWait:(NSManagedObjectContext *)context
{
    [super saveContextAndWait:context];
    // FIXME: Remove this method to use superclass one instead
    // This log magically resolves a deadlock in
    // `ZDashboardCardTests.testShouldNotShowQuickStartIfDefaultSectionIsSiteMenu`
    NSLog(@"Context save completed");
}

@end
