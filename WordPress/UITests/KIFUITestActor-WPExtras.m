
#import "KIFUITestActor-WPExtras.h"
#import <KIF.h>
#import "NSError-KIFAdditions.h"
#import "CGGeometry-KIFAdditions.h"

@implementation KIFUITestActor (WPExtras)

- (BOOL)tryFindingViewWithAccessibilityLabelStartingWith:(NSString *)label error:(out NSError **)error
{
    UIAccessibilityElement * accessibilityElement = nil;
    UIView * view = nil;
    return ([self tryFindingAccessibilityElement:&accessibilityElement view:&view withElementMatchingPredicate:[NSPredicate predicateWithFormat:@"accessibilityLabel BEGINSWITH %@", label] tappable:YES error:error]);
}

- (void) tapViewWithAccessibilityLabelStartingWith:(NSString *)label
{
    UIAccessibilityElement * accessibilityElement = nil;
    UIView * view = nil;
    NSError * error = nil;
    if ([self tryFindingAccessibilityElement:&accessibilityElement view:&view withElementMatchingPredicate:[NSPredicate predicateWithFormat:@"accessibilityLabel BEGINSWITH %@", label] tappable:YES error:&error])
    {
        [tester tapAccessibilityElement:accessibilityElement inView:view];
    } else {
        [tester failWithError:[NSError KIFErrorWithFormat:@"Unable to find accesible element with label starting with: %@", label] stopTest:YES];
    }
}

- (void)swipeViewWithAccessibilityIdentifier:(NSString *)identifier inDirection:(KIFSwipeDirection)direction
{
    [self swipeViewWithAccessibilityIdentifier:identifier value:nil traits:UIAccessibilityTraitNone inDirection:direction];
}

- (void)swipeViewWithAccessibilityIdentifier:(NSString *)identifier value:(NSString *)value inDirection:(KIFSwipeDirection)direction
{
    [self swipeViewWithAccessibilityLabel:identifier value:value traits:UIAccessibilityTraitNone inDirection:direction];
}

- (void)swipeViewWithAccessibilityIdentifier:(NSString *)identifier value:(NSString *)value traits:(UIAccessibilityTraits)traits inDirection:(KIFSwipeDirection)direction
{
    const NSUInteger kNumberOfPointsInSwipePath = 20;
    
    // The original version of this came from http://groups.google.com/group/kif-framework/browse_thread/thread/df3f47eff9f5ac8c
    
    UIView *viewToSwipe = nil;
    UIAccessibilityElement *element = nil;
    
    [self waitForAccessibilityElement:&element view:&viewToSwipe withIdentifier:identifier tappable:NO];
    
    // Within this method, all geometry is done in the coordinate system of the view to swipe.
    
    CGRect elementFrame = [viewToSwipe.windowOrIdentityWindow convertRect:element.accessibilityFrame toView:viewToSwipe];
    CGPoint swipeStart = CGPointCenteredInRect(elementFrame);
    KIFDisplacement swipeDisplacement = KIFDisplacementForSwipingInDirection(direction);
    
    [viewToSwipe dragFromPoint:swipeStart displacement:swipeDisplacement steps:kNumberOfPointsInSwipePath];
}

- (BOOL)tryFindingViewWithAccessibilityIdentifier:(NSString *)identifier error:(out NSError **)error
{
    UIAccessibilityElement * accessibilityElement = nil;
    UIView * view = nil;
    return ([self tryFindingAccessibilityElement:&accessibilityElement view:&view withElementMatchingPredicate:[NSPredicate predicateWithFormat:@"accessibilityIdentifier = %@", identifier] tappable:YES error:error]);
}

@end
