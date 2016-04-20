#import "WPLegacyEditPostViewController.h"
#import "PostSettingsViewController.h"
#import "PostPreviewViewController.h"
#import "AbstractPost.h"

typedef NS_ENUM(NSUInteger, EditPostViewControllerMode) {
    EditPostViewControllerModeNewPost,
    EditPostViewControllerModeEditPost
};

@interface WPLegacyEditPostViewController () <UITextFieldDelegate, UITextViewDelegate, UIViewControllerRestoration>

@property (nonatomic, strong) PostSettingsViewController *postSettingsViewController;
@property (nonatomic, assign) EditPostViewControllerMode editMode;
@property (nonatomic, strong) AbstractPost *post;
@property (readonly) BOOL hasChanges;

- (void)didSaveNewPost;

@end
