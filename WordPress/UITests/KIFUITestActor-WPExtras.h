#import "KIFUITestActor.h"

@interface KIFUITestActor (WPExtras)

- (BOOL)tryFindingViewWithAccessibilityLabelStartingWith:(NSString *)label error:(out NSError **)error;

- (void) tapViewWithAccessibilityLabelStartingWith:(NSString *)label;

- (void)swipeViewWithAccessibilityIdentifier:(NSString *)identifier inDirection:(KIFSwipeDirection)direction;

- (void)swipeViewWithAccessibilityIdentifier:(NSString *)identifier value:(NSString *)value inDirection:(KIFSwipeDirection)direction;

- (void)swipeViewWithAccessibilityIdentifier:(NSString *)identifier value:(NSString *)value traits:(UIAccessibilityTraits)traits inDirection:(KIFSwipeDirection)direction;

- (BOOL)tryFindingViewWithAccessibilityIdentifier:(NSString *)identifier error:(out NSError **)error;

@end
