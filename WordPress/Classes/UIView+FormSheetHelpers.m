//
//  UIView+FormSheetHelpers.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/6/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "UIView+FormSheetHelpers.h"

// This is a hacky, but it seems like Apple won't give you the correct dimensions of a view inside a form sheet
// until viewDidAppear which will result in a nasty layout flicker because we don't have the correct dimensions
// from self.view.bounds. As such we use these helper methods to get rid of that flicker.
@implementation UIView (FormSheetHelpers)

- (CGFloat)formSheetViewWidth
{
    if (IS_IPAD)
        return 540;
    else
        return CGRectGetWidth(self.bounds);
}

- (CGFloat)formSheetViewHeight
{
    if (IS_IPAD)
        return 620;
    else
        return CGRectGetHeight(self.bounds);
}

@end
