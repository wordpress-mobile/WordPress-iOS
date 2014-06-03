#import <UIKit/UIKit.h>

@class Blog;

typedef void(^JetpackSettingsCompletionBlock)(BOOL didAuthenticate);

@interface JetpackSettingsViewController : UIViewController
@property (nonatomic, assign) BOOL canBeSkipped;
// Navigation bar is hidden and all buttons are added into the
// view on initial sign in
@property (nonatomic, assign) BOOL showFullScreen;
@property (nonatomic, copy) JetpackSettingsCompletionBlock completionBlock;
- (void)setCompletionBlock:(JetpackSettingsCompletionBlock)completionBlock; // Just so Xcode autocompletes the block
- (id)initWithBlog:(Blog *)blog;
@end