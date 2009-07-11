//
//  RefreshButtonView.h
//  WordPress
//
//  Created by Josh Bassett on 9/07/09.
//

#import <UIKit/UIKit.h>

@interface RefreshButtonView : UIView {
    UIButton *button;
    UIActivityIndicatorView *spinner;
}

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;
- (void)startAnimating;
- (void)stopAnimating;

@end
