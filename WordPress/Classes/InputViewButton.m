/*
 * InputViewButton.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "InputViewButton.h"

@implementation InputViewButton

@synthesize inputView = _inputView;

- (UIView *)inputView {
    return _inputView;
}

- (void)setInputView:(UIView *)inputView {
    if (_inputView != inputView) {
        _inputView = inputView;
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

@end
