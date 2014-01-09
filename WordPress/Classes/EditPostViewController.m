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
#import "IOS7CorrectedTextView.h"
#import "NSString+XMLExtensions.h"
#import "Post.h"
#import "WPTableViewCell.h"
#import "BlogSelectorViewController.h"
#import "WPBlogSelectorButton.h"

NSString *const EditPostViewControllerLastUsedBlogURL = @"EditPostViewControllerLastUsedBlogURL";
CGFloat const EPVCTextfieldHeight = 44.0f;
CGFloat const EPVCCellHeight = 44.0f;
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

@end

@implementation EditPostViewController

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

- (void)dealloc {
    _failedMediaAlertView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithDraftForLastUsedBlog {
    Blog *blog = [EditPostViewController blogForNewDraft];
    return [self initWithPost:[Post newDraftForBlog:blog]];
}

- (id)initWithPost:(AbstractPost *)post {
    self = [self initWithStyle:UITableViewStylePlain];
    if (self) {
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
        self.tableView.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    }
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self setupNavbar];
    [self setupToolbar];
    [self setupTableHeaderView];
    
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    if(self.navigationController.navigationBarHidden) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
    
    if (self.navigationController.toolbarHidden) {
        [self.navigationController setToolbarHidden:NO animated:YES];
    }
    
    for (UIView *view in self.navigationController.toolbar.subviews) {
        [view setExclusiveTouch:YES];
    }
    
    [self refreshUIForCurrentPost];
    
    [_textView setContentOffset:CGPointMake(0, 0)];
}

- (void)viewWillDisappear:(BOOL)animated {
    DDLogMethod();
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

    
    [self.navigationController setToolbarHidden:YES animated:YES];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
	[_titleTextField resignFirstResponder];
	[_textView resignFirstResponder];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [self refreshTableHeaderViewHeight];
}

- (void)didReceiveMemoryWarning {
    DDLogInfo(@"");
    [super didReceiveMemoryWarning];
}

#pragma mark - View Setup

- (void)setupNavbar {
    self.navigationController.navigationBar.translucent = NO;
    
    if (self.navigationItem.leftBarButtonItem == nil) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelEditing)];
        self.navigationItem.leftBarButtonItem = cancelButton;
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
        NSMutableAttributedString *titleSubtext = [[NSMutableAttributedString alloc] initWithString:self.post.blog.blogName
                                                                                         attributes:@{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:10.0] }];
        [titleText appendAttributedString:titleSubtext];
        [titleButton setAttributedTitle:titleText forState:UIControlStateNormal];

        [titleButton sizeToFit];
    }
}

- (void)setupToolbar {
    UIToolbar *toolbar = self.navigationController.toolbar;
    toolbar.barTintColor = [WPStyleGuide littleEddieGrey];
    toolbar.translucent = NO;
    toolbar.barStyle = UIBarStyleDefault;
    
    if ([self.toolbarItems count] > 0) {
        return;
    }
    
    UIBarButtonItem *previewButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-posts-editor-preview"] style:UIBarButtonItemStylePlain target:self action:@selector(showPreview)];
    UIBarButtonItem *photoButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-posts-editor-media"] style:UIBarButtonItemStylePlain target:self action:@selector(showMediaOptions)];
    
    previewButton.tintColor = [WPStyleGuide readGrey];
    photoButton.tintColor = [WPStyleGuide readGrey];
    
    UIBarButtonItem *leftFixedSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *rightFixedSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *centerFlexSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    leftFixedSpacer.width = -2.0f;
    rightFixedSpacer.width = -5.0f;
    
    self.toolbarItems = @[leftFixedSpacer, previewButton, centerFlexSpacer, photoButton, rightFixedSpacer];
}

