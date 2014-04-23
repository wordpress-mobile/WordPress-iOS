#import "EditPostViewController.h"
#import "PostSettingsViewController.h"
#import "MediaBrowserViewController.h"
#import "PostPreviewViewController.h"
#import "AbstractPost.h"
#import "WPKeyboardToolbarBase.h"
#import "WPKeyboardToolbarDone.h"

typedef NS_ENUM(NSInteger, EditPostViewControllerAlertTag) {
    EditPostViewControllerAlertTagNone,
    EditPostViewControllerAlertTagLinkHelper,
    EditPostViewControllerAlertTagFailedMedia,
    EditPostViewControllerAlertTagSwitchBlogs
};

typedef NS_ENUM(NSUInteger, EditPostViewControllerMode) {
	EditPostViewControllerModeNewPost,
	EditPostViewControllerModeEditPost
};

@interface EditPostViewController () <UIActionSheetDelegate, UITextFieldDelegate, UITextViewDelegate, WPKeyboardToolbarDelegate, UIViewControllerRestoration>

@property (nonatomic, strong) PostSettingsViewController *postSettingsViewController;
@property (nonatomic, assign) EditPostViewControllerMode editMode;
@property (nonatomic, strong) AbstractPost *post;
@property (readonly) BOOL hasChanges;
@property (nonatomic) BOOL isShowingKeyboard;
@property (nonatomic) BOOL isExternalKeyboard;

@property (nonatomic, strong) UITextField *titleTextField;
@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) UIView *optionsSeparatorView;
@property (nonatomic, strong) UIView *optionsView;
@property (nonatomic, strong) UIButton *optionsButton;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) WPKeyboardToolbarBase *editorToolbar;
@property (nonatomic, strong) WPKeyboardToolbarDone *titleToolbar;
@property (nonatomic, strong) UILabel *tapToStartWritingLabel;
@property (nonatomic, strong) UIActionSheet *currentActionSheet;
@property (nonatomic, strong) UIAlertView *failedMediaAlertView;

- (void)didSaveNewPost;

@end
