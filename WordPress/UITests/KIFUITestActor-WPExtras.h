#import "KIFUITestActor.h"

@interface KIFUITestActor (WPExtras)

- (BOOL)tryFindingViewWithAccessibilityLabelStartingWith:(NSString *)label error:(out NSError **)error;

- (void) tapViewWithAccessibilityLabelStartingWith:(NSString *)label;

- (BOOL)tryFindingViewWithAccessibilityIdentifier:(NSString *)identifier error:(out NSError **)error;

- (void) tapViewWithAccessibilityIdentifier:(NSString *)identifier;

@end