- (void)setupTableHeaderView {
    CGFloat x = 0.0f;
    CGFloat y = 0.0f;
    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat minHeight = CGRectGetHeight(self.view.frame) - (EPVCCellHeight + EPVCNavbarHeight + EPVCToolbarHeight);
    CGRect frame = CGRectZero;
    
    // Header View
    if (!self.tableView.tableHeaderView) {
        frame = CGRectMake(x, y, width, minHeight);
        UIView *tableHeaderView = [[UIView alloc] initWithFrame:frame];
        tableHeaderView.clipsToBounds = YES;
        self.tableView.tableHeaderView = tableHeaderView;
    }
    
    
    // tableHeaderView Content View. The tableHeaderView matches the width of the tableView.
    // This let's us achieve the layout we want on the iPad without a lot of layout code.
    if (!_tableHeaderViewContentView) {
        if (IS_IPAD) {
            x = (width - WPTableViewFixedWidth) / 2;
            width = WPTableViewFixedWidth;
        }
        frame = CGRectMake(x, y, width, minHeight);
        self.tableHeaderViewContentView = [[UIView alloc] initWithFrame:frame];
        _tableHeaderViewContentView.backgroundColor = [UIColor whiteColor];
        if (IS_IPAD) {
            _tableHeaderViewContentView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        } else {
            _tableHeaderViewContentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        }
    }
    [self.tableView.tableHeaderView addSubview:_tableHeaderViewContentView];
    
    
    // Title TextField.
    // Appears at the top of the Table Header view.
    if (!_titleTextField) {
        CGFloat textWidth = CGRectGetWidth(_tableHeaderViewContentView.frame) - (2 * EPVCStandardOffset);
        frame = CGRectMake(EPVCStandardOffset, y, textWidth, EPVCTextfieldHeight);
        self.titleTextField = [[UITextField alloc] initWithFrame:frame];
        _titleTextField.delegate = self;
        _titleTextField.font = [WPStyleGuide postTitleFont];
        _titleTextField.textColor = [WPStyleGuide darkAsNightGrey];
        _titleTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _titleTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:(NSLocalizedString(@"Enter title here", @"Label for the title of the post field. Should be the same as WP core.")) attributes:(@{NSForegroundColorAttributeName: [WPStyleGuide textFieldPlaceholderGrey]})];
        
        _titleTextField.returnKeyType = UIReturnKeyNext;
    }
    [_tableHeaderViewContentView addSubview:_titleTextField];
    
    
    // InputAccessoryView for title textField.
    if (!_titleToolbar) {
        frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.frame), WPKT_HEIGHT_PORTRAIT);
        self.titleToolbar = [[WPKeyboardToolbarDone alloc] initWithFrame:frame];
        _titleToolbar.backgroundColor = [UIColor UIColorFromHex:(0xdcdfe2)];
        if (IS_IPAD) {
            _titleToolbar.backgroundColor = [UIColor UIColorFromHex:(0xcfd2d5)];
        }
        _titleToolbar.delegate = self;
        _titleTextField.inputAccessoryView = _titleToolbar;
    }
    
    
    // One pixel separator bewteen title and content text fields.
    if (!_separatorView) {
        y = CGRectGetMaxY(_titleTextField.frame);
        CGFloat separatorWidth = CGRectGetWidth(_tableHeaderViewContentView.frame) - EPVCStandardOffset;
        frame = CGRectMake(EPVCStandardOffset, y, separatorWidth, 1.0);
        self.separatorView = [[UIView alloc] initWithFrame:frame];
        _separatorView.backgroundColor = [WPStyleGuide readGrey];
        _separatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    [_tableHeaderViewContentView addSubview:_separatorView];
    
    
    // Content text field.
    // Shows the post body.
    // Height should never be smaller than what is required to display its text.
    if (!_textView) {
        y = CGRectGetMaxY(_separatorView.frame) + EPVCTextViewTopPadding;
        CGFloat height = minHeight - EPVCTextfieldHeight;
        width = CGRectGetWidth(_tableHeaderViewContentView.frame);
        // Let x == 0.0f because the textView has its own inset margins.
        frame = CGRectMake(0.0f, y, width, height);
        self.textView = [[IOS7CorrectedTextView alloc] initWithFrame:frame];
        _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _textView.delegate = self;
        _textView.typingAttributes = [WPStyleGuide regularTextAttributes];
        _textView.font = [WPStyleGuide regularTextFont];
        _textView.textColor = [WPStyleGuide darkAsNightGrey];
        _textView.textContainerInset = UIEdgeInsetsMake(0.0f, EPVCTextViewOffset, 0.0f, EPVCTextViewOffset);
    }
    [_tableHeaderViewContentView addSubview:_textView];
    
    
    // Formatting bar for the textView's inputAccessoryView.
    if (_editorToolbar == nil) {
        frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.frame), WPKT_HEIGHT_PORTRAIT);
        self.editorToolbar = [[WPKeyboardToolbarBase alloc] initWithFrame:frame];
        _editorToolbar.backgroundColor = [UIColor UIColorFromHex:(0xdcdfe2)];
        if (IS_IPAD) {
            _editorToolbar.backgroundColor = [UIColor UIColorFromHex:(0xcfd2d5)];
        }
        _editorToolbar.delegate = self;
        _textView.inputAccessoryView = _editorToolbar;
    }
    
    
    // One pixel separator bewteen content and table view cells.
    if (!_cellSeparatorView) {
        y = CGRectGetMaxY(_tableHeaderViewContentView.frame) - 1;
        CGFloat separatorWidth = CGRectGetWidth(_tableHeaderViewContentView.frame) - EPVCStandardOffset;
        frame = CGRectMake(EPVCStandardOffset, y, separatorWidth, 1.0);
        self.cellSeparatorView = [[UIView alloc] initWithFrame:frame];
        _cellSeparatorView.backgroundColor = [WPStyleGuide readGrey];
        _cellSeparatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    }
    [_tableHeaderViewContentView addSubview:_cellSeparatorView];
    
    
    if (!_tapToStartWritingLabel) {
        frame = _textView.frame;
        frame.size.height = 26.0f;
        frame.origin.x = EPVCStandardOffset;
        frame.size.width -= (EPVCStandardOffset * 2);
        self.tapToStartWritingLabel = [[UILabel alloc] initWithFrame:frame];
        _tapToStartWritingLabel.text = NSLocalizedString(@"Tap here to begin writing", @"Placeholder for the main body text. Should hint at tapping to enter text (not specifying body text).");
        _tapToStartWritingLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _tapToStartWritingLabel.font = [WPStyleGuide regularTextFont];
        _tapToStartWritingLabel.textColor = [WPStyleGuide textFieldPlaceholderGrey];
    }
    [_tableHeaderViewContentView addSubview:_tapToStartWritingLabel];
}

