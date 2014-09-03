//
//  SLElement.m
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

#import "SLElement.h"
#import "SLUIAElement+Subclassing.h"
#import "NSObject+SLAccessibilityHierarchy.h"
#import "SLAccessibilityPath.h"
#import "NSObject+SLVisibility.h"
#import "NSObject+SLAccessibilityDescription.h"
#import "UIScrollView+SLProgrammaticScrolling.h"


// The real value (set in `+load`) is not a compile-time constant,
// so we provide a placeholder here.
UIAccessibilityTraits SLUIAccessibilityTraitAny = 0;


@implementation SLElement {
    BOOL (^_matchesObject)(NSObject*);
    NSString *_description;

    BOOL _shouldDoubleCheckValidity;
}

+ (void)load {
    // We create a unique `UIAccessibilityTraits` mask
    // from a combination of traits that should never occur in reality.
    // This value is not a compile-time constant, so we declare it as we load
    // (which is guaranteed to be after UIKit loads, by Subliminal linking UIKit).
    SLUIAccessibilityTraitAny = UIAccessibilityTraitNone | UIAccessibilityTraitButton;
}

+ (instancetype)elementWithAccessibilityLabel:(NSString *)label {
    return [[self alloc] initWithPredicate:^BOOL(NSObject *obj) {
        return [obj.accessibilityLabel isEqualToString:label];
    } description:label];
}

+ (id)elementWithAccessibilityLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits {
    NSString *traitsString;
    if (traits == SLUIAccessibilityTraitAny) {
        traitsString = @"(any)";
    } else {
        NSMutableArray *traitNames = [NSMutableArray array];
        
        if (traits & UIAccessibilityTraitButton)                  [traitNames addObject:@"Button"];
        if (traits & UIAccessibilityTraitLink)                    [traitNames addObject:@"Link"];
        // UIAccessibilityTraitHeader is only available starting in iOS 6
        if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_5_1) {
            if (traits & UIAccessibilityTraitHeader)                  [traitNames addObject:@"Header"];
        }
        if (traits & UIAccessibilityTraitSearchField)             [traitNames addObject:@"Search Field"];
        if (traits & UIAccessibilityTraitImage)                   [traitNames addObject:@"Image"];
        if (traits & UIAccessibilityTraitSelected)                [traitNames addObject:@"Selected"];
        if (traits & UIAccessibilityTraitPlaysSound)              [traitNames addObject:@"Plays Sound"];
        if (traits & UIAccessibilityTraitKeyboardKey)             [traitNames addObject:@"Keyboard Key"];
        if (traits & UIAccessibilityTraitStaticText)              [traitNames addObject:@"Static Text"];
        if (traits & UIAccessibilityTraitSummaryElement)          [traitNames addObject:@"Summary Element"];
        if (traits & UIAccessibilityTraitNotEnabled)              [traitNames addObject:@"Not Enabled"];
        if (traits & UIAccessibilityTraitUpdatesFrequently)       [traitNames addObject:@"Updates Frequently"];
        if (traits & UIAccessibilityTraitStartsMediaSession)      [traitNames addObject:@"Starts Media Session"];
        if (traits & UIAccessibilityTraitAdjustable)              [traitNames addObject:@"Adjustable"];
        if (traits & UIAccessibilityTraitAllowsDirectInteraction) [traitNames addObject:@"Allows Direct Interaction"];
        if (traits & UIAccessibilityTraitCausesPageTurn)          [traitNames addObject:@"Causes Page Turn"];

        if ([traitNames count]) {
            traitsString = [NSString stringWithFormat:@"(%@)", [traitNames componentsJoinedByString:@", "]];
        } else {
            traitsString = @"(none)";
        }
    }

    return [[self alloc] initWithPredicate:^BOOL(NSObject *obj) {
        BOOL matchesLabel   = ((label == nil) || [obj.accessibilityLabel isEqualToString:label]);
        // in iOS 6.1 (at least), `UITextView` returns an attributed string from `-accessibilityValue`
        // as does `UISearchBarTextField` in iOS 7  >.<
        id accessibilityValue = obj.accessibilityValue;
        if ([accessibilityValue isKindOfClass:[NSAttributedString class]]) {
            accessibilityValue = [accessibilityValue string];
        }
        BOOL matchesValue   = ((value == nil) || [accessibilityValue isEqualToString:value]);
        BOOL matchesTraits  = ((traits == SLUIAccessibilityTraitAny) || ((obj.accessibilityTraits & traits) == traits));
        return (matchesLabel && matchesValue && matchesTraits);
    } description:[NSString stringWithFormat:@"label: %@; value: %@; traits: %@", label, value, traitsString]];
}

