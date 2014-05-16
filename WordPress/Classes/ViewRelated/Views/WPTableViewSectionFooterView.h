#import <UIKit/UIKit.h>

@interface WPTableViewSectionFooterView : UITableViewHeaderFooterView

@property (nonatomic, strong) NSString *title;

+ (CGFloat)heightForTitle:(NSString *)title andWidth:(CGFloat)width;

@end
