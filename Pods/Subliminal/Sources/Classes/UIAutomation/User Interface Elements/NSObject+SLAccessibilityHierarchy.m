//
//  NSObject+SLAccessibilityHierarchy.h
//  Subliminal
//
//  For details and documentation:
//  http://github.com/inkling/Subliminal
//
//  Copyright 2013-2014 Inkling Systems, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


#import "NSObject+SLAccessibilityHierarchy.h"
#import "SLLogger.h"


#pragma mark SLAccessibility internal interface

/**
 The methods in the `NSObject (SLAccessibility_Internal)` category describe 
 criteria that factor into `-[NSObject willAppearInAccessibilityHierarchy]`.
 */
@interface NSObject (SLAccessibility_Internal)

/**
 Returns a Boolean value that indicates whether the receiver's accessibility
 traits force its presence in an accessibility hierarchy.

 Experimentation reveals that objects with certain accessibility traits 
 will appear in UIAutomation's accessibility hierarchy regardless of their 
 accessibility identification.

 @return YES if the receiver's accessibility traits force its presence in an
 accessibility hierarchy, otherwise NO.
 */
- (BOOL)accessibilityTraitsForcePresenceInAccessibilityHierarchy;

/**
 Returns a Boolean value that indicates whether the receiver's class
 forces its presence in an accessibility hierarchy.

 Experimentation reveals that objects descending from a certain set of classes 
 will appear in UIAutomation's accessibility hierarchy regardless of their 
 accessibility identification.

 @return YES if the receiver's class forces its presence in an accessibility
 hierarchy, otherwise NO.
 */
- (BOOL)classForcesPresenceInAccessibilityHierarchy;

/**
 Returns a Boolean value that indicates whether the receiver is prevented from
 existing in the accessibility hierarchy by an accessibility element above it in
 the hierarchy.
 
 Experimentation reveals that accessibilityElements decending from certain classes
 prevent any other elements from existing in the hierarchy below them.
 
 @return YES if there exists an element above the receiver in the accessibility hierarchy
 that prevents its accessibility descendents from appearing in the accessibility hierarchy.
 */
- (BOOL)accessibilityAncestorPreventsPresenceInAccessibilityHierarchy;

@end


#pragma mark - NSObject (SLAccessibilityHierarchy) implementation

@implementation NSObject (SLAccessibilityHierarchy)

#pragma mark -Public methods

- (NSUInteger)slIndexOfChildAccessibilityElement:(NSObject *)object favoringSubviews:(BOOL)favoringSubviews {
    NSArray *children = [self slChildAccessibilityElementsFavoringSubviews:favoringSubviews];
    return [children indexOfObject:object];
}

- (NSObject *)slChildAccessibilityElementAtIndex:(NSUInteger)index favoringSubviews:(BOOL)favoringSubviews {
    NSArray *children = [self slChildAccessibilityElementsFavoringSubviews:favoringSubviews];
    if ([children count] > index) {
        return children[index];
    }
    return nil;
}

- (NSArray *)slChildAccessibilityElementsFavoringSubviews:(BOOL)favoringSubviews {
    NSMutableArray *children = [NSMutableArray array];
    // Certain accessibility containers, like those that mock table view headers,
    // may contain "stale" accessibility elements: elements which initially carry no information,
    // but when queried (for some accessibility property) cause their container to reload
    // and replace _all_ of its elements.
    // We ensure we return valid children by asking for the accessibility label of each element,
    // then checking if the container yet vends that element--if it doesn't, we retrieve all children again.
    BOOL shouldReloadChildren, haveReloadedChildren = NO;
    do {
        shouldReloadChildren = NO;
        NSInteger count = [self accessibilityElementCount];
        if (count != NSNotFound && count > 0) {
            for (NSInteger i = 0; i < count; i++) {
                id element = [self accessibilityElementAtIndex:i];
                if (!element) {
                    dispatch_async([[SLLogger sharedLogger] loggingQueue], ^{
                        NSString *message = [NSString stringWithFormat:@"accessibilityElementAtIndex: %ld is nil for %@", (long)i, self];
                        [[SLLogger sharedLogger] logWarning:message];
                    });
                    continue;
                }
                (void)[element accessibilityLabel];
                if (element != [self accessibilityElementAtIndex:i]) {
                    // Protect against tests entering an infinite loop,
                    // in case there's any scenario where the hierarchy might not stabilize.
                    if (haveReloadedChildren) {
                        SLLogAsync(@"The accessibility hierarchy is unstable: the accessibility children of %@ are likely invalid.", self);
                    } else {
                        shouldReloadChildren = YES, haveReloadedChildren = YES;
                        [children removeAllObjects];
                        break;
                    }
                }
                
                [children addObject:element];
            }
        }
    } while (shouldReloadChildren);
    return children;
}

