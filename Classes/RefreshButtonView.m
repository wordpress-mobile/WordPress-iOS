//
//  RefreshButtonView.m
//  WordPress
//
//  Created by Josh Bassett on 9/07/09.
//

#import "RefreshButtonView.h"

#define REFRESH_BUTTON_ICON @"sync.png"

@implementation RefreshButtonView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIImage *buttonImage = [UIImage imageNamed:REFRESH_BUTTON_ICON];
        button = [[UIButton alloc] initWithFrame:frame];
        [button setImage:buttonImage forState:UIControlStateNormal];
        [self addSubview:button];

        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        spinner.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
        spinner.center = self.center;
        spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self addSubview:spinner];
    }

    return self;
}

- (void)dealloc {
    [spinner release];
    [button release];
    [super dealloc];
}

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents {
    [button addTarget:target action:action forControlEvents:controlEvents];
}

- (void)startAnimating {
    button.hidden = YES;
    [spinner startAnimating];
}

- (void)stopAnimating {
    [spinner stopAnimating];
    button.hidden = NO;
}

@end
