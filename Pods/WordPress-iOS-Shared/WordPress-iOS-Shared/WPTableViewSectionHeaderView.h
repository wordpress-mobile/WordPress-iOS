#import <UIKit/UIKit.h>

@interface WPTableViewSectionHeaderView : UIView

@property (nonatomic, strong) NSString *title;

// By default, the title is flush left. Setting a fixed
// width places the title flush left within the specified width.
// Specified width must be greater than 0.
@property (nonatomic, assign) CGFloat fixedWidth;

+ (CGFloat)heightForTitle:(NSString *)title andWidth:(CGFloat)width;

@end
