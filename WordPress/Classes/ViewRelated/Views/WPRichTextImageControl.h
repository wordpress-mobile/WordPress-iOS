#import <UIKit/UIKit.h>

@interface WPRichTextImageControl : UIControl

@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, strong) NSURL *contentURL;
@property (nonatomic, strong) NSURL *linkURL;

@end
