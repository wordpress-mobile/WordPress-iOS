#import "WPPostViewController.h"
#import "PostSettingsViewController.h"
#import "MediaBrowserViewController.h"
#import "PostPreviewViewController.h"
#import "AbstractPost.h"

typedef NS_ENUM(NSInteger, EditPostViewControllerAlertTag) {
    EditPostViewControllerAlertTagNone,
    EditPostViewControllerAlertTagLinkHelper,
    EditPostViewControllerAlertTagFailedMedia,
    EditPostViewControllerAlertTagSwitchBlogs,
    EditPostViewControllerAlertCancelMediaUpload,
};

@interface WPPostViewController () <UIActionSheetDelegate, UITextFieldDelegate, UITextViewDelegate, UIViewControllerRestoration>

@property (nonatomic, strong) PostSettingsViewController *postSettingsViewController;
@property (nonatomic, strong) AbstractPost *post;
@property (readonly) BOOL hasChanges;

@property (nonatomic, strong) UIActionSheet *currentActionSheet;
@property (nonatomic, strong) UIAlertView *failedMediaAlertView;

- (void)didSaveNewPost;

@end
