#import <UIKit/UIKit.h>
#import "WPContentViewProvider.h"

@interface WPContentActionView : UIView

@property (nonatomic, weak) id<WPContentViewProvider>contentProvider;

- (void)addActionButton:(UIButton *)actionButton;
- (void)removeAllActionButtons;

@end
