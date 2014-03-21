//
//  EditPostViewController.m
//  WordPress
//
//  Created by ? on ?.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "EditPostViewController.h"
#import "EditPostViewController_Internal.h"
#import "ContextManager.h"
#import "NSString+XMLExtensions.h"
#import "Post.h"
#import "Page.h"
#import "WPTableViewCell.h"
#import "BlogSelectorViewController.h"
#import "WPBlogSelectorButton.h"
#import "UIImage+Util.h"
#import "LocationService.h"

NSString *const WPEditorNavigationRestorationID = @"WPEditorNavigationRestorationID";
NSString *const WPAbstractPostRestorationKey = @"WPAbstractPostRestorationKey";
NSString *const EditPostViewControllerLastUsedBlogURL = @"EditPostViewControllerLastUsedBlogURL";
CGFloat const EPVCTextfieldHeight = 44.0f;
CGFloat const EPVCToolbarHeight = 44.0f;
CGFloat const EPVCNavbarHeight = 44.0f;
CGFloat const EPVCStandardOffset = 15.0;
CGFloat const EPVCTextViewOffset = 10.0;
CGFloat const EPVCTextViewBottomPadding = 50.0f;
CGFloat const EPVCTextViewTopPadding = 7.0f;

@interface EditPostViewController ()<UIPopoverControllerDelegate>

@property (nonatomic, strong) UIButton *titleBarButton;
@property (nonatomic, strong) WPAlertView *linkHelperAlertView;
@property (nonatomic, strong) UIPopoverController *blogSelectorPopover;
@property (nonatomic) BOOL dismissingBlogPicker;
@property (nonatomic) EditPostUserEvent currentUserEvent;

@end

@implementation EditPostViewController

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    
    if ([[identifierComponents lastObject] isEqualToString:WPEditorNavigationRestorationID]) {
        UINavigationController *navController = [[UINavigationController alloc] init];
        navController.restorationIdentifier = WPEditorNavigationRestorationID;
        return navController;
    }
    
    NSString *postID = [coder decodeObjectForKey:WPAbstractPostRestorationKey];
    if (!postID) {
        return nil;
    }
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:postID]];
    if (!objectID) {
        return nil;
    }
    
    NSError *error = nil;
    AbstractPost *restoredPost = (AbstractPost *)[context existingObjectWithID:objectID error:&error];
    if (error || !restoredPost) {
        return nil;
    }
    
    return [[self alloc] initWithPost:restoredPost];
}

+ (Blog *)blogForNewDraft {
    // Try to get the last used blog, if there is one.
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Blog"];
    NSString *url = [[NSUserDefaults standardUserDefaults] stringForKey:EditPostViewControllerLastUsedBlogURL];
    NSPredicate *predicate;
    if (url) {
        predicate = [NSPredicate predicateWithFormat:@"visible = YES AND url = %@", url];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"visible = YES"];
    }
    [fetchRequest setPredicate:predicate];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"blogName" ascending:YES]];
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        DDLogError(@"Couldn't fetch blogs: %@", error);
        return nil;
    }
    
    if([results count] == 0) {
        if (url) {
            // Blog might have been removed from the app. Get the first available.
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:EditPostViewControllerLastUsedBlogURL];
            [[NSUserDefaults standardUserDefaults] synchronize];
            return [self blogForNewDraft];
        }
        return nil;
    }
    
    return [results firstObject];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [coder encodeObject:[[self.post.objectID URIRepresentation] absoluteString] forKey:WPAbstractPostRestorationKey];
    [super encodeRestorableStateWithCoder:coder];
}


- (void)dealloc {
    _failedMediaAlertView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithTitle:(NSString *)title andContent:(NSString *)content andTags:(NSString *)tags andImage:(NSString *)image {
    self = [self initWithDraftForLastUsedBlog];
    if (self) {
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
        Post *post = (Post *)self.post;
        post.postTitle = title;
        post.content = content;
        post.tags = tags;
        
        if (image) {
            NSURL *imageURL = [NSURL URLWithString:image];
            if (imageURL) {
                NSString *aimg = [NSString stringWithFormat:@"<a href=\"%@\"><img src=\"%@\"></a>", [imageURL absoluteString], [imageURL absoluteString]];
                content = [NSString stringWithFormat:@"%@\n%@", aimg, content];
                post.content = content;
            } else {
                // Assume image as base64 encoded string.
                // TODO: Wrangle a base64 encoded image.
            }
        }
    }
    return self;
}

- (id)initWithDraftForLastUsedBlog {
    Blog *blog = [EditPostViewController blogForNewDraft];
    return [self initWithPost:[Post newDraftForBlog:blog]];
}

- (id)initWithPost:(AbstractPost *)post {
    self = [super init];
    if (self) {
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
        _post = post;
        [[NSUserDefaults standardUserDefaults] setObject:post.blog.url forKey:EditPostViewControllerLastUsedBlogURL];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if (_post.remoteStatus == AbstractPostRemoteStatusLocal) {
            _editMode = EditPostViewControllerModeNewPost;
        } else {
            _editMode = EditPostViewControllerModeEditPost;
        }
    }
    return self;
}

- (void)viewDidLoad {
    DDLogMethod();
    [super viewDidLoad];
    
    // For the iPhone, let's let the overscroll background color be white to
    // match the editor.
    if (IS_IPAD) {
        self.view.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    }
    
    [self setupNavbar];
    [self setupToolbar];
    [self setupTextView];
    
    [self createRevisionOfPost];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(insertMediaAbove:) name:@"ShouldInsertMediaAbove" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(insertMediaBelow:) name:@"ShouldInsertMediaBelow" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeMedia:) name:@"ShouldRemoveMedia" object:nil];
    
    if (self.editorOpenedBy) {
        [WPMobileStats trackEventForWPCom:[self formattedStatEventString:StatsEventPostDetailOpenedEditor] properties:@{StatsPropertyPostDetailEditorOpenedBy : self.editorOpenedBy }];
    } else {
        [WPMobileStats trackEventForWPCom:[self formattedStatEventString:StatsEventPostDetailOpenedEditor]];
    }
    
    [self geotagNewPost];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // When restoring state, the navigationController is nil when the view loads,
    // so configure its appearance here instead.
    self.navigationController.navigationBar.translucent = NO;
    UIToolbar *toolbar = self.navigationController.toolbar;
    toolbar.barTintColor = [WPStyleGuide littleEddieGrey];
    toolbar.translucent = NO;
    toolbar.barStyle = UIBarStyleDefault;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    if(self.navigationController.navigationBarHidden) {
        [self.navigationController setNavigationBarHidden:NO animated:animated];
    }
    
    if (self.navigationController.toolbarHidden) {
        [self.navigationController setToolbarHidden:NO animated:animated];
    }
    
    for (UIView *view in self.navigationController.toolbar.subviews) {
        [view setExclusiveTouch:YES];
    }
    
    [_textView setContentOffset:CGPointMake(0, 0)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Refresh the UI when the view appears or the options button won't be
    // visible when restoring state.
    [self refreshUIForCurrentPost];
}

