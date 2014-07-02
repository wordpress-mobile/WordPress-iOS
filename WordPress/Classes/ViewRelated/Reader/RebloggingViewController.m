#import <QuartzCore/QuartzCore.h>

#import "RebloggingViewController.h"
#import "ReaderPost.h"
#import "ReaderPostSimpleContentView.h"
#import "ReaderPostService.h"
#import "BlogSelectorViewController.h"
#import "WPBlogSelectorButton.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "WPToast.h"

CGFloat const ReblogViewPostMargin = 10;
CGFloat const ReblogViewTextBottomInset = 30;

@interface RebloggingViewController ()<UIPopoverControllerDelegate, UITextViewDelegate>

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) UIButton *titleBarButton;
@property (nonatomic, strong) UIPopoverController *blogSelectorPopover;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) ReaderPostSimpleContentView *postView;
@property (nonatomic, strong) UIView *postViewWrapper;
@property (nonatomic, strong) CALayer *postViewBackingLayer;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIImage *avatarImage;
@property (nonatomic, strong) UIImage *featuredImage;
@property (nonatomic, strong) UILabel *textPromptLabel;
@property (nonatomic) BOOL isShowingKeyboard;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@property (nonatomic, strong) UIBarButtonItem *activityBarItem;
@property (nonatomic, strong) UIBarButtonItem *publishBarItem;

@end

@implementation RebloggingViewController

#pragma mark - Lifecycle Methods

- (void)dealloc
{
    self.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithPost:(id)post featuredImage:(id)image avatarImage:(UIImage *)avatarImage
{
    self = [self init];
    if (self){
        self.post = post;
        self.featuredImage = image;
        self.avatarImage = avatarImage;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self configureNavbar];
    [self configureView];

	UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePostViewTapped:)];
    tgr.cancelsTouchesInView = YES;
    [self.postView addGestureRecognizer:tgr];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self layoutViews];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self layoutViews];
}


#pragma mark - Appearance and Layout

- (void)configureNavbar
{
    if (!self.navigationItem.rightBarButtonItem) {
        self.publishBarItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Publish", @"")
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(handlePublishAction:)];
        self.navigationItem.rightBarButtonItem = self.publishBarItem;
    }

    if (!self.navigationItem.leftBarButtonItem) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                              target:self
                                                                                              action:@selector(handleCancelAction:)];
    }

    if (!self.activityBarItem) {
        self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.activityBarItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityView];
    }

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    NSInteger blogCount = [blogService blogCountForAllAccounts];
    if (blogCount < 2) {
        self.navigationItem.title = NSLocalizedString(@"Reblog", @"");
    } else {
        UIButton *titleButton = self.titleBarButton;
        self.navigationItem.titleView = titleButton;
        NSMutableAttributedString *titleText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Reblog to", @"")]
                                                                                      attributes:@{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans-Bold" size:14.0] }];

        if (!self.blog) {
            self.blog = [blogService lastUsedOrFirstWPcomBlog];
        }
        NSDictionary *subtextAttributes = @{ NSFontAttributeName: [UIFont fontWithName:@"OpenSans" size:10.0] };
        NSMutableAttributedString *titleSubtext = [[NSMutableAttributedString alloc] initWithString:self.blog.blogName
                                                                                         attributes:subtextAttributes];
        [titleText appendAttributedString:titleSubtext];
        [titleButton setAttributedTitle:titleText forState:UIControlStateNormal];
        [titleButton sizeToFit];
    }
}

