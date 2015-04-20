#import "WPLegacyEditPostViewController.h"
#import "PostSettingsViewController.h"
#import "PostPreviewViewController.h"
#import "AbstractPost.h"

typedef NS_ENUM(NSInteger, EditPostViewControllerAlertTag) {
    EditPostViewControllerAlertTagNone,
    EditPostViewControllerAlertTagLinkHelper,
    EditPostViewControllerAlertTagFailedMedia,
    EditPostViewControllerAlertTagSwitchBlogs,
    EditPostViewControllerAlertCancelMediaUpload,
};

typedef NS_ENUM(NSUInteger, EditPostViewControllerMode) {
    EditPostViewControllerModeNewPost,
    EditPostViewControllerModeEditPost
};

@interface WPLegacyEditPostViewController () <UIActionSheetDelegate, UITextFieldDelegate, UITextViewDelegate, UIViewControllerRestoration>

@property (nonatomic, strong) PostSettingsViewController *postSettingsViewController;
@property (nonatomic, assign) EditPostViewControllerMode editMode;
@property (nonatomic, strong) AbstractPost *post;
@property (readonly) BOOL hasChanges;

@property (nonatomic, strong) UIActionSheet *currentActionSheet;
@property (nonatomic, strong) UIAlertView *failedMediaAlertView;

- (void)didSaveNewPost;

@end
