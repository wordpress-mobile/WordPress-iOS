//
//  EditPostViewController_Internal.h
//  WordPress
//
//  Created by Jorge Bernal on 1/24/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "EditPostViewController.h"
#import "PostSettingsViewController.h"
#import "PostMediaViewController.h"
#import "PostPreviewViewController.h"
#import "AbstractPost.h"
#import "IOS7CorrectedTextView.h"
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

@interface EditPostViewController () <UIActionSheetDelegate, UITextFieldDelegate, UITextViewDelegate, WPKeyboardToolbarDelegate>

@property (nonatomic, strong) PostSettingsViewController *postSettingsViewController;
@property (nonatomic, strong) PostMediaViewController *postMediaViewController;
@property (nonatomic, strong) PostPreviewViewController *postPreviewViewController;
@property (nonatomic, assign) EditPostViewControllerMode editMode;
@property (nonatomic, strong) AbstractPost *post;
@property (readonly) BOOL hasChanges;
@property (nonatomic) BOOL isShowingKeyboard;
@property (nonatomic) BOOL isExternalKeyboard;

@property (nonatomic, strong) UIView *tableHeaderViewContentView;
@property (nonatomic, strong) UITextField *titleTextField;
@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) UIView *cellSeparatorView;
@property (nonatomic, strong) IOS7CorrectedTextView *textView;
@property (nonatomic, strong) WPKeyboardToolbarBase *editorToolbar;
@property (nonatomic, strong) WPKeyboardToolbarDone *titleToolbar;
@property (nonatomic, strong) UILabel *tapToStartWritingLabel;
@property (nonatomic, strong) UIActionSheet *currentActionSheet;
@property (nonatomic, strong) UIAlertView *failedMediaAlertView;

@property (nonatomic, strong) NSString *statsPrefix;

- (void)didSaveNewPost;

@end
