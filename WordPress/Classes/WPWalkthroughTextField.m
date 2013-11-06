//
//  WPWalkthroughTextField.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/30/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPWalkthroughTextField.h"

@implementation WPWalkthroughTextField

- (id)init
{
    
    self = [super init];
    if (self)
    {
        self.textInsets = UIEdgeInsetsMake(7, 10, 7, 10);
    }
    return self;
}

// placeholder position
- (CGRect)textRectForBounds:(CGRect)bounds
{
    return CGRectMake(_textInsets.left, _textInsets.top, bounds.size.width - _textInsets.left - _textInsets.right, bounds.size.height - _textInsets.top - _textInsets.bottom);
}

// text position
- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return CGRectMake(_textInsets.left, _textInsets.top, bounds.size.width - _textInsets.left - _textInsets.right, bounds.size.height - _textInsets.top - _textInsets.bottom);
}

@end
