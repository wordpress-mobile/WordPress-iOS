//
//  SLTextField.m
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

#import "SLTextField.h"
#import "SLUIAElement+Subclassing.h"

@implementation SLTextField

- (NSString *)text {
    return [self value];
}

- (void)setText:(NSString *)text {
    [self setText:text withKeyboard: _defaultKeyboard ?: [SLKeyboard keyboard]];
}

- (void)setText:(NSString *)text withKeyboard:(id<SLKeyboard>)keyboard
{
    // Tap to show the keyboard (if the field doesn't already have keyboard focus,
    // because in that case a real user would probably not tap again before typing)
    if (![self hasKeyboardFocus]) {
        [self tap];
    }

    // Clear any current text before typing the new text.
    [self waitUntilTappable:YES thenSendMessage:@"setValue('')"];
    if ([keyboard respondsToSelector:@selector(typeString:withSetValueFallbackUsingElement:)]) {
        [keyboard typeString:text withSetValueFallbackUsingElement:self];
    } else {
        [keyboard typeString:text];
    }
}

- (BOOL)matchesObject:(NSObject *)object {
    return [super matchesObject:object] && [object isKindOfClass:[UITextField class]];
}

@end


#pragma mark - SLSearchField

@implementation SLSearchField

+ (instancetype)elementWithAccessibilityLabel:(NSString *)label {
    SLLog(@"An %@ can't be matched by accessibility properties--see the comments on its @interface. \
          Returning +anyElement.", NSStringFromClass(self));
    return [self anyElement];
}

+ (instancetype)elementWithAccessibilityLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits {
    SLLog(@"An %@ can't be matched by accessibility properties--see the comments on its @interface. \
          Returning +anyElement.", NSStringFromClass(self));
    return [self anyElement];
}

+ (instancetype)elementWithAccessibilityIdentifier:(NSString *)identifier {
    SLLog(@"An %@ can't be matched by accessibility properties--see the comments on its @interface. \
          Returning +anyElement.", NSStringFromClass(self));
    return [self anyElement];
}

- (BOOL)matchesObject:(NSObject *)object {
    return ([super matchesObject:object] && ([object accessibilityTraits] & UIAccessibilityTraitSearchField));
}

@end


@implementation SLWebTextField
// SLWebTextField does not inherit from SLTextField
// because the elements it matches, web text fields, are not instances of UITextField
// but rather a private type of accessibility element.

- (NSString *)text {
    return [self value];
}

- (void)setText:(NSString *)text {
    // Tap to show the keyboard (if the field doesn't already have keyboard focus,
    // because in that case a real user would probably not tap again before typing)
    BOOL didNewlyBecomeFirstResponder = NO;
    if (![self hasKeyboardFocus]) {
        didNewlyBecomeFirstResponder = YES;
        [self tap];
    }

    // Clear any current text before typing the new text.
    // Unfortunately, you can't set the value (text) of a web text field to the empty string: `setValue('')` simply fails.
    // So, if there's text to clear, we set the text to a single space and then delete that.
    if ([[self text] length]) {
        // If the field newly became first responder, we must delay for a second or `setValue('')` won't have an effect.
        if (didNewlyBecomeFirstResponder) {
            [NSThread sleepForTimeInterval:1.0];
        }
        [self waitUntilTappable:YES thenSendMessage:@"setValue(' ')"];
        [[SLKeyboardKey elementWithAccessibilityLabel:@"Delete"] tap];
    }

    [[SLKeyboard keyboard] typeString:text withSetValueFallbackUsingElement:self];
}

@end