- (NSObject *)slAccessibilityParent {
    if ([self isKindOfClass:[UIView class]]) {
        return [(UIView *)self superview];
    } else if ([self respondsToSelector:@selector(accessibilityContainer)]) {
        return [(UIAccessibilityElement *)self accessibilityContainer];
    } else {
        return nil;
    }
}

- (BOOL)willAppearInAccessibilityHierarchy {
    if ([self accessibilityAncestorPreventsPresenceInAccessibilityHierarchy]) {
        return NO;
    }

    NSString *accessibilityIdentifier;
    if ([self respondsToSelector:@selector(accessibilityIdentifier)]) {
        accessibilityIdentifier = [self performSelector:@selector(accessibilityIdentifier)];
    }
    BOOL isAccessibilityElement = [self isAccessibilityElement];
    
    // In the standard case, an element will appear in the accessibility hierarchy if it returns YES
    // to isAccessibilityElement or has an accessibility identifier.
    if (isAccessibilityElement || [accessibilityIdentifier length] > 0) {
        return YES;
    }

    if ([self accessibilityTraitsForcePresenceInAccessibilityHierarchy]) {
        return YES;
    }

    if ([self classForcesPresenceInAccessibilityHierarchy]) {
        return YES;
    }

    return NO;
}

#pragma mark -Private methods

- (BOOL)accessibilityAncestorPreventsPresenceInAccessibilityHierarchy {
    // An object will not appear in the accessibility hierarchy
    // if an ancestor is an accessibility element.
    id parent = [self slAccessibilityParent];
    while (parent) {
        if ([parent isAccessibilityElement]) {
            return YES;
        }
        parent = [parent slAccessibilityParent];
    }

    // Text fields (when they are editing) and text views (all the time) render their text
    // using something like a web view, which vends an accessibility element--inheriting from `NSObject` though,
    // not `UIAccessibilityElement`--which element represents the current text.
    // This element is not recognized by UIAutomation.
    if (([self accessibilityTraits] & UIAccessibilityTraitStaticText) &&
        ![self isKindOfClass:[UIAccessibilityElement class]] &&
        ![self isKindOfClass:[UIView class]]) {
        // if we're within a text field or text view, abort
        parent = [self slAccessibilityParent];
        while (parent &&
               !([parent isKindOfClass:[UITextField class]] || [parent isKindOfClass:[UITextView class]])) {
            parent = [parent slAccessibilityParent];
        }
        if (parent) return YES;
    }
    
    return NO;
}

- (BOOL)accessibilityTraitsForcePresenceInAccessibilityHierarchy {
    UIAccessibilityTraits traits = self.accessibilityTraits;
    return ((traits & UIAccessibilityTraitButton) ||
            (traits & UIAccessibilityTraitLink) ||
            (traits & UIAccessibilityTraitImage) ||
            (traits & UIAccessibilityTraitKeyboardKey) ||
            (traits & UIAccessibilityTraitStaticText));
}

