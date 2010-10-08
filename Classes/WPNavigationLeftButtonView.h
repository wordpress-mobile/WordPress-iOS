//
//  WPNavigationLeftButtonView.h
//  WordPress
//
//  Created by Janakiram on 18/09/08.

#import <UIKit/UIKit.h>

@interface WPNavigationLeftButtonView : UIView {
    IBOutlet UIButton *addButton;
}

@property (nonatomic, assign) NSString *title;
@property (nonatomic, retain) IBOutlet UIButton *addButton;

+ (WPNavigationLeftButtonView *)createCopyOfView;
- (void)setTarget:(id)aTarget withAction:(SEL)action;
- (void)updateButton:(NSString *)text newStyle:(UIBarButtonItemStyle)style;

@end
