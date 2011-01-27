//
//  EditPageViewController.m
//  WordPress
//
//  Created by Chris Boyd on 9/4/10.
//

#import "EditPageViewController.h"

@implementation EditPageViewController

// Hides tags/categories fileds by putting text view above them
- (CGRect)normalTextFrame {
    CGRect frame = [super normalTextFrame];
    // 93 is the height of Tags+Categories rows
    frame.origin.y -= 93;
    frame.size.height += 93;
    return frame;
}

@end