+ (instancetype)elementWithAccessibilityIdentifier:(NSString *)identifier {
    return [[self alloc] initWithPredicate:^BOOL(NSObject *obj) {
        if (![obj respondsToSelector:@selector(accessibilityIdentifier)]) return NO;

        return [[obj performSelector:@selector(accessibilityIdentifier)] isEqualToString:identifier];
    } description:identifier];
}

+ (instancetype)elementMatching:(BOOL (^)(NSObject *obj))predicate withDescription:(NSString *)description {
    return [[self alloc] initWithPredicate:predicate description:description];
}

+ (instancetype)anyElement {
    return [[self alloc] initWithPredicate:^BOOL(NSObject *obj) {
        return YES;
    } description:@"any element"];
}

- (instancetype)initWithPredicate:(BOOL (^)(NSObject *))predicate description:(NSString *)description {
    self = [super init];
    if (self) {
        _matchesObject = predicate;
        _description = [description copy];
    }
    return self;
}

- (BOOL)matchesObject:(NSObject *)object
{
    NSAssert(_matchesObject, @"matchesObject called on %@, which has no _matchesObject predicate", self);
    BOOL matchesObject = _matchesObject(object);

    return (matchesObject && [object willAppearInAccessibilityHierarchy]);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ description:\"%@\">", NSStringFromClass([self class]), _description];
}

- (BOOL)canDetermineTappabilityUsingAccessibilityPath:(SLAccessibilityPath *)path {
    BOOL canDetermineTappability = YES;
    if ((kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1)
        && ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)) {
        __block BOOL matchingObjectIsScrollView = NO;
        [path examineLastPathComponent:^(NSObject *lastPathComponent) {
            matchingObjectIsScrollView = [lastPathComponent isKindOfClass:[UIScrollView class]];
        }];
        canDetermineTappability = !matchingObjectIsScrollView;
    }
    return canDetermineTappability;
}

- (BOOL)canDetermineTappability {
    BOOL canDetermineTappability = YES;
    // incur the cost of a path lookup only if necessary
    if ((kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1)
        && ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)) {
        // like `-isTappable`, evaluate the current state, no waiting to resolve the element
        SLAccessibilityPath *accessibilityPath = [self accessibilityPathWithTimeout:0.0];
        if (!accessibilityPath) {
            [NSException raise:SLUIAElementInvalidException format:@"Element '%@' does not exist.", self];
        }
        canDetermineTappability = [self canDetermineTappabilityUsingAccessibilityPath:accessibilityPath];
    }
    return canDetermineTappability;
}

- (BOOL)shouldDoubleCheckValidity {
    return _shouldDoubleCheckValidity;
}

- (void)setShouldDoubleCheckValidity:(BOOL)shouldDoubleCheckValidity {
    _shouldDoubleCheckValidity = shouldDoubleCheckValidity;
}

- (SLAccessibilityPath *)accessibilityPathWithTimeout:(NSTimeInterval)timeout {
    __block SLAccessibilityPath *accessibilityPath = nil;
    NSDate *startDate = [NSDate date];
    // a timeout of 0 means check once--but then return immediately, no waiting
    do {
        dispatch_sync(dispatch_get_main_queue(), ^{
            accessibilityPath = [[[UIApplication sharedApplication] keyWindow] slAccessibilityPathToElement:self];
        });
        if (accessibilityPath || !timeout) break;

        [NSThread sleepForTimeInterval:SLUIAElementWaitRetryDelay];
    } while ([[NSDate date] timeIntervalSinceDate:startDate] < timeout);
    return accessibilityPath;
}