- (void)viewWillDisappear:(BOOL)animated {
    DDLogMethod();
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    [self.navigationController setToolbarHidden:YES animated:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
	[_titleTextField resignFirstResponder];
	[_textView resignFirstResponder];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void)didReceiveMemoryWarning {
    DDLogInfo(@"");
    [super didReceiveMemoryWarning];
}

#pragma mark - View Setup

- (void)setupNavbar {
    if (self.navigationItem.leftBarButtonItem == nil) {
        UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Finish", @"Default main action button for closing/completing the post editing screen")
                                                                       style:[WPStyleGuide barButtonStyleForDone]
                                                                      target:self
                                                                      action:@selector(finishEditing)];
        self.navigationItem.leftBarButtonItem = saveButton;
        
        UIImage *image = [UIImage imageNamed:@"icon-posts-options"];
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
        [button setImage:image forState:UIControlStateNormal];
        [button addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
        button.accessibilityLabel = NSLocalizedString(@"Options", @"The accessibility value of the post options button.");
        button.accessibilityIdentifier = @"postOptions";
        UIBarButtonItem *postOptionsButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
        [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:postOptionsButtonItem forNavigationItem:self.navigationItem];
    }

    self.navigationItem.backBarButtonItem.title = [self editorTitle];
    self.title = [self editorTitle];
    
    // Configure the custom title view, or just set the navigationItem title.
    // Only show the blog selector in the nav title view if we're editing a new post
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSInteger blogCount = [Blog countWithContext:context];
    
    if (blogCount <= 1 || self.editMode == EditPostViewControllerModeEditPost) {
        self.navigationItem.title = [self editorTitle];
    } else {
        UIButton *titleButton = self.titleBarButton;
        NSMutableAttributedString *titleText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", [self editorTitle]]
                                                                                      attributes:@{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans-Bold" size:14.0] }];

        NSString *subtext = [self.post.blog.blogName length] == 0 ? self.post.blog.url : self.post.blog.blogName;
        NSDictionary *subtextAttributes = @{ NSFontAttributeName: [UIFont fontWithName:@"OpenSans" size:10.0] };
        NSMutableAttributedString *titleSubtext = [[NSMutableAttributedString alloc] initWithString:subtext
                                                                                         attributes:subtextAttributes];
        [titleText appendAttributedString:titleSubtext];
        [titleButton setAttributedTitle:titleText forState:UIControlStateNormal];

        [titleButton sizeToFit];
    }
}

- (void)setupToolbar {
    if ([self.toolbarItems count] > 0) {
        return;
    }
    
    UIBarButtonItem *previewButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-posts-editor-preview"] style:UIBarButtonItemStylePlain target:self action:@selector(showPreview)];
    UIBarButtonItem *photoButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-posts-editor-media"] style:UIBarButtonItemStylePlain target:self action:@selector(showMediaOptions)];
    
    previewButton.tintColor = [WPStyleGuide readGrey];
    photoButton.tintColor = [WPStyleGuide readGrey];

    previewButton.accessibilityLabel = NSLocalizedString(@"Preview post", nil);
    photoButton.accessibilityLabel = NSLocalizedString(@"Add media", nil);
    
    UIBarButtonItem *leftFixedSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *rightFixedSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *centerFlexSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    leftFixedSpacer.width = -2.0f;
    rightFixedSpacer.width = -5.0f;
    
    self.toolbarItems = @[leftFixedSpacer, previewButton, centerFlexSpacer, photoButton, rightFixedSpacer];
}

- (void)setupTextView {
    CGFloat x = 0.0f;
    CGFloat viewWidth = CGRectGetWidth(self.view.frame);
    CGFloat width = viewWidth;
    UIViewAutoresizing mask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if (IS_IPAD) {
        width = WPTableViewFixedWidth;
        x = ceilf((viewWidth - width) / 2.0f);
        mask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    }
    CGRect frame = CGRectMake(x, 0.0f, width, CGRectGetHeight(self.view.frame));
    
    // Content text field.
    // Shows the post body.
    // Height should never be smaller than what is required to display its text.
    if (!self.textView) {
        self.textView = [[IOS7CorrectedTextView alloc] initWithFrame:frame];
        self.textView.autoresizingMask = mask;
        self.textView.delegate = self;
        self.textView.typingAttributes = [WPStyleGuide regularTextAttributes];
        self.textView.font = [WPStyleGuide regularTextFont];
        self.textView.textColor = [WPStyleGuide darkAsNightGrey];
        self.textView.accessibilityLabel = NSLocalizedString(@"Content", @"Post content");
    }
    [self.view addSubview:self.textView];
    
    // Formatting bar for the textView's inputAccessoryView.
    if (self.editorToolbar == nil) {
        frame = CGRectMake(0.0f, 0.0f, viewWidth, WPKT_HEIGHT_PORTRAIT);
        self.editorToolbar = [[WPKeyboardToolbarBase alloc] initWithFrame:frame];
        self.editorToolbar.backgroundColor = [WPStyleGuide keyboardColor];
        self.editorToolbar.delegate = self;
        self.textView.inputAccessoryView = self.editorToolbar;
    }
    
    // Title TextField.
    if (!self.titleTextField) {
        CGFloat textWidth = CGRectGetWidth(self.textView.frame) - (2 * EPVCStandardOffset);
        frame = CGRectMake(EPVCStandardOffset, 0.0, textWidth, EPVCTextfieldHeight);
        self.titleTextField = [[UITextField alloc] initWithFrame:frame];
        self.titleTextField.delegate = self;
        self.titleTextField.font = [WPStyleGuide postTitleFont];
        self.titleTextField.textColor = [WPStyleGuide darkAsNightGrey];
        self.titleTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.titleTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:(NSLocalizedString(@"Enter title here", @"Label for the title of the post field. Should be the same as WP core.")) attributes:(@{NSForegroundColorAttributeName: [WPStyleGuide textFieldPlaceholderGrey]})];
        self.titleTextField.accessibilityLabel = NSLocalizedString(@"Title", @"Post title");
        self.titleTextField.returnKeyType = UIReturnKeyNext;
    }
    [self.textView addSubview:self.titleTextField];
    
    // InputAccessoryView for title textField.
    if (!self.titleToolbar) {
        frame = CGRectMake(0.0f, 0.0f, viewWidth, WPKT_HEIGHT_PORTRAIT);
        self.titleToolbar = [[WPKeyboardToolbarDone alloc] initWithFrame:frame];
        self.titleToolbar.backgroundColor = [WPStyleGuide keyboardColor];
        self.titleToolbar.delegate = self;
        self.titleTextField.inputAccessoryView = self.titleToolbar;
    }
    
    // One pixel separator bewteen title and content text fields.
    if (!self.separatorView) {
        CGFloat y = CGRectGetMaxY(self.titleTextField.frame);
        CGFloat separatorWidth = width - EPVCStandardOffset;
        frame = CGRectMake(EPVCStandardOffset, y, separatorWidth, 1.0);
        self.separatorView = [[UIView alloc] initWithFrame:frame];
        self.separatorView.backgroundColor = [WPStyleGuide readGrey];
        self.separatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    [self.textView addSubview:self.separatorView];
    
    // Update the textView's textContainerInsets so text does not overlap content.
    CGFloat left = EPVCTextViewOffset;
    CGFloat right = EPVCTextViewOffset;
    CGFloat top = CGRectGetMaxY(self.separatorView.frame) + EPVCTextViewTopPadding;
    CGFloat bottom = EPVCTextViewBottomPadding;
    self.textView.textContainerInset = UIEdgeInsetsMake(top, left, bottom, right);

    if (!self.tapToStartWritingLabel) {
        frame = CGRectZero;
        frame.origin.x = EPVCStandardOffset;
        frame.origin.y = self.textView.textContainerInset.top;
        frame.size.width = width - (EPVCStandardOffset * 2);
        frame.size.height = 26.0f;
        self.tapToStartWritingLabel = [[UILabel alloc] initWithFrame:frame];
        self.tapToStartWritingLabel.text = NSLocalizedString(@"Tap here to begin writing", @"Placeholder for the main body text. Should hint at tapping to enter text (not specifying body text).");
        self.tapToStartWritingLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.tapToStartWritingLabel.font = [WPStyleGuide regularTextFont];
        self.tapToStartWritingLabel.textColor = [WPStyleGuide textFieldPlaceholderGrey];
        self.tapToStartWritingLabel.isAccessibilityElement = NO;
    }
    [self.textView addSubview:self.tapToStartWritingLabel];

}

- (void)positionTextView:(NSNotification *)notification {
    
    NSDictionary *keyboardInfo = [notification userInfo];
    CGRect originalKeyboardFrame = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardFrame = [self.view convertRect:[self.view.window convertRect:originalKeyboardFrame fromWindow:nil] fromView:nil];
    
    CGRect frame = self.textView.frame;
    
    if (self.isShowingKeyboard) {
        frame.size.height = CGRectGetMinY(keyboardFrame) - CGRectGetMinY(frame);
    } else {
        frame.size.height = CGRectGetHeight(self.view.frame);
    }

    self.textView.frame = frame;
}

#pragma mark - Actions

- (void)showBlogSelectorPrompt {
    if (![self.post hasSiteSpecificChanges]) {
        [self showBlogSelector];
        return;
    }
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Change Site", @"Title of an alert prompting the user that they are about to change the blog they are posting to.")
                                                        message:NSLocalizedString(@"Choosing a different site will lose edits to site specific content like media and categories. Are you sure?", @"And alert message warning the user they will loose blog specific edits like categories, and media if they change the blog being posted to.")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel",@"")
                                              otherButtonTitles:NSLocalizedString(@"OK",@""), nil];
    alertView.tag = EditPostViewControllerAlertTagSwitchBlogs;
    [alertView show];
}

- (void)showBlogSelector {
    [WPMobileStats incrementProperty:StatsPropertyPostDetailClickedBlogSelector forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];

    if (IS_IPAD && self.blogSelectorPopover.isPopoverVisible) {
        [self.blogSelectorPopover dismissPopoverAnimated:YES];
        self.blogSelectorPopover = nil;
    }
    
    void (^dismissHandler)() = ^(void) {
        if (IS_IPAD) {
            [self.blogSelectorPopover dismissPopoverAnimated:YES];
        } else {
            self.dismissingBlogPicker = YES;
            [self dismissViewControllerAnimated:YES completion:nil];
            self.dismissingBlogPicker = NO;
        }
    };
    void (^selectedCompletion)(NSManagedObjectID *) = ^(NSManagedObjectID *selectedObjectID) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        Blog *blog = (Blog *)[context objectWithID:selectedObjectID];
        
        if (blog) {
            AbstractPost *newPost = [[self.post class] newDraftForBlog:blog];
            AbstractPost *oldPost = self.post;
            
            NSString *content = oldPost.content;
            if ([oldPost.media count] > 0) {
                for (Media *media in oldPost.media) {
                    content = [self removeMedia:media fromString:content];
                }
            }
            newPost.content = content;
            newPost.postTitle = oldPost.postTitle;
            newPost.password = oldPost.password;
            newPost.status = oldPost.status;
            newPost.dateCreated = oldPost.dateCreated;
            
            if ([newPost isKindOfClass:[Post class]]) {
                ((Post *)newPost).tags = ((Post *)oldPost).tags;
            }

            self.post = newPost;
            [self createRevisionOfPost];
            
            [oldPost.original deleteRevision];
            [oldPost.original remove];

            [[NSUserDefaults standardUserDefaults] setObject:blog.url forKey:EditPostViewControllerLastUsedBlogURL];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self syncOptionsIfNecessaryForBlog:blog afterBlogChanged:YES];
        }
        
        [self refreshUIForCurrentPost];
        dismissHandler();
    };
    
    BlogSelectorViewController *vc = [[BlogSelectorViewController alloc] initWithSelectedBlogObjectID:self.post.blog.objectID
                                                                                   selectedCompletion:selectedCompletion
                                                                                     cancelCompletion:dismissHandler];
    vc.title = NSLocalizedString(@"Select Site", @"");

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    navController.navigationBar.translucent = NO;
    navController.navigationBar.barStyle = UIBarStyleBlack;
    
    if (IS_IPAD) {
        vc.preferredContentSize = CGSizeMake(320.0, 500);
        
        CGRect titleRect = self.navigationItem.titleView.frame;
        titleRect = [self.navigationController.view convertRect:titleRect fromView:self.navigationItem.titleView.superview];

        self.blogSelectorPopover = [[UIPopoverController alloc] initWithContentViewController:navController];
        self.blogSelectorPopover.backgroundColor = [WPStyleGuide newKidOnTheBlockBlue];
        self.blogSelectorPopover.delegate = self;
        [self.blogSelectorPopover presentPopoverFromRect:titleRect inView:self.navigationController.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];

    } else {
        navController.modalPresentationStyle = UIModalPresentationPageSheet;
        navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
        [self presentViewController:navController animated:YES completion:nil];
    }
}

