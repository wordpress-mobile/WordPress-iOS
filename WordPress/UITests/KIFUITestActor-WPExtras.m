//
//  KIFUITestActor.m
//  WordPress
//
//  Created by Sergio Estevao on 14/10/2014.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "KIFUITestActor-WPExtras.h"
#import <KIF.h>
#import "NSError-KIFAdditions.h"

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

- (BOOL)tryFindingViewWithAccessibilityIdentifier:(NSString *)identifier error:(out NSError **)error
{
    UIAccessibilityElement * accessibilityElement = nil;
    UIView * view = nil;
    return ([self tryFindingAccessibilityElement:&accessibilityElement view:&view withElementMatchingPredicate:[NSPredicate predicateWithFormat:@"accessibilityIdentifier = %@", identifier] tappable:YES error:error]);
}

- (void) tapViewWithAccessibilityIdentifier:(NSString *)identifier
{
    UIAccessibilityElement * accessibilityElement = nil;
    UIView * view = nil;
    NSError * error = nil;
    if ([self tryFindingAccessibilityElement:&accessibilityElement view:&view withElementMatchingPredicate:[NSPredicate predicateWithFormat:@"accessibilityIdentifier = %@", identifier] tappable:YES error:&error])
    {
        [tester tapAccessibilityElement:accessibilityElement inView:view];
    } else {
        [tester failWithError:[NSError KIFErrorWithFormat:@"Unable to find accesible element with identifier: %@", identifier] stopTest:YES];
    }
}

@end