- (void)waitUntilTappable:(BOOL)waitUntilTappable
        thenPerformActionWithUIARepresentation:(void(^)(NSString *UIARepresentation))block
                                       timeout:(NSTimeInterval)timeout {
    __block NSTimeInterval remainingTimeout = timeout;
    __block BOOL didCheckTappability = NO, automationRaisedTappabilityException = NO;
    NSException *__block actionException;
    do {
        actionException = nil;
        
        NSDate *resolutionStart = [NSDate date];
        SLAccessibilityPath *accessibilityPath = [self accessibilityPathWithTimeout:remainingTimeout];
        NSTimeInterval resolutionDuration = [[NSDate date] timeIntervalSinceDate:resolutionStart];
        remainingTimeout -= resolutionDuration;

        if (!accessibilityPath) {
            [NSException raise:SLUIAElementInvalidException format:@"Element '%@' does not exist.", self];
        }
        
        // It's possible, if unlikely, that one or more path components could have dropped
        // out of scope between the path's construction and its binding/serialization
        // here. If the representation is invalid, UIAutomation will throw an exception,
        // and it will be caught by Subliminal.
        [accessibilityPath bindPath:^(SLAccessibilityPath *boundPath) {
            // catch and rethrow exceptions so that we can unbind the path
            @try {
                NSString *UIARepresentation = [boundPath UIARepresentation];

                if (self.shouldDoubleCheckValidity) {
                    BOOL uiaIsValid = [[[SLTerminal sharedTerminal] evalWithFormat:@"%@.isValid()", UIARepresentation] boolValue];
                    if (!uiaIsValid) {
                        // Subliminal is not properly identifying the element to UIAutomation:
                        // there is a bug in `SLAccessibilityPath` or `NSObject (SLAccessibilityHierarchy)`
                        [NSException raise:SLUIAElementInvalidException format:@"Element '%@' does not exist at path '%@'.", self, UIARepresentation];
                    }
                }

                // evaluate canDetermineTappability using the current path
                // because we can't retrieve another while the element is bound
                if (waitUntilTappable && [self canDetermineTappabilityUsingAccessibilityPath:accessibilityPath]) {
                    NSDate *tappabilityCheckStart = [NSDate date];
                    BOOL isTappable = [[SLTerminal sharedTerminal] waitUntilFunctionWithNameIsTrue:[[self class]SLElementIsTappableFunctionName]
                                                                             whenEvaluatedWithArgs:@[ UIARepresentation ]
                                                                                        retryDelay:SLUIAElementWaitRetryDelay
                                                                                           timeout:remainingTimeout];
                    NSTimeInterval tappabilityCheckDuration = [[NSDate date] timeIntervalSinceDate:tappabilityCheckStart];
                    remainingTimeout -= tappabilityCheckDuration;
                    didCheckTappability = YES;

                    if (!isTappable) [NSException raise:SLUIAElementNotTappableException format:@"Element '%@' is not tappable.", self];
                }
                block(UIARepresentation);
            }
            @catch (NSException *exception) {
                // rename JavaScript exceptions to make the context of the exception clear
                if ([[exception name] isEqualToString:SLTerminalJavaScriptException]) {
                    exception = [NSException exceptionWithName:SLUIAElementAutomationException
                                                        reason:[exception reason] userInfo:[exception userInfo]];
                }
                actionException = exception;
            }
        }];

        // In certain circumstances (e.g. during animations, when the view hierarchy is undergoing rapid modification)
        // it's possible for Subliminal to identify a valid and tappable element, only for that element to have
        // been replaced in the accessibility hierarchy by the time that UIAutomation goes to manipulate the element.
        // This results in UIAutomation raising an exception about the element not being tappable
        // --despite Subliminal's tappability check having succeeded. If this occurs and time remains, we retry.
        automationRaisedTappabilityException =  [[actionException name] isEqualToString:SLUIAElementAutomationException] &&
                                                [[actionException reason] hasSuffix:@"could not be tapped"];
    } while (didCheckTappability && automationRaisedTappabilityException && (remainingTimeout > 0));
    if (actionException) @throw actionException;
}

- (void)examineMatchingObject:(void (^)(NSObject *object))block {
    [self examineMatchingObject:block timeout:[[self class] defaultTimeout]];
}

- (void)examineMatchingObject:(void (^)(NSObject *))block timeout:(NSTimeInterval)timeout {
    NSParameterAssert(block);

    __block NSTimeInterval remainingTimeout = timeout;
    NSException *__block examinationException;
    do {
        examinationException = nil;

        NSDate *resolutionStart = [NSDate date];
        SLAccessibilityPath *accessibilityPath = [self accessibilityPathWithTimeout:remainingTimeout];
        NSTimeInterval resolutionDuration = [[NSDate date] timeIntervalSinceDate:resolutionStart];
        remainingTimeout -= resolutionDuration;
        
        if (!accessibilityPath) {
            [NSException raise:SLUIAElementInvalidException format:@"Element '%@' does not exist.", self];
        }

        [accessibilityPath examineLastPathComponent:^(NSObject *lastPathComponent) {
            // It's possible, if unlikely, that the matching object could have dropped
            // out of scope between the path's construction and its examination here
            if (!lastPathComponent) {
                examinationException = [NSException exceptionWithName:SLUIAElementInvalidException
                                                               reason:[NSString stringWithFormat:@"Element %@ does not exist.", self] userInfo:nil];
                return;
            }
            block(lastPathComponent);
        }];

        // if the matching object dropped out of scope, retry while the timeout has not elapsed
    } while (examinationException && (remainingTimeout > 0));
    if (examinationException) @throw examinationException;
}

