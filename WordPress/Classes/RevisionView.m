//
//  RevisionView.m
//  WordPress
//
//  Created by Maxime Biais on 10/07/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "RevisionView.h"

@implementation RevisionView

- (void)awakeFromNib {
    // Main view
    self.layer.cornerRadius = 10;
    self.layer.masksToBounds = YES;
    self.layer.borderWidth = 1;
    self.layer.borderColor = [UIColor grayColor].CGColor;

    // Textview
    UITextView *textView;
    for (id subview in self.subviews) {
        if([subview isKindOfClass:[UITextView class]]) {
            textView = (UITextView *) subview;
            break;
        }
    }
    textView.layer.cornerRadius = 5;
    textView.layer.masksToBounds = YES;
}

@end