- (CGFloat)heightForTextView {
    // The minHeight is the height of the table view minus the title text view and top padding
    // We also have to account for the toolbar if the tableView has not yet been
    // added to the app's key window.
    CGFloat minHeight = self.view.frame.size.height;
    minHeight -= (EPVCTextfieldHeight + EPVCTextViewTopPadding);
    if (self.dismissingBlogPicker) {
        // For some reason the frame/bounds hight includes the status bar.
        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
            minHeight -= [UIApplication sharedApplication].statusBarFrame.size.height;
        } else {
            minHeight -= [UIApplication sharedApplication].statusBarFrame.size.width;
        }
    } else if (!self.tableView.window) {
        minHeight -= EPVCToolbarHeight;
    }
    
    if (_isShowingKeyboard) {
        minHeight -= self.tableView.contentInset.bottom;
    } else {
        minHeight -= EPVCCellHeight; // Show the settings cell if the keyboard is not showing.
    }
    
    CGFloat width = _textView.frame.size.width;
    width -= (_textView.textContainerInset.left + _textView.textContainerInset.right);
    width -= (_textView.textContainer.lineFragmentPadding * 2);
    
    CGRect rect = [_textView.text boundingRectWithSize:CGSizeMake(width, INFINITY)
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                            attributes:_textView.typingAttributes
                                               context:nil];
    
    
    CGFloat rectHeight = rect.size.height;
    rectHeight += EPVCTextViewBottomPadding;
    
    return MAX(ceil(rectHeight), ceil(minHeight));
}

