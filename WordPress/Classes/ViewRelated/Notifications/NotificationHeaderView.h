#import <UIKit/UIKit.h>



@interface NotificationHeaderView : UIView

@property (nonatomic, strong) NSString              *noticon;
@property (nonatomic, strong) NSAttributedString    *attributedText;

+ (instancetype)headerWithWidth:(CGFloat)width;

@end