- (Class)classForSettingsViewController {
    return [PostSettingsViewController class];
}

- (void)showSettings {
    [WPMobileStats flagProperty:StatsPropertyPostDetailClickedSettings forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
    Post *post = (Post *)self.post;
    PostSettingsViewController *vc = [[[self classForSettingsViewController] alloc] initWithPost:post];
    vc.statsPrefix = self.statsPrefix;
    self.navigationItem.title = NSLocalizedString(@"Back", nil);
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showPreview {
    [WPMobileStats flagProperty:StatsPropertyPostDetailClickedPreview forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
    PostPreviewViewController *vc = [[PostPreviewViewController alloc] initWithPost:self.post];
    self.navigationItem.title = NSLocalizedString(@"Back", nil);
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showMediaOptions {
    [WPMobileStats flagProperty:StatsPropertyPostDetailClickedMediaOptions forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
    PostMediaViewController *vc = [[PostMediaViewController alloc] initWithPost:self.post];
    self.navigationItem.title = NSLocalizedString(@"Back", nil);
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)finishEditing {
    if(_currentActionSheet) return;
    
    [_textView resignFirstResponder];
    [_titleTextField resignFirstResponder];
	[self.postSettingsViewController endEditingAction:nil];
    
	if ([self isMediaInUploading]) {
		[self showMediaInUploadingAlert];
		return;
	}

    if (![self hasChanges] && [self.post.status isEqualToString:@"publish"]) {
        //No changes + publishedso just dismiss this view
        [WPMobileStats trackEventForWPComWithSavedProperties:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
        [self discardChangesAndDismiss];
        return;
    }
    
	UIActionSheet *actionSheet;
    NSString *keepEditingText = NSLocalizedString(@"Keep Editing", @"Button shown if there are unsaved changes and the author decides to keep editing the post.");
    NSString *publishText;
    if ([self isScheduled]) {
        publishText = NSLocalizedString(@"Schedule", @"Schedule button, this is what the Publish button changes to in the Post Editor if the post has been scheduled for posting later.");
    } else {
        publishText = NSLocalizedString(@"Publish", @"Button shown when the author wants to publish a draft post.");
    }
    
    if ([self hasChanges]) {
        NSString *unsavedChangesTitle = NSLocalizedString(@"You have unsaved changes",
                                                          @"Title of message with options that shown when there are unsaved changes and the author is trying to move away from the post.");
        
        if ( [self.post.original.status isEqualToString:@"publish"] && self.editMode != EditPostViewControllerModeNewPost) {
            // The post is already published on the server or it was intended to be and failed
            NSString *discardText = NSLocalizedString(@"Discard Changes",
                                                      @"Button shown if there are unsaved changes and the author decides to not save his changes.");
            NSString *updatePublishedText = ([self isPage]) ? NSLocalizedString(@"Update Published Page", @"Button shown when the author wants to update a published page.")
                                                            : NSLocalizedString(@"Update Published Post", @"Button shown when the author wants to update a published post.");
            actionSheet = [[UIActionSheet alloc] initWithTitle:unsavedChangesTitle
                                                      delegate:self
                                             cancelButtonTitle:keepEditingText
                                        destructiveButtonTitle:discardText
                                             otherButtonTitles:updatePublishedText, nil];
        } else if (self.editMode == EditPostViewControllerModeNewPost) {
            // The post is a local draft or an autosaved draft
            NSString *saveDraftText = NSLocalizedString(@"Save Draft", @"Button shown when the author wants to save a draft post.");
            NSString *discardText = NSLocalizedString(@"Discard New Post",
                                                      @"Button shown if the author is creating a new post that has content and the author decides to not save it.");
            actionSheet = [[UIActionSheet alloc] initWithTitle:unsavedChangesTitle
                                                      delegate:self
                                             cancelButtonTitle:keepEditingText
                                        destructiveButtonTitle:discardText
                                             otherButtonTitles:saveDraftText, publishText, nil];
        } else {
            // The post was already a draft or private or pending
            NSString *updateDraftText = NSLocalizedString(@"Update Draft", @"Button shown when the author wants to update an existing a draft post.");
            NSString *discardText = NSLocalizedString(@"Discard Changes",
                                                      @"Button shown if there are unsaved changes and the author decides to not save his changes.");
            actionSheet = [[UIActionSheet alloc] initWithTitle:unsavedChangesTitle
                                                      delegate:self
                                             cancelButtonTitle:keepEditingText
                                        destructiveButtonTitle:discardText
                                             otherButtonTitles:updateDraftText, publishText, nil];
        }
        
    } else {
        //No changes, but not published so prompt user for action
        NSString *chooseTitle = NSLocalizedString(@"Please choose one of the following",
                                                  @"Title of message with options shown when the author is trying to move away from the post.");
        NSString *goBackText = ([self isPage]) ? NSLocalizedString(@"Go Back to Pages", @"Button shown if there are unsaved changes and the author is trying to move away from the page.")
                                               : NSLocalizedString(@"Go Back to Posts", @"Button shown if there are unsaved changes and the author is trying to move away from the post.");
        
        actionSheet = [[UIActionSheet alloc] initWithTitle:chooseTitle
                                                  delegate:self
                                         cancelButtonTitle:keepEditingText
                                    destructiveButtonTitle:goBackText
                                         otherButtonTitles:publishText, nil];
    }
    
    actionSheet.tag = 201;
    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    if (IS_IPAD) {
        [actionSheet showFromBarButtonItem:self.navigationItem.leftBarButtonItem animated:YES];
    } else {
        [actionSheet showFromToolbar:self.navigationController.toolbar];
    }
}

#pragma mark - Instance Methods

- (void)geotagNewPost {
    if (EditPostViewControllerModeNewPost != self.editMode) {
        return;
    }
    
    if (self.post.blog.geolocationEnabled && ![LocationService sharedService].locationServicesDisabled) {
        [[LocationService sharedService] getCurrentLocationAndAddress:^(CLLocation *location, NSString *address, NSError *error) {
            if (location) {
                if(self.post.isDeleted) {
                    return;
                }
                Coordinate *coord = [[Coordinate alloc] initWithCoordinate:location.coordinate];
                Post *post = (Post *)self.post;
                post.geolocation = coord;
            }
        }];
    }
}

- (void)setEditorOpenedBy:(NSString *)editorOpenedBy {
    if ([_editorOpenedBy isEqualToString:editorOpenedBy]) {
        return;
    }
    _editorOpenedBy = editorOpenedBy;
    [self syncOptionsIfNecessaryForBlog:_post.blog afterBlogChanged:NO];
}

/*
 Sync the blog if desired info is missing.
 
 Always sync after a blog switch to ensure options are updated. Otherwise, 
 only sync for new posts when launched from the post tab vs the posts list.
 */
- (void)syncOptionsIfNecessaryForBlog:(Blog *)blog afterBlogChanged:(BOOL)blogChanged {
    if (blogChanged || [self.editorOpenedBy isEqualToString:StatsPropertyPostDetailEditorOpenedOpenedByTabBarButton]) {
        [blog syncBlogWithSuccess:nil failure:nil];
    }
}

- (NSString *)editorTitle {
    NSString *title = @"";
    if (self.editMode == EditPostViewControllerModeNewPost) {
        title = NSLocalizedString(@"New Post", @"Post Editor screen title.");
    } else {
        if ([self.post.postTitle length]) {
            title = self.post.postTitle;
        } else {
            title = NSLocalizedString(@"Edit Post", @"Post Editor screen title.");
        }
    }
    return title;
}

- (NSString *)statsPrefix {
    if (_statsPrefix == nil) {
        return @"Post Detail";
    }
    return _statsPrefix;
}

- (NSString *)formattedStatEventString:(NSString *)event {
    return [NSString stringWithFormat:@"%@ - %@", self.statsPrefix, event];
}

- (BOOL)hasChanges {
    return [self.post hasChanged];
}

- (BOOL)isPage {
    return [self.post isKindOfClass:Page.class];
}

- (BOOL)isScheduled {
    return ([self.post.status isEqualToString:@"publish"] && ([self.post.dateCreated compare:[NSDate date]] == NSOrderedDescending));
}

#pragma mark - UI Manipulation

- (void)refreshUIForCurrentPost {
    [self setupNavbar];
    
    _titleTextField.text = self.post.postTitle;
    
    if(self.post.content == nil || [self.post.content isEmpty]) {
        _tapToStartWritingLabel.hidden = NO;
        _textView.text = @"";
    } else {
        _tapToStartWritingLabel.hidden = YES;
        if ((self.post.mt_text_more != nil) && ([self.post.mt_text_more length] > 0)) {
			_textView.text = [NSString stringWithFormat:@"%@\n<!--more-->\n%@", self.post.content, self.post.mt_text_more];
        } else {
			_textView.text = self.post.content;
        }
    }
}

- (UIButton *)titleBarButton {
    if (_titleBarButton) {
        return _titleBarButton;
    }
    UIButton *titleButton = [WPBlogSelectorButton buttonWithType:UIButtonTypeSystem];
    titleButton.frame = CGRectMake(0.0f, 0.0f, 200.0f, 33.0f);
    titleButton.titleLabel.numberOfLines = 2;
    titleButton.titleLabel.textColor = [UIColor whiteColor];
    titleButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    titleButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [titleButton setImage:[UIImage imageNamed:@"icon-navbar-dropdown.png"] forState:UIControlStateNormal];
    [titleButton addTarget:self action:@selector(showBlogSelectorPrompt) forControlEvents:UIControlEventTouchUpInside];
    [titleButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 10)];
    [titleButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
    [titleButton setAccessibilityHint:NSLocalizedString(@"Tap to select which blog to post to", nil)];

    _titleBarButton = titleButton;
    self.navigationItem.titleView = titleButton;
    
    return _titleBarButton;
}

# pragma mark - Model State Methods

- (void)createRevisionOfPost {
    // Using performBlock: with the AbstractPost on the main context:
    // Prevents a hang on opening this view on slow and fast devices
    // by deferring the cloning and UI update.
    // Slower devices have the effect of the content appearing after
    // a short delay
    [self.post.managedObjectContext performBlock:^{
        self.post = [self.post createRevision];
        [self.post save];
        [self refreshUIForCurrentPost];
    }];
}

- (void)discardChangesAndDismiss {
    [self.post.original deleteRevision];
    
    if (self.editMode == EditPostViewControllerModeNewPost) {
        [self.post.original remove];
    }
    
    [self dismissEditView];
}

- (void)dismissEditView {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)saveActionWithUserEvent:(EditPostUserEvent)userEvent {
    _currentUserEvent = userEvent;
    
    if (_currentActionSheet.isVisible) {
        [_currentActionSheet dismissWithClickedButtonIndex:-1 animated:YES];
        _currentActionSheet = nil;
    }
    
	if ([self isMediaInUploading] ) {
		[self showMediaInUploadingAlert];
		return;
	}
    
    if ([self hasFailedMedia]) {
        [self showFailedMediaAlert];
        return;
    }
    
	[self savePost:YES];
}

- (void)savePost:(BOOL)upload {
    DDLogMethod();
    [self logSavePostStats];

    [WPMobileStats trackEventForWPComWithSavedProperties:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
    
    [self.view endEditing:YES];
    
    [self.post.original applyRevision];
    [self.post.original deleteRevision];
    
    if (upload) {
        NSString *postTitle = self.post.original.postTitle;
        [self.post.original uploadWithSuccess:^{
            DDLogInfo(@"post uploaded: %@", postTitle);
        } failure:^(NSError *error) {
            DDLogError(@"post failed: %@", [error localizedDescription]);
        }];
    }
    
    [self didSaveNewPost];

    [self dismissEditView];
}

- (void)didSaveNewPost {
    if (_editMode == EditPostViewControllerModeNewPost) {
        [[WordPressAppDelegate sharedWordPressApplicationDelegate] switchTabToPostsListForPost:self.post];
    }
}

- (void)logSavePostStats {
    NSString *event;
    switch (_currentUserEvent) {
        case EditPostUserActionSchedule:
            event = StatsEventPostDetailClickedSchedule;
            break;
        case EditPostUserActionPublish:
            event = StatsEventPostDetailClickedPublish;
            break;
        case EditPostUserActionSave:
            event = StatsEventPostDetailClickedSave;
            break;
        case EditPostUserActionUpdate:
            event = StatsEventPostDetailClickedUpdate;
            break;
        default:
            break;
    }
    
    if (event != nil) {
        [WPMobileStats trackEventForWPCom:[self formattedStatEventString:event]];
        //Reset the current user event
        _currentUserEvent = EditPostUserActionNone;
    }

    // This word counting algorithm is from : http://stackoverflow.com/a/13367063
    __block NSInteger originalWordCount = 0;
    [self.post.original.content enumerateSubstringsInRange:NSMakeRange(0, [self.post.original.content length])
                               options:NSStringEnumerationByWords | NSStringEnumerationLocalized
                            usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop){
                                originalWordCount++;
                            }];
    
    __block NSInteger wordCount = 0;
    [self.post.content enumerateSubstringsInRange:NSMakeRange(0, [self.post.content length])
                               options:NSStringEnumerationByWords | NSStringEnumerationLocalized
                            usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop){
                                wordCount++;
                            }];

    [WPMobileStats setValue:@(wordCount) forProperty:StatsPropertyPostDetailWordCount forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
    if ([self.post hasRemote]) {
        [WPMobileStats setValue:@(wordCount - originalWordCount) forProperty:StatsPropertyPostDetailWordDiffCount forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
    }
}

// Save changes to core data
- (void)autosaveContent {
    self.post.postTitle = _titleTextField.text;
    self.navigationItem.title = [self editorTitle];
    
    self.post.content = _textView.text;
	if ([self.post.content rangeOfString:@"<!--more-->"].location != NSNotFound)
		self.post.mt_text_more = @"";
    
    if ( self.post.original.password != nil ) { //original post was password protected
        if ( self.post.password == nil || [self.post.password isEqualToString:@""] ) { //removed the password
            self.post.password = @"";
        }
    }
    
    [self.post save];
    [_textView scrollRangeToVisible:[_textView selectedRange]];
}

#pragma mark - Media State Methods

- (BOOL)hasFailedMedia {
	BOOL hasFailedMedia = NO;
    
	NSSet *mediaFiles = self.post.media;
	for (Media *media in mediaFiles) {
		if(media.remoteStatus == MediaRemoteStatusFailed) {
			hasFailedMedia = YES;
			break;
		}
	}
	mediaFiles = nil;
    
	return hasFailedMedia;
}

//check if there are media in uploading status
- (BOOL)isMediaInUploading {
	BOOL isMediaInUploading = NO;
	
	NSSet *mediaFiles = self.post.media;
	for (Media *media in mediaFiles) {
		if(media.remoteStatus == MediaRemoteStatusPushing) {
			isMediaInUploading = YES;
			break;
		}
	}
	mediaFiles = nil;
    
	return isMediaInUploading;
}

- (void)showFailedMediaAlert {
    if (_failedMediaAlertView)
        return;
    _failedMediaAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Pending media", @"Title for alert when trying to publish a post with failed media items")
                                                       message:NSLocalizedString(@"There are media items in this post that aren't uploaded to the server. Do you want to continue?", @"")
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"No", @"")
                                             otherButtonTitles:NSLocalizedString(@"Post anyway", @""), nil];
    _failedMediaAlertView.tag = EditPostViewControllerAlertTagFailedMedia;
    [_failedMediaAlertView show];
}

- (void)showMediaInUploadingAlert {
	//the post is using the network connection and cannot be stoped, show a message to the user
	UIAlertView *blogIsCurrentlyBusy = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Info", @"Info alert title")
																  message:NSLocalizedString(@"A Media file is currently uploading. Please try later.", @"")
																 delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
	[blogIsCurrentlyBusy show];
}


#pragma mark - Editor and Formatting Methods
#pragma mark Link Methods

//code to append http:// if protocol part is not there as part of urlText.
- (NSString *)validateNewLinkInfo:(NSString *)urlText {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[\\w]+:" options:0 error:&error];
    
    if ([regex numberOfMatchesInString:urlText options:0 range:NSMakeRange(0, [urlText length])] > 0) {
        return urlText;
    } else if([urlText hasPrefix:@"#"]) {
        // link to named anchor
        return urlText;
    } else {
        return [NSString stringWithFormat:@"http://%@", urlText];
    }
}

- (void)showLinkView {
    if (_linkHelperAlertView) {
        [_linkHelperAlertView dismiss];
        _linkHelperAlertView = nil;
    }
    
    NSRange range = _textView.selectedRange;
    NSString *infoText = nil;
    
    if (range.length > 0)
        infoText = [_textView.text substringWithRange:range];
    
    CGRect frame = CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, self.view.bounds.size.height);
    if (IS_IPAD) {
        frame.origin.y = 22.0f; // Make sure the title of the alert view is visible on the iPad.
    }
    _linkHelperAlertView = [[WPAlertView alloc] initWithFrame:frame andOverlayMode:WPAlertViewOverlayModeTwoTextFieldsTwoButtonMode];
    
    NSString *title = NSLocalizedString(@"Make a Link\n\n\n\n", @"Title of the Link Helper popup to aid in creating a Link in the Post Editor.\n\n\n\n");
    NSCharacterSet *charSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    title = [title stringByTrimmingCharactersInSet:charSet];
    
    _linkHelperAlertView.overlayTitle = title;
    _linkHelperAlertView.overlayDescription = @"";
    _linkHelperAlertView.footerDescription = [NSLocalizedString(@"tap to dismiss", nil) uppercaseString];
    _linkHelperAlertView.firstTextFieldPlaceholder = NSLocalizedString(@"Text to be linked", @"Popup to aid in creating a Link in the Post Editor.");
    _linkHelperAlertView.firstTextFieldValue = infoText;
    _linkHelperAlertView.secondTextFieldPlaceholder = NSLocalizedString(@"Link URL", @"Popup to aid in creating a Link in the Post Editor, URL field (where you can type or paste a URL that the text should link.");
    _linkHelperAlertView.leftButtonText = NSLocalizedString(@"Cancel", @"Cancel button");
    _linkHelperAlertView.rightButtonText = NSLocalizedString(@"Insert", @"Insert content (link, media) button");
    
    _linkHelperAlertView.firstTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _linkHelperAlertView.secondTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _linkHelperAlertView.firstTextField.keyboardAppearance = UIKeyboardAppearanceAlert;
    _linkHelperAlertView.secondTextField.keyboardAppearance = UIKeyboardAppearanceAlert;
    _linkHelperAlertView.firstTextField.keyboardType = UIKeyboardTypeDefault;
    _linkHelperAlertView.secondTextField.keyboardType = UIKeyboardTypeURL;
    _linkHelperAlertView.secondTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) && IS_IPHONE && !_isExternalKeyboard) {
        [_linkHelperAlertView hideTitleAndDescription:YES];
    }
    
    __block UITextView *editorTextView = _textView;
    __block id fles = self;
    _linkHelperAlertView.button1CompletionBlock = ^(WPAlertView *overlayView){
        // Cancel
        [overlayView dismiss];
        
        [editorTextView becomeFirstResponder];
        
        [fles setLinkHelperAlertView:nil];
    };
    _linkHelperAlertView.button2CompletionBlock = ^(WPAlertView *overlayView){
        // Insert
        
        //Disable scrolling temporarily otherwise inserting text will scroll to the bottom in iOS6 and below.
        editorTextView.scrollEnabled = NO;
        [overlayView dismiss];
        
        [editorTextView becomeFirstResponder];
        
        UITextField *infoText = overlayView.firstTextField;
        UITextField *urlField = overlayView.secondTextField;
        
        if ((urlField.text == nil) || ([urlField.text isEqualToString:@""])) {
            return;
        }
        
        if ((infoText.text == nil) || ([infoText.text isEqualToString:@""]))
            infoText.text = urlField.text;
        
        NSString *urlString = [fles validateNewLinkInfo:[urlField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        NSString *aTagText = [NSString stringWithFormat:@"<a href=\"%@\">%@</a>", urlString, infoText.text];
        
        NSRange range = editorTextView.selectedRange;
        
        NSString *oldText = editorTextView.text;
        NSRange oldRange = editorTextView.selectedRange;
        editorTextView.text = [editorTextView.text stringByReplacingCharactersInRange:range withString:aTagText];
        
        //Re-enable scrolling after insertion is complete
        editorTextView.scrollEnabled = YES;
        
        //reset selection back to nothing
        range.length = 0;
        
        if (range.length == 0) {                // If nothing was selected
            range.location += [aTagText length]; // Place selection between tags
            editorTextView.selectedRange = range;
        }
        [[editorTextView.undoManager prepareWithInvocationTarget:fles] restoreText:oldText withRange:oldRange];
        [editorTextView.undoManager setActionName:@"link"];
        
        [fles autosaveContent];

        [fles setLinkHelperAlertView:nil];
        [fles refreshTextView];
    };
    
    _linkHelperAlertView.alpha = 0.0;
    [self.view.superview addSubview:_linkHelperAlertView];
    if ([infoText length] > 0) {
        [_linkHelperAlertView.secondTextField becomeFirstResponder];
    }
    [UIView animateWithDuration:0.2 animations:^{
        _linkHelperAlertView.alpha = 1.0;
    }];
}

#pragma mark Media Formatting

- (void)insertMediaAbove:(NSNotification *)notification {
    [WPMobileStats trackEventForWPCom:[self formattedStatEventString:StatsEventPostDetailAddedPhoto]];
    
	Media *media = (Media *)[notification object];
	NSString *prefix = @"<br /><br />";
	
	if(self.post.content == nil || [self.post.content isEqualToString:@""]) {
		self.post.content = @"";
		prefix = @"";
	}
	
	NSMutableString *content = [[NSMutableString alloc] initWithString:media.html];
	NSRange imgHTML = [_textView.text rangeOfString: content];
	
	NSRange imgHTMLPre = [_textView.text rangeOfString:[NSString stringWithFormat:@"%@%@", @"<br /><br />", content]];
 	NSRange imgHTMLPost = [_textView.text rangeOfString:[NSString stringWithFormat:@"%@%@", content, @"<br /><br />"]];
	
	if (imgHTMLPre.location == NSNotFound && imgHTMLPost.location == NSNotFound && imgHTML.location == NSNotFound) {
		[content appendString:[NSString stringWithFormat:@"%@%@", prefix, self.post.content]];
        self.post.content = content;
	}
	else {
		NSMutableString *processedText = [[NSMutableString alloc] initWithString:_textView.text];
		if (imgHTMLPre.location != NSNotFound)
			[processedText replaceCharactersInRange:imgHTMLPre withString:@""];
		else if (imgHTMLPost.location != NSNotFound)
			[processedText replaceCharactersInRange:imgHTMLPost withString:@""];
		else
			[processedText replaceCharactersInRange:imgHTML withString:@""];
        
		[content appendString:[NSString stringWithFormat:@"<br /><br />%@", processedText]];
		self.post.content = content;
	}
    [self refreshUIForCurrentPost];
    [self.post save];
}

- (void)insertMediaBelow:(NSNotification *)notification {
    [WPMobileStats trackEventForWPCom:[self formattedStatEventString:StatsEventPostDetailAddedPhoto]];
    
	Media *media = (Media *)[notification object];
	NSString *prefix = @"<br /><br />";
	
	if(self.post.content == nil || [self.post.content isEqualToString:@""]) {
		self.post.content = @"";
		prefix = @"";
	}
	
	NSMutableString *content = [[NSMutableString alloc] initWithString:self.post.content];
	NSRange imgHTML = [content rangeOfString: media.html];
	NSRange imgHTMLPre = [content rangeOfString:[NSString stringWithFormat:@"%@%@", @"<br /><br />", media.html]];
 	NSRange imgHTMLPost = [content rangeOfString:[NSString stringWithFormat:@"%@%@", media.html, @"<br /><br />"]];
	
	if (imgHTMLPre.location == NSNotFound && imgHTMLPost.location == NSNotFound && imgHTML.location == NSNotFound) {
		[content appendString:[NSString stringWithFormat:@"%@%@", prefix, media.html]];
        self.post.content = content;
	}
	else {
		if (imgHTMLPre.location != NSNotFound)
			[content replaceCharactersInRange:imgHTMLPre withString:@""];
		else if (imgHTMLPost.location != NSNotFound)
			[content replaceCharactersInRange:imgHTMLPost withString:@""];
		else
			[content replaceCharactersInRange:imgHTML withString:@""];
		[content appendString:[NSString stringWithFormat:@"<br /><br />%@", media.html]];
		self.post.content = content;
	}
    
    [self refreshUIForCurrentPost];
    [self.post save];
}

- (void)removeMedia:(NSNotification *)notification {
    [WPMobileStats trackEventForWPCom:[self formattedStatEventString:StatsEventPostDetailRemovedPhoto]];
    
	//remove the html string for the media object
	Media *media = (Media *)[notification object];
    _textView.text = [self removeMedia:media fromString:_textView.text];
    [self autosaveContent];
    [self refreshUIForCurrentPost];
}

- (NSString *)removeMedia:(Media *)media fromString:(NSString *)string {
	string = [string stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"<br /><br />%@", media.html] withString:@""];
	string = [string stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@<br /><br />", media.html] withString:@""];
	string = [string stringByReplacingOccurrencesOfString:media.html withString:@""];
    
    return string;
}


#pragma mark - Formatting

- (void)restoreText:(NSString *)text withRange:(NSRange)range {
    DDLogVerbose(@"restoreText:%@",text);
    NSString *oldText = _textView.text;
    NSRange oldRange = _textView.selectedRange;
    _textView.scrollEnabled = NO;
    // iOS6 seems to have a bug where setting the text like so : textView.text = text;
    // will cause an infinate loop of undos.  A work around is to perform the selector
    // on the main thread.
    // textView.text = text;
    [_textView performSelectorOnMainThread:@selector(setText:) withObject:text waitUntilDone:NO];
    _textView.scrollEnabled = YES;
    _textView.selectedRange = range;
    [[_textView.undoManager prepareWithInvocationTarget:self] restoreText:oldText withRange:oldRange];
    [self autosaveContent];
}

- (void)wrapSelectionWithTag:(NSString *)tag {
    NSRange range = _textView.selectedRange;
    NSString *selection = [_textView.text substringWithRange:range];
    NSString *prefix, *suffix;
    if ([tag isEqualToString:@"more"]) {
        prefix = @"<!--more-->";
        suffix = @"\n";
    } else if ([tag isEqualToString:@"blockquote"]) {
        prefix = [NSString stringWithFormat:@"\n<%@>", tag];
        suffix = [NSString stringWithFormat:@"</%@>\n", tag];
    } else {
        prefix = [NSString stringWithFormat:@"<%@>", tag];
        suffix = [NSString stringWithFormat:@"</%@>", tag];
    }
    _textView.scrollEnabled = NO;
    NSString *replacement = [NSString stringWithFormat:@"%@%@%@",prefix,selection,suffix];
    _textView.text = [_textView.text stringByReplacingCharactersInRange:range
                                                             withString:replacement];
    _textView.scrollEnabled = YES;
    if (range.length == 0) {                // If nothing was selected
        range.location += [prefix length]; // Place selection between tags
    } else {
        range.location += range.length + [prefix length] + [suffix length]; // Place selection after tag
        range.length = 0;
    }
    _textView.selectedRange = range;
    
    [self autosaveContent];
    [self refreshTextView];
}

// In some situations on iOS7, inserting text while `scrollEnabled = NO` results in
// the last line(s) of text on the text view not appearing. This is a workaround
// to get the UITextView to redraw after inserting text but without affecting the
// scrollOffset.
- (void)refreshTextView {
    dispatch_async(dispatch_get_main_queue(), ^{
        _textView.scrollEnabled = NO;
        [_textView setNeedsDisplay];
        _textView.scrollEnabled = YES;
    });
}

#pragma mark - WPKeyboardToolbar Delegate Methods

- (void)keyboardToolbarButtonItemPressed:(WPKeyboardToolbarButtonItem *)buttonItem {
    DDLogMethod();
    [self logWPKeyboardToolbarButtonStat:buttonItem];
    if ([buttonItem.actionTag isEqualToString:@"link"]) {
        [self showLinkView];
    } else if ([buttonItem.actionTag isEqualToString:@"done"]) {
        // With the titleTextField as a subview of textField, we need to resign and
        // end editing to prevent the textField from becomeing first responder.
        if ([self.titleTextField isFirstResponder]) {
            [self.titleTextField resignFirstResponder];
        }
        [self.view endEditing:YES];
    } else {
        NSString *oldText = _textView.text;
        NSRange oldRange = _textView.selectedRange;
        [self wrapSelectionWithTag:buttonItem.actionTag];
        [[_textView.undoManager prepareWithInvocationTarget:self] restoreText:oldText withRange:oldRange];
        [_textView.undoManager setActionName:buttonItem.actionName];
    }
}

- (void)logWPKeyboardToolbarButtonStat:(WPKeyboardToolbarButtonItem *)buttonItem {
    NSString *actionTag = buttonItem.actionTag;
    NSString *property;
    if ([actionTag isEqualToString:@"strong"]) {
        property = StatsEventPostDetailClickedKeyboardToolbarBoldButton;
    } else if ([actionTag isEqualToString:@"em"]) {
        property = StatsEventPostDetailClickedKeyboardToolbarItalicButton;
    } else if ([actionTag isEqualToString:@"u"]) {
        property = StatsEventPostDetailClickedKeyboardToolbarUnderlineButton;
    } else if ([actionTag isEqualToString:@"link"]) {
        property = StatsEventPostDetailClickedKeyboardToolbarLinkButton;
    } else if ([actionTag isEqualToString:@"blockquote"]) {
        property = StatsEventPostDetailClickedKeyboardToolbarBlockquoteButton;
    } else if ([actionTag isEqualToString:@"del"]) {
        property = StatsEventPostDetailClickedKeyboardToolbarDelButton;
    } else if ([actionTag isEqualToString:@"more"]) {
        property = StatsEventPostDetailClickedKeyboardToolbarMoreButton;
    }
    
    if (property != nil) {
        [WPMobileStats flagProperty:property forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
    }
}

#pragma mark - UIPopoverControllerDelegate methods

- (void)popoverController:(UIPopoverController *)popoverController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView **)view {
    if (popoverController == self.blogSelectorPopover) {
        CGRect titleRect = self.navigationItem.titleView.frame;
        titleRect = [self.navigationController.view convertRect:titleRect fromView:self.navigationItem.titleView.superview];
        
        *view = self.navigationController.view;
        *rect = titleRect;
    }
}

#pragma mark -
#pragma mark AlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == EditPostViewControllerAlertTagFailedMedia) {
        if (buttonIndex == 1) {
            DDLogInfo(@"Saving post even after some media failed to upload");
            [self savePost:YES];
        }
        _failedMediaAlertView = nil;
    } else if (alertView.tag == EditPostViewControllerAlertTagSwitchBlogs) {
        if (buttonIndex == 1) {
            [self showBlogSelector];
        }
    }
    return;
}

#pragma mark -
#pragma mark ActionSheet Delegate Methods

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    _currentActionSheet = actionSheet;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    _currentActionSheet = nil;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([actionSheet tag] == 201) {
        [WPMobileStats trackEventForWPComWithSavedProperties:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
        // Discard
        if (buttonIndex == 0) {
            [self discardChangesAndDismiss];
        }
        
        if (buttonIndex == 1) {
			if ([actionSheet numberOfButtons] == 3) {
                // Publish / Update published
                EditPostUserEvent userEvent = EditPostUserActionUpdate;
                if (![self.post.original.status isEqualToString:@"publish"]) {
                    if ([self isScheduled]) {
                        userEvent = EditPostUserActionSchedule;
                    } else {
                        userEvent = EditPostUserActionPublish;
                    }
                    
                    // If you tapped on a button labeled "Publish", you probably expect the post to be published
                    if (![self.post.status isEqualToString:@"publish"]) {
                        self.post.status = @"publish";
                    }
                }
                [self saveActionWithUserEvent:userEvent];
                
			} else {
                // Save or update draft
                EditPostUserEvent userEvent = EditPostUserActionUpdate;
                if (![self.post hasRemote]) {
                    userEvent = EditPostUserActionSave;
                    
                    // If you tapped on a button labeled "Save Draft", you probably expect the post to be saved as a draft
                    if([self.post.status isEqualToString:@"publish"]) {
                        self.post.status = @"draft";
                    }
                }
                [self saveActionWithUserEvent:userEvent];
			}
        }
        
        if (buttonIndex == 2 && [actionSheet numberOfButtons] == 4) {
            //Publish
            if (![self.post.status isEqualToString:@"publish"]) {
                self.post.status = @"publish";
            }
            
            EditPostUserEvent userEvent = EditPostUserActionPublish;
            if ([self isScheduled]) {
                userEvent = EditPostUserActionSchedule;
            }
            [self saveActionWithUserEvent:userEvent];
        }
    }
}

#pragma mark - TextView delegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    _tapToStartWritingLabel.hidden = YES;
}

- (void)textViewDidChange:(UITextView *)aTextView {
    [self autosaveContent];
}

- (void)textViewDidEndEditing:(UITextView *)aTextView {
    [self autosaveContent];
    if ([_textView.text isEqualToString:@""]) {
        _tapToStartWritingLabel.hidden = NO;
    }
}

#pragma mark - TextField delegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self autosaveContent];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == _titleTextField) {
        self.post.postTitle = [textField.text stringByReplacingCharactersInRange:range withString:string];
        self.navigationItem.title = [self editorTitle];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [_textView becomeFirstResponder];
    return NO;
}