- (UIButton *)titleBarButton
{
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
    [titleButton addTarget:self action:@selector(handleTitleButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [titleButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 10)];
    [titleButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
    [titleButton setAccessibilityHint:NSLocalizedString(@"Tap to select which site to publish to", nil)];

    _titleBarButton = titleButton;

    return _titleBarButton;
}

- (void)configureView
{
    [self.view addSubview:self.textView];
    [self.textView addSubview:self.postViewWrapper];
    [self.postViewWrapper addSubview:self.postView];
    [self.textView addSubview:self.textPromptLabel];

    [self layoutViews];
}

- (UITextView *)textView
{
    if (_textView) {
        return _textView;
    }
    self.textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _textView.delegate = self;
    _textView.typingAttributes = [WPStyleGuide regularTextAttributes];
    _textView.font = [WPStyleGuide regularTextFont];
    _textView.textColor = [WPStyleGuide darkAsNightGrey];
    _textView.accessibilityLabel = NSLocalizedString(@"Optional note", @"Optional note to include with the reblogged post");

    return _textView;
}

- (UIView *)postViewWrapper
{
    if (_postViewWrapper) {
        return _postViewWrapper;
    }

    _postViewWrapper = [[UIView alloc] initWithFrame:self.view.bounds];
    _postViewWrapper.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    CALayer *layer = [[CALayer alloc] init];
    layer.zPosition = -1;
    layer.backgroundColor = [[WPStyleGuide itsEverywhereGrey] CGColor];
    self.postViewBackingLayer = layer;
    [_postViewWrapper.layer addSublayer:layer];

    return _postViewWrapper;
}

- (ReaderPostSimpleContentView *)postView
{
    if (_postView) {
        return _postView;
    }

    self.postView = [[ReaderPostSimpleContentView alloc] init];
    _postView.contentProvider = self.post;
    _postView.backgroundColor = [UIColor whiteColor];
    [_postView setFeaturedImage:self.featuredImage];
    [_postView setAvatarImage:[self.post cachedAvatarWithSize:CGSizeMake(WPContentAttributionViewAvatarSize, WPContentAttributionViewAvatarSize)]];

    return _postView;
}

- (UILabel *)textPromptLabel
{
    if (_textPromptLabel) {
        return _textPromptLabel;
    }

    CGRect frame = CGRectZero;
    frame.origin.x = ReblogViewPostMargin;
    frame.origin.y = self.textView.textContainerInset.top;
    frame.size.width = CGRectGetWidth(self.textView.bounds) - (ReblogViewPostMargin * 2);
    frame.size.height = 26.0f;
    self.textPromptLabel = [[UILabel alloc] initWithFrame:frame];
    _textPromptLabel.text = NSLocalizedString(@"Add your thoughts here... (optional)", @"Placeholder text prompting the user to add a note to the post they are reblogging.");
    _textPromptLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _textPromptLabel.font = [WPStyleGuide regularTextFont];
    _textPromptLabel.textColor = [WPStyleGuide textFieldPlaceholderGrey];
    _textPromptLabel.isAccessibilityElement = NO;

    return _textPromptLabel;
}

- (void)layoutViews
{
    CGFloat verticleMargin = ReblogViewPostMargin;
    CGFloat horizontalMargin = ReblogViewPostMargin;
    if (IS_IPAD) {
        horizontalMargin = 30;
    }

    CGFloat width = CGRectGetWidth(self.view.bounds) - (horizontalMargin * 2);
    CGSize size = [self.postView sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];

    CGFloat height = size.height;

    CGRect frame = CGRectMake(horizontalMargin, verticleMargin, width, height);
    CGFloat top = CGRectGetMaxY(frame) + (verticleMargin * 2);
    self.postViewWrapper.frame = frame;
    self.postView.frame = self.postViewWrapper.bounds;

    self.textView.textContainerInset = UIEdgeInsetsMake(top, ReblogViewPostMargin, ReblogViewTextBottomInset, ReblogViewPostMargin);

    frame = CGRectZero;
    frame.origin.x = horizontalMargin;
    frame.origin.y = self.textView.textContainerInset.top;
    frame.size.width = CGRectGetWidth(self.textView.bounds) - (horizontalMargin * 2);
    frame.size.height = 26.0f;
    self.textPromptLabel.frame = frame;

    frame = self.postViewWrapper.bounds;
    CGFloat x = CGRectGetMinX(frame) - horizontalMargin;
    CGFloat y = CGRectGetMinY(frame) - verticleMargin;
    CGFloat w = CGRectGetWidth(frame) + horizontalMargin * 2.0f;
    CGFloat h = CGRectGetHeight(frame) + verticleMargin * 2.0f;
    self.postViewBackingLayer.frame = CGRectMake(x, y, w, h);

    // Refresh the contentSize to account for changes to textContainerInset
    // by calling sizeToFit and then resetting the frame.
    // A little hackish but prevents layout issues due to orientation change.
    [self.textView sizeToFit];
    self.textView.frame = self.view.bounds;
}

- (void)resizeTextView:(NSNotification *)notification
{
    NSDictionary *keyboardInfo = [notification userInfo];
    CGRect originalKeyboardFrame = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardFrame = [self.view convertRect:[self.view.window convertRect:originalKeyboardFrame fromWindow:nil] fromView:nil];

    CGRect frame = self.textView.frame;

    if (self.isShowingKeyboard) {
        frame.size.height = CGRectGetMinY(keyboardFrame) - CGRectGetMinY(frame);
    } else {
        frame.size.height = CGRectGetHeight(self.view.bounds);
    }

    self.textView.frame = frame;
}

- (void)moveCursorIntoView
{
    // Hacky way to make sure the cursor is in view with iOS7.1's funky cursor positioning.
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect rect = [self.textView caretRectForPosition:self.textView.selectedTextRange.end];
        rect.size.height += self.textView.textContainerInset.bottom;
        [self.textView scrollRectToVisible:rect animated:YES];
    });
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark Nabar Button actions

- (void)handleCancelAction:(id)sender
{
    [self dismiss];
}

- (void)handlePublishAction:(id)sender
{
    [self.textView setEditable:NO];
    self.navigationItem.leftBarButtonItem.enabled = NO;

    self.navigationItem.rightBarButtonItem = self.activityBarItem;
	[self.activityView startAnimating];

    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];

    [service reblogPost:self.post toSite:[self.blog.blogID integerValue] note:[self.textView.text trim] success:^{
        [WPToast showToastWithMessage:NSLocalizedString(@"Reblogged", @"User reblogged a post.")
							 andImage:[UIImage imageNamed:@"action_icon_replied"]];

		if ([self.delegate respondsToSelector:@selector(postWasReblogged:)]) {
			[self.delegate postWasReblogged:self.post];
		}

        [WPAnalytics track:WPAnalyticsStatReaderRebloggedArticle];
        [self dismiss];

    } failure:^(NSError *error) {
		DDLogError(@"Error Reblogging Post : %@", [error localizedDescription]);
        [self.textView setEditable:YES];
        self.navigationItem.leftBarButtonItem.enabled = YES;
		[self.activityView stopAnimating];
        self.navigationItem.rightBarButtonItem = self.publishBarItem;

		// TODO: Failure reason.
        [WPError showAlertWithTitle:NSLocalizedString(@"Reblog failed", nil) message:NSLocalizedString(@"There was a problem reblogging. Please try again.", nil)];
    }];
}

