//
//  NSObject+SLAccessibilityDescription.m
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

#import "NSObject+SLAccessibilityDescription.h"
#import "SLStringUtilities.h"

#import <UIKit/UIKit.h>

@implementation NSObject (SLAccessibilityDescription)

- (NSString *)slAccessibilityDescription {
    NSInteger count = [self accessibilityElementCount];
    if (![self isAccessibilityElement] && (count == NSNotFound || count == 0) && ![self respondsToSelector:@selector(accessibilityIdentifier)]) {
        return [NSString stringWithFormat:@"<%@: %p; (not accessible)>", NSStringFromClass([self class]), self];
    }

    // Build a semicolon separated list of properties
    NSMutableArray *properties = [NSMutableArray array];

    [properties addObject:[NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self]];
    CGRect frame = [self accessibilityFrame];
    [properties addObject:[NSString stringWithFormat:@"frame = (%g %g; %g %g)", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height]];
    if ([self respondsToSelector:@selector(accessibilityIdentifier)]) {
        NSString *identifier = [(id)self accessibilityIdentifier];
        if ([identifier length]) {
            [properties addObject:[NSString stringWithFormat:@"id = '%@'", [identifier slStringByEscapingForJavaScriptLiteral]]];
        }
    }
    if ([self.accessibilityLabel length]) {
        [properties addObject:[NSString stringWithFormat:@"label = '%@'", [self.accessibilityLabel slStringByEscapingForJavaScriptLiteral]]];
    }
    // in iOS 6.1 (at least), `UITextView` returns an attributed string from `-accessibilityValue`
    // as does `UISearchBarTextField` in iOS 7  >.<
    id accessibilityValue = self.accessibilityValue;
    if ([accessibilityValue isKindOfClass:[NSAttributedString class]]) {
        accessibilityValue = [accessibilityValue string];
    }
    if ([accessibilityValue length]) {
        [properties addObject:[NSString stringWithFormat:@"value = '%@'", [accessibilityValue slStringByEscapingForJavaScriptLiteral]]];
    }
    if ([self.accessibilityHint length]) {
        [properties addObject:[NSString stringWithFormat:@"hint = '%@'", [self.accessibilityHint slStringByEscapingForJavaScriptLiteral]]];
    }

    UIAccessibilityTraits traits = self.accessibilityTraits;
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
        [properties addObject:[NSString stringWithFormat:@"traits = (%@)", [traitNames componentsJoinedByString:@", "]]];
    }
    if (self.isAccessibilityElement) {
        [properties addObject:@"accessibilityElement = YES"];
    }
    return [NSString stringWithFormat:@"<%@>", [properties componentsJoinedByString:@"; "]];
}

/**
 This method does not use [NSObject slChildAccessibilityElements] because it needs to visually
 differentiate between UIViews and UIAccessibilityContainers. However, it should display elements
 in the same order.
 */
- (NSString *)slRecursiveAccessibilityDescription {
    NSMutableString *recursiveDescription = [[self slAccessibilityDescription] mutableCopy];

    NSInteger count = [self accessibilityElementCount];
    if (count != NSNotFound && count > 0) {
        for (NSInteger i = 0; i < count; i++) {
            id element = [self accessibilityElementAtIndex:i];
            NSString *description = [element slRecursiveAccessibilityDescription];
            [recursiveDescription appendFormat:@"\n  + %@", [description stringByReplacingOccurrencesOfString:@"\n" withString:@"\n  + "]];
        }
    }

    if ([self isKindOfClass:[UIView class]]) {
        for (UIView *view in [(UIView *)self subviews]) {
            NSString *description = [view slRecursiveAccessibilityDescription];
            [recursiveDescription appendFormat:@"\n  | %@", [description stringByReplacingOccurrencesOfString:@"\n" withString:@"\n  | "]];
        }
    }

    return recursiveDescription;
}

@end
