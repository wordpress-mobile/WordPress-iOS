#import <UIKit/UIKit.h>

@interface ContentActionButton : UIButton

@property (nonatomic) BOOL drawLabelBubble;

- (void)repositionTitleAndImage;
- (void)adjustImageSpacing;

@end