#pragma mark - Positioning & Rotation

- (BOOL)shouldHideToolbarsWhileTyping {
    /*
     Never hide for the iPad.
     Always hide on the iPhone except for portrait + external keyboard
     */
    if (IS_IPAD) {
        return NO;
    }
    
    BOOL isLandscape = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    if (!isLandscape && _isExternalKeyboard) {
        return NO;
    }
    
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    DDLogMethod();
    CGRect frame = _editorToolbar.frame;
    if (UIDeviceOrientationIsLandscape(interfaceOrientation)) {
        if (IS_IPAD) {
            frame.size.height = WPKT_HEIGHT_IPAD_LANDSCAPE;
        } else {
            frame.size.height = WPKT_HEIGHT_IPHONE_LANDSCAPE;
            if (_linkHelperAlertView && !_isExternalKeyboard) {
                [_linkHelperAlertView hideTitleAndDescription:YES];
            }
        }
        
    } else {
        if (IS_IPAD) {
            frame.size.height = WPKT_HEIGHT_IPAD_PORTRAIT;
        } else {
            frame.size.height = WPKT_HEIGHT_IPHONE_PORTRAIT;
            if (_linkHelperAlertView) {
                [_linkHelperAlertView hideTitleAndDescription:NO];
            }
        }
    }
    _editorToolbar.frame = frame;
    _titleToolbar.frame = frame; // Frames match, no need to re-calc.
}


#pragma mark -
#pragma mark Keyboard management

- (void)keyboardWillShow:(NSNotification *)notification {
    DDLogMethod();
	_isShowingKeyboard = YES;
    
    CGRect originalKeyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardFrame = [self.view convertRect:[self.view.window convertRect:originalKeyboardFrame fromWindow:nil] fromView:nil];
    _isExternalKeyboard = keyboardFrame.origin.y > self.view.frame.size.height;
    
    if (_isExternalKeyboard) {
        [WPMobileStats flagProperty:StatsPropertyPostDetailHasExternalKeyboard forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
    } else {
        [WPMobileStats unflagProperty:StatsPropertyPostDetailHasExternalKeyboard forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
    }
    
    if ([self shouldHideToolbarsWhileTyping]) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [self.navigationController setToolbarHidden:YES animated:NO];
    }
}

- (void)keyboardDidShow:(NSNotification *)notification {
    [self positionTextView:notification];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    DDLogMethod();
	_isShowingKeyboard = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController setToolbarHidden:NO animated:NO];
    
    [self positionTextView:notification];
}

@end
