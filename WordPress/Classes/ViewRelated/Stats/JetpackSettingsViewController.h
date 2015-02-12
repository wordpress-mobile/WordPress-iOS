#import <UIKit/UIKit.h>

@class Blog;

typedef void(^JetpackSettingsCompletionBlock)(BOOL didAuthenticate);

@interface JetpackSettingsViewController : UIViewController

// Navigation bar is hidden and all buttons are added into the view on initial sign in
@property (nonatomic, assign) BOOL                              showFullScreen;
@property (nonatomic, assign) BOOL                              canBeSkipped;
@property (nonatomic,   copy) JetpackSettingsCompletionBlock    completionBlock;

- (instancetype)initWithBlog:(Blog *)blog;

@end