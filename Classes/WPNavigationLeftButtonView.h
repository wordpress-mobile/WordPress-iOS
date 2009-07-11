//
//  WPNavigationLeftButtonView.h
//  WordPress
//
//  Created by Janakiram on 18/09/08.

#import <UIKit/UIKit.h>

@interface WPNavigationLeftButtonView : UIView {
    UIButton *addButton;
}

@property (nonatomic, assign) NSString *title;

+ (WPNavigationLeftButtonView *)createCopyOfView;

- (void)setTarget:(id)aTarget withAction:(SEL)action;

@end