// At the NSObject level, we identify several private classes that seem to be
// special cases that will always appear in the accessibility hierarchy.
// We identify them by their context to avoid accessing or referencing private APIs.
- (BOOL)classForcesPresenceInAccessibilityHierarchy {
    id parent = [self slAccessibilityParent];

    // We identify UIWebBrowserViews by their superviews and by
    // the non-UIAccessibilityElement objects they vend from elementAtAccessibilityIndex:.
    BOOL isWebBrowserView = NO;
    if([parent isKindOfClass:[UIScrollView class]] &&
       [[parent slAccessibilityParent] isKindOfClass:[UIWebView class]]) {
        NSInteger elementCount = [self accessibilityElementCount];
        if (elementCount != NSNotFound && elementCount > 0) {
            for (NSUInteger i = 0; i < elementCount; i++) {
                id accessibilityObject = [self accessibilityElementAtIndex:i];
                if (![accessibilityObject isKindOfClass:[UIAccessibilityElement class]]) {
                    isWebBrowserView = YES;
                    break;
                }
            }
        }
    }
    if (isWebBrowserView) return YES;

    // UITableViewSectionElements are mock views created for UITableView header views,
    // which return NO from -isAccessibilityElement and do not carry any accessibility
    // information--thus will not otherwise pass -shouldAppearInAccessibilityHierarchy
    // or -elementObject:isMockingViewObject:--but will still appear in the hierarchy.
    // We identify them as accessibility elements vended by their parent table views.
    BOOL isTableViewSectionElement = NO;
    if ([parent isKindOfClass:[UITableView class]] &&
        [self isKindOfClass:[UIAccessibilityElement class]]) {
        NSInteger elementCount = [parent accessibilityElementCount];
        if (elementCount != NSNotFound && elementCount > 0) {
            for (NSUInteger i = 0; i < elementCount; i++) {
                if (self == [parent accessibilityElementAtIndex:i]) {
                    isTableViewSectionElement = YES;
                    break;
                }
            }
        }
    }
    if (isTableViewSectionElement) return YES;

    return NO;
}

@end


#pragma mark UIView overrides

@implementation UIView (SLAccessibilityHierarchy)

- (NSArray *)slChildAccessibilityElementsFavoringSubviews:(BOOL)favoringSubviews {
    if (favoringSubviews) {
        NSMutableArray *children = [[NSMutableArray alloc] init];
        for (UIView *view in [self.subviews reverseObjectEnumerator]) {
            [children addObject:view];
        }
        [children addObjectsFromArray:[super slChildAccessibilityElementsFavoringSubviews:NO]];
        return children;
    } else {
        NSMutableArray *children = [[super slChildAccessibilityElementsFavoringSubviews:NO] mutableCopy];
        for (UIView *view in [self.subviews reverseObjectEnumerator]) {
            [children addObject:view];
        }
        return children;
    }
}

- (BOOL)classForcesPresenceInAccessibilityHierarchy {
    if ([super classForcesPresenceInAccessibilityHierarchy]) return YES;

    // Identify _UIPopoverView by its first subview being a popover background view.
    BOOL isPopover = NO;
    if ([self.subviews count]) {
        isPopover = [self.subviews[0] isKindOfClass:[UIPopoverBackgroundView class]];
    }
    return isPopover;
}

// An object is a mock view if its `accessibilityIdentifier` tracks
// the `accessibilityIdentifier` of the view, or, failing that,
// if its occupies the same region of the same accessibility parent.
+ (BOOL)elementObject:(id)elementObject isMockingViewObject:(id)viewObject {
    if (![viewObject isKindOfClass:[UIView class]]) {
        return NO;
    }
    UIView *view = (UIView *)viewObject;
    NSString *previousIdentifier = view.accessibilityIdentifier;
    view.accessibilityIdentifier = [NSString stringWithFormat:@"%@: %p", [view class], view];

    BOOL isMocking = NO;
    if ([elementObject respondsToSelector:@selector(accessibilityIdentifier)]) {
        NSString *mockIdentifier = [elementObject performSelector:@selector(accessibilityIdentifier)];
        isMocking = [mockIdentifier isEqualToString:view.accessibilityIdentifier];
    }

    view.accessibilityIdentifier = previousIdentifier;

    if (!isMocking) {
        // On iOS 6.1, instances of `UITableViewSectionElement` do not track the `accessibilityIdentifier`s of the views they mock.
        // We don't actually manipulate the accessibility frame of the `viewObject` because
        // we might break that property's syncing with the `viewObject`'s `frame`.
        if ([elementObject slAccessibilityParent] == [viewObject slAccessibilityParent]) {
            isMocking = CGRectEqualToRect([elementObject accessibilityFrame], [viewObject accessibilityFrame]);
        }
    }

    return isMocking;
}

