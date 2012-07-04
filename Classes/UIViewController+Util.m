//
//  UIViewController+Util.m
//  WordPress
//
//  Created by Dan Roundhill on 7/4/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "UIViewController+Util.h"

@implementation UIViewController (Util)

- (void)setTitle:(NSString *)title
{
    //Change title color on iOS 4
    if (![[UINavigationBar class] respondsToSelector:@selector(appearance)]) {
        UILabel *titleView = (UILabel *)self.navigationItem.titleView;
        if (!titleView) {
            titleView = [[UILabel alloc] initWithFrame:CGRectZero];
            titleView.backgroundColor = [UIColor clearColor];
            titleView.font = [UIFont boldSystemFontOfSize:20.0];
            titleView.shadowColor = [UIColor whiteColor];
            titleView.shadowOffset = CGSizeMake(0.0, 1.0);
            titleView.textColor = [UIColor colorWithRed:70.0/255.0 green:70.0/255.0 blue:70.0/255.0 alpha:1.0];
            
            self.navigationItem.titleView = titleView;
            [titleView release];
        }
        titleView.text = title;
        [titleView sizeToFit];
    }
}

@end