- (CGFloat)heightForTableHeaderView {
    CGFloat height = _textView.frame.origin.y;
    height += [self heightForTextView];
    return height;
}

- (void)refreshTableHeaderViewHeight {
    // Update the height of the post content text view if necessary.
    CGFloat height = [self heightForTextView];
    CGRect frame = _textView.frame;
    
    // If the height doesn't need to change just bail.
    if (frame.size.height == height) {
        return;
    }
    
    frame.size.height = height;
    _textView.frame = frame;
    
    // Update the height of the header view.
    // The content view should autoresize its heightx
    UIView *tableHeaderView = self.tableView.tableHeaderView;
    frame = tableHeaderView.frame;
    frame.size.height = [self heightForTableHeaderView];
    tableHeaderView.frame = frame;
    self.tableView.tableHeaderView = tableHeaderView;
    
    if (_isShowingKeyboard) {
        [self scrollCursorIntoViewIfNeeded];
    }
}

- (void)scrollCursorIntoViewIfNeeded {
    if ([_titleTextField isFirstResponder]) {
        [self.tableView scrollRectToVisible:CGRectZero animated:YES];
        return;
    }
    
    // Get the cursor position in the textView
    CGRect rect = [_textView caretRectForPosition:_textView.selectedTextRange.start];
    
    // Translate the rect to the tableView
    rect = [self.tableView convertRect:rect fromView:_textView];
    
    // Add a line of padding to make sure the cursor never dips below the visible bounds
    rect.size.height += ceil(EPVCTextViewBottomPadding / 2.0);
    
    // scroll the tableview to show the rect.
    [self.tableView scrollRectToVisible:rect animated:YES];
}

#pragma mark - TableView

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return EPVCCellHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"EditPostTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.row == 0) {
        // Settings Cell
        cell.textLabel.text = NSLocalizedString(@"Options", @"Title of the Post Settings tableview cell in the Post Editor. Tapping shows settings and options related to the post being edited.");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    [WPStyleGuide configureTableViewCell:cell];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self showSettings];
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
    vc.title = NSLocalizedString(@"Select Blog", @"");
    
    if (IS_IPAD) {
        vc.preferredContentSize = CGSizeMake(320.0, 500);
        
        CGRect titleRect = self.navigationItem.titleView.frame;
        titleRect = [self.navigationController.view convertRect:titleRect fromView:self.navigationItem.titleView.superview];
        
        self.blogSelectorPopover = [[UIPopoverController alloc] initWithContentViewController:vc];
        self.blogSelectorPopover.backgroundColor = [WPStyleGuide newKidOnTheBlockBlue];
        self.blogSelectorPopover.delegate = self;
        [self.blogSelectorPopover presentPopoverFromRect:titleRect inView:self.navigationController.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
        navController.navigationBar.translucent = NO;
        navController.modalPresentationStyle = UIModalPresentationPageSheet;
        navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
        [self presentViewController:navController animated:YES completion:nil];
    }
}