- (void)handleTitleButtonAction:(id)sender
{
    if (IS_IPAD && self.blogSelectorPopover.isPopoverVisible) {
        [self.blogSelectorPopover dismissPopoverAnimated:YES];
        self.blogSelectorPopover = nil;
    }

    void (^dismissHandler)() = ^(void) {
        if (IS_IPAD) {
            [self.blogSelectorPopover dismissPopoverAnimated:YES];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    };
    void (^selectedCompletion)(NSManagedObjectID *) = ^(NSManagedObjectID *selectedObjectID) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        Blog *blog = (Blog *)[context objectWithID:selectedObjectID];
        if (blog) {
            self.blog = blog;
        }
        [self configureNavbar];
        dismissHandler();
    };

    BlogSelectorViewController *vc = [[BlogSelectorViewController alloc] initWithSelectedBlogObjectID:self.blog.objectID
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


#pragma mark Gesture Regonizer

- (void)handlePostViewTapped:(id)sender
{
    [self.view endEditing:YES];
}


#pragma mark Keyboard Notifications

- (void)keyboardDidShow:(NSNotification *)notification
{
    self.isShowingKeyboard = YES;
    [self resizeTextView:notification];
    [self moveCursorIntoView];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    self.isShowingKeyboard = NO;
    [self resizeTextView:notification];
}


#pragma mark UITextView Delegate Methods

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.textPromptLabel.hidden = YES;
}

- (void)textViewDidEndEditing:(UITextView *)aTextView
{
    if ([_textView.text isEqualToString:@""]) {
        self.textPromptLabel.hidden = NO;
    }
}

@end