- (BOOL)elementMockingSelfWillAppearInAccessibilityHierarchy {
    if ([self willAppearInAccessibilityHierarchy]) return YES;

    if ([self classForcesPresenceOfMockingViewsInAccessibilityHierarchy]) {
        return YES;
    }

    // table view headers--which need not themselves be accessible to be mocked
    // (so long as they contain accessible elements)
    // and, unlike table view cells, are not necessarily of any particular class
    if ([[self slAccessibilityParent] isKindOfClass:[UITableView class]]) return YES;

    return NO;
}

- (BOOL)classForcesPresenceOfMockingViewsInAccessibilityHierarchy {
    return NO;
}

@end


#pragma mark UIView subclass overrides

@implementation UILabel (SLAccessibilityHierarchy)

- (BOOL)accessibilityAncestorPreventsPresenceInAccessibilityHierarchy {
    if ([super accessibilityAncestorPreventsPresenceInAccessibilityHierarchy]) return YES;

    NSObject *parent = [self slAccessibilityParent];
    // A label will not appear in the accessibility hierarchy
    // if it is contained within a UITableViewCell, at any depth
    // -- UITableViewCells create a mock element that aggregates sublabels' text;
    // we can match that combined label, but not individual labels.
    do {
        if ([parent isKindOfClass:[UITableViewCell class]]) return YES;
    } while ((parent = [parent slAccessibilityParent]));

    return NO;
}

@end


@implementation UITableViewCell (SLAccessibilityHierarchy)
- (BOOL)classForcesPresenceOfMockingViewsInAccessibilityHierarchy {
    return YES;
}
@end


// On iOS 6, collection view cells themselves appear in the accessibility hierarchy.
// On iOS 7, mock cells (instances of `UICollectionViewCellAccessibilityElement`) appear in the hierarchy instead.
@implementation UICollectionViewCell (SLAccessibilityHierarchy)
- (BOOL)classForcesPresenceInAccessibilityHierarchy {
    return kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1;
}
- (BOOL)classForcesPresenceOfMockingViewsInAccessibilityHierarchy {
    return kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_6_1;
}
@end


@implementation UIScrollView (SLAccessibilityHierarchy)
- (BOOL)classForcesPresenceInAccessibilityHierarchy {
    return YES;
}
@end


@implementation UIWebView (SLAccessibilityHierarchy)
- (BOOL)classForcesPresenceInAccessibilityHierarchy {
    return YES;
}
@end


@implementation UITabBar (SLAccessibilityHierarchy)
- (BOOL)classForcesPresenceInAccessibilityHierarchy {
    return YES;
}
@end


@implementation UIToolbar (SLAccessibilityHierarchy)
- (BOOL)classForcesPresenceInAccessibilityHierarchy {
    return YES;
}
@end


@implementation UIActionSheet (SLAccessibilityHierarchy)
- (BOOL)classForcesPresenceInAccessibilityHierarchy {
    return YES;
}
@end


@implementation UINavigationBar (SLAccessibilityHierarchy)
- (BOOL)classForcesPresenceInAccessibilityHierarchy {
    return YES;
}
@end


@implementation UIControl (SLAccessibilityHierarchy)
- (BOOL)classForcesPresenceInAccessibilityHierarchy {
    return YES;
}
@end


@implementation UIAlertView (SLAccessibilityHierarchy)
- (BOOL)classForcesPresenceInAccessibilityHierarchy {
    return YES;
}
@end


@implementation UIWindow (SLAccessibilityHierarchy)
- (BOOL)classForcesPresenceInAccessibilityHierarchy {
    return YES;
}
@end