- (void)showSettings {
    [WPMobileStats flagProperty:StatsPropertyPostDetailClickedSettings forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
    PostSettingsViewController *vc = [[PostSettingsViewController alloc] initWithPost:self.post];
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

- (void)cancelEditing {
    if(_currentActionSheet) return;
    
    [_textView resignFirstResponder];
    [_titleTextField resignFirstResponder];
	[self.postSettingsViewController endEditingAction:nil];
    
	if ([self isMediaInUploading]) {
		[self showMediaInUploadingAlert];
		return;
	}
    
    if (![self hasChanges]) {
        [WPMobileStats trackEventForWPComWithSavedProperties:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
        [self discardChangesAndDismiss];
        return;
    }
    
	UIActionSheet *actionSheet;
	if (![self.post.original.status isEqualToString:@"draft"] && self.editMode != EditPostViewControllerModeNewPost) {
        // The post is already published in the server or it was intended to be and failed: Discard changes or keep editing
		actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"You have unsaved changes.", @"Title of message with options that shown when there are unsaved changes and the author is trying to move away from the post.")
												  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Keep Editing", @"Button shown if there are unsaved changes and the author is trying to move away from the post.")
                                    destructiveButtonTitle:NSLocalizedString(@"Discard", @"Button shown if there are unsaved changes and the author is trying to move away from the post.")
										 otherButtonTitles:nil];
    } else if (self.editMode == EditPostViewControllerModeNewPost) {
        // The post is a local draft or an autosaved draft: Discard or Save
        actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"You have unsaved changes.", @"Title of message with options that shown when there are unsaved changes and the author is trying to move away from the post.")
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Keep Editing", @"Button shown if there are unsaved changes and the author is trying to move away from the post.")
                                    destructiveButtonTitle:NSLocalizedString(@"Discard", @"Button shown if there are unsaved changes and the author is trying to move away from the post.")
                                         otherButtonTitles:NSLocalizedString(@"Save Draft", @"Button shown if there are unsaved changes and the author is trying to move away from the post."), nil];
    } else {
        // The post was already a draft
        actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"You have unsaved changes.", @"Title of message with options that shown when there are unsaved changes and the author is trying to move away from the post.")
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Keep Editing", @"Button shown if there are unsaved changes and the author is trying to move away from the post.")
                                    destructiveButtonTitle:NSLocalizedString(@"Discard", @"Button shown if there are unsaved changes and the author is trying to move away from the post.")
                                         otherButtonTitles:NSLocalizedString(@"Update Draft", @"Button shown if there are unsaved changes and the author is trying to move away from an already published/saved post."), nil];
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

#pragma mark - UI Manipulation

- (void)refreshButtons {
    // Left nav button: Cancel Button
    if (self.navigationItem.leftBarButtonItem == nil) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelEditing)];
        self.navigationItem.leftBarButtonItem = cancelButton;
    }
    
    // Right nav button: Publish Button
    NSString *buttonTitle;
    if(![self.post hasRemote] || ![self.post.status isEqualToString:self.post.original.status]) {
        if ([self.post.status isEqualToString:@"publish"] && ([self.post.dateCreated compare:[NSDate date]] == NSOrderedDescending)) {
            buttonTitle = NSLocalizedString(@"Schedule", @"Schedule button, this is what the Publish button changes to in the Post Editor if the post has been scheduled for posting later.");
            
		} else if ([self.post.status isEqualToString:@"publish"]){
            buttonTitle = NSLocalizedString(@"Publish", @"Publish button label.");
            
		} else {
            buttonTitle = NSLocalizedString(@"Save", @"Save button label (saving content, ex: Post, Page, Comment).");
        }
    } else {
        buttonTitle = NSLocalizedString(@"Update", @"Update button label (saving content, ex: Post, Page, Comment).");
    }
    
    if (self.navigationItem.rightBarButtonItem == nil) {
        UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:buttonTitle
                                                                       style:[WPStyleGuide barButtonStyleForDone]
                                                                      target:self
                                                                      action:@selector(saveAction)];
        self.navigationItem.rightBarButtonItem = saveButton;
    } else {
        self.navigationItem.rightBarButtonItem.title = buttonTitle;
    }
    
    BOOL updateEnabled = self.hasChanges || self.post.remoteStatus == AbstractPostRemoteStatusFailed;
    [self.navigationItem.rightBarButtonItem setEnabled:updateEnabled];
    
    // Seems to be a bug with UIBarButtonItem respecting the UIControlStateDisabled text color
    NSDictionary *titleTextAttributes;
    UIColor *color = updateEnabled ? [UIColor whiteColor] : [UIColor lightGrayColor];
    titleTextAttributes = @{NSFontAttributeName: [WPStyleGuide regularTextFont], NSForegroundColorAttributeName : color};
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
}

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
    
    [self refreshTableHeaderViewHeight];
    [self refreshButtons];
}

