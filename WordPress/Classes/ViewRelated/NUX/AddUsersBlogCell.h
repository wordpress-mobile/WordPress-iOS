#import <UIKit/UIKit.h>

@interface AddUsersBlogCell : UITableViewCell

@property (nonatomic, assign) BOOL showTopSeparator;
@property (nonatomic, assign) BOOL isWPCom;

+ (CGFloat)rowHeightWithText:(NSString *)text;
- (void)setTitle:(NSString *)title;
- (void)setBlavatarUrl:(NSString *)url;
- (void)hideCheckmark:(BOOL)hide;

@end