- (BOOL)isValid {
    // isValid evaluates the current state, no waiting to resolve the element
    SLAccessibilityPath *accessibilityPath = [self accessibilityPathWithTimeout:0.0];
    __block BOOL isValid = (accessibilityPath != nil);
    if (isValid && self.shouldDoubleCheckValidity) {
        [accessibilityPath bindPath:^(SLAccessibilityPath *boundPath) {
            NSString *UIARepresentation = [boundPath UIARepresentation];
            isValid = [[[SLTerminal sharedTerminal] evalWithFormat:@"%@.isValid()", UIARepresentation] boolValue];
        }];
    }
    return isValid;
}

/*
 Subliminal's implementation of -isVisible does not rely upon UIAutomation to check
 visibility of UIViews or UIAccessibilityElements, because UIAElement.isVisible()
 has a number of bugs. See SLElementVisibilityTest for more information. For some classes,
 for example those vended by UIWebBrowserView, we cannot fully determine whether or not
 they will be visible, and must depend on UIAutomation to confirm visibility.
 */
- (BOOL)isVisible {
    // Temporarily use UIAutomation to check visibility if the device is in a non-portrait orientation
    // to work around https://github.com/inkling/Subliminal/issues/135
    if ([UIDevice currentDevice].orientation != UIDeviceOrientationPortrait) {
        return [super isVisible];
    }

    __block BOOL isVisible = NO;
    __block BOOL matchedObjectOfUnknownClass = NO;
    // isVisible evaluates the current state, no waiting to resolve the element
    [self examineMatchingObject:^(NSObject *object) {
        isVisible = [object slAccessibilityIsVisible];
        matchedObjectOfUnknownClass = ![object isKindOfClass:[UIView class]] && ![object isKindOfClass:[UIAccessibilityElement class]];
    } timeout:0.0];

    if (isVisible && matchedObjectOfUnknownClass) {
        isVisible = [super isVisible];
    }

    return isVisible;
}

#pragma mark -

- (void)tapAtActivationPoint {
    __block CGPoint activationPoint;
    __block CGRect accessibilityFrame;
    [self examineMatchingObject:^(NSObject *object) {
        activationPoint = [object accessibilityActivationPoint];
        accessibilityFrame = [object accessibilityFrame];
    }];

    CGPoint activationOffset = (CGPoint){
        .x = (activationPoint.x - CGRectGetMinX(accessibilityFrame)) / CGRectGetWidth(accessibilityFrame),
        .y = (activationPoint.y - CGRectGetMinY(accessibilityFrame)) / CGRectGetHeight(accessibilityFrame)
    };
    [self waitUntilTappable:YES thenSendMessage:@"tapWithOptions({tapOffset:{x:%g, y:%g}})", activationOffset.x, activationOffset.y];
}

- (void)dragWithStartOffset:(CGPoint)startOffset endOffset:(CGPoint)endOffset {
    // In the iOS 7 Simulator, scroll views' pan gesture recognizers fail to cause those views to scroll
    // in response to UIAutomation drag gestures, so we must programmatically scroll those views.
#if TARGET_IPHONE_SIMULATOR
    if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_6_1) {
        [self examineMatchingObject:^(NSObject *object) {
            if ([object isKindOfClass:[UIScrollView class]]) {
                [(UIScrollView *)object slScrollWithStartOffset:startOffset endOffset:endOffset];
            }
        }];
    }
#endif

    // Even if we programmatically dragged a scroll view above, we concurrently ask `UIAutomation` to drag the view,
    // because scroll views(' `UIResponder` method implementations) do receive the touches involved in drag gestures
    // and our programmatic scroll method does not deliver such touches.
    [super dragWithStartOffset:startOffset endOffset:endOffset];
}

#pragma mark -

- (NSString *)accessibilityDescription {
    NSString *__block description = nil;
    [self examineMatchingObject:^(NSObject *object) {
        description = [object slAccessibilityDescription];
    }];
    return description;
}

- (void)logElement {
    SLLog(@"%@", [self accessibilityDescription]);
}

// First log the element using `-slAccessibilityDescription` so the user can see the unbound name
// (https://github.com/inkling/Subliminal/issues/65 ), but otherwise use UIAutomation to log the tree
// because it will log just those elements in the accessibility hierarchy,
// which would be expensive for us to determine.
- (void)logElementTree {
    SLLog(@"Logging the tree rooted in %@:", [self accessibilityDescription]);
    [super logElementTree];
}

@end