- (UIButton *)titleBarButton {
    if (_titleBarButton) {
        return _titleBarButton;
    }
    UIButton *titleButton = [WPBlogSelectorButton buttonWithType:UIButtonTypeSystem];
    titleButton.frame = CGRectMake(0, 0, 200, 33);
    titleButton.titleLabel.numberOfLines = 2;
    titleButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    titleButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [titleButton setImage:[UIImage imageNamed:@"icon-navbar-dropdown.png"] forState:UIControlStateNormal];
    [titleButton addTarget:self action:@selector(showBlogSelectorPrompt) forControlEvents:UIControlEventTouchUpInside];
    [titleButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 10)];
    [titleButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];

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

- (void)saveAction {
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
    [WPMobileStats trackEventForWPComWithSavedProperties:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
    
    [self logSavePostStats];
    
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
    NSString *buttonTitle = self.navigationItem.rightBarButtonItem.title;
    NSString *event;
    if ([buttonTitle isEqualToString:NSLocalizedString(@"Schedule", nil)]) {
        event = StatsEventPostDetailClickedSchedule;
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Publish", nil)]) {
        event = StatsEventPostDetailClickedPublish;
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Save", nil)]) {
        event = StatsEventPostDetailClickedSave;
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Update", nil)]) {
        event = StatsEventPostDetailClickedUpdate;
    }
    
    if (event != nil) {
        [WPMobileStats trackEventForWPCom:[self formattedStatEventString:event]];
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
    [self refreshTableHeaderViewHeight];
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
    
    _linkHelperAlertView = [[WPAlertView alloc] initWithFrame:self.view.bounds andOverlayMode:WPAlertViewOverlayModeTwoTextFieldsTwoButtonMode];
    
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
    [self.view addSubview:_linkHelperAlertView];
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
        // Discard
        if (buttonIndex == 0) {
            [WPMobileStats trackEventForWPComWithSavedProperties:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
            [self discardChangesAndDismiss];
        }
        
        if (buttonIndex == 1) {
            // Cancel / Keep editing
			if ([actionSheet numberOfButtons] == 2) {
                [WPMobileStats trackEventForWPComWithSavedProperties:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
                
				[actionSheet dismissWithClickedButtonIndex:0 animated:YES];
                // Save draft
			} else {
                [WPMobileStats trackEventForWPComWithSavedProperties:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
                
                // If you tapped on a button labeled "Save Draft", you probably expect the post to be saved as a draft
                if (![self.post hasRemote] && [self.post.status isEqualToString:@"publish"]) {
                    self.post.status = @"draft";
                }
                DDLogInfo(@"Saving post as a draft after user initially attempted to cancel");
                [self savePost:YES];
			}
        }
    }
}

#pragma mark - TextView delegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    _tapToStartWritingLabel.hidden = YES;
}

- (void)textViewDidChange:(UITextView *)aTextView {
    [self autosaveContent];
    [self refreshButtons];
}

- (void)textViewDidEndEditing:(UITextView *)aTextView {
    [self autosaveContent];
    [self refreshButtons];
    if ([_textView.text isEqualToString:@""]) {
        _tapToStartWritingLabel.hidden = NO;
    }
}

#pragma mark - TextField delegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self autosaveContent];
    [self refreshButtons];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == _titleTextField) {
        self.post.postTitle = [textField.text stringByReplacingCharactersInRange:range withString:string];
        self.navigationItem.title = [self editorTitle];
    }
    
    [self refreshButtons];
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
    [self refreshTableHeaderViewHeight];
    [self scrollCursorIntoViewIfNeeded];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    DDLogMethod();
	_isShowingKeyboard = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController setToolbarHidden:NO animated:NO];
    
    [self refreshTableHeaderViewHeight];
}

@end
