#import <UIKit/UIKit.h>

@interface StatsBorderedCellBackgroundView : UIView

- (instancetype)initWithFrame:(CGRect)frame andSelected:(BOOL)selected;

@property (nonatomic, strong) UIView *contentBackgroundView;
@property (nonatomic, assign) BOOL bottomBorderEnabled;
@property (nonatomic, assign) BOOL topBorderDarkEnabled;

@end
