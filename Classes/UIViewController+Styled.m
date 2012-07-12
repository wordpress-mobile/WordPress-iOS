//
//  UIViewController+Styled.m
//  WordPress
//
//  Created by Jorge Bernal on 7/12/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "UIViewController+Styled.h"
#import "UIBarButtonItem+Styled.h"

#import <objc/runtime.h>

@implementation UIViewController (Styled)

- (void)setStyledEditing:(BOOL)editing animated:(BOOL)animated {
    // Since we exchanged implementations, this actually calls UIKit's setEditing:animated:
    [self setStyledEditing:editing animated:animated];
    if (editing) {
        [UIBarButtonItem styleButtonAsPrimary:self.editButtonItem];
    } else {
        [UIBarButtonItem restoreDefaultButtonStyle:self.editButtonItem];
    }
}

+ (void)load {
    if ([[UIBarButtonItem class] respondsToSelector:@selector(appearance)]) {
        Method origMethod = class_getInstanceMethod(self, @selector(setEditing:animated:));
        Method newMethod = class_getInstanceMethod(self, @selector(setStyledEditing:animated:));
        method_exchangeImplementations(origMethod, newMethod);
    }
}

@end
