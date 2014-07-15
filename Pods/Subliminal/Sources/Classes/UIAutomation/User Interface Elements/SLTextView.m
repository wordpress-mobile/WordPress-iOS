//
//  SLTextView.m
//  Subliminal
//
//  Created by Jeffrey Wear on 7/29/13.
//  Copyright (c) 2013 Inkling. All rights reserved.
//

#import "SLTextView.h"
#import "SLUIAElement+Subclassing.h"

@implementation SLTextView

- (NSString *)text {
    return [self value];
}

- (void)setText:(NSString *)text
{
    [self setText:text withKeyboard:_defaultKeyboard ?: [SLKeyboard keyboard]];
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
    return [super matchesObject:object] && [object isKindOfClass:[UITextView class]];
}

@end


@implementation SLWebTextView
// `SLWebTextView` does not inherit from `SLTextView`
// because the elements it matches, web text views, are not instances of `UITextView`
// but rather a private type of accessibility element.
//
// UIAutomation actually considers these elements to be text fields (instances of `UIATextField`)
// even if they represent multi-line HTML text areas, but Subliminal represents them as a distinct
// "text view" element for parity with `UIKit` controls (`UITextField`/`SLTextField` vs. `UITextView`/`SLTextView`).

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
