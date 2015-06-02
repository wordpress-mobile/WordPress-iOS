#import "WPLegacyEditPostViewController.h"
#import "WPLegacyEditPostViewController_Internal.h"
#import "ContextManager.h"
#import "Post.h"
#import "Coordinate.h"
#import "Media.h"
#import "WPTableViewCell.h"
#import "BlogSelectorViewController.h"
#import "WPBlogSelectorButton.h"
#import "LocationService.h"
#import "BlogService.h"
#import "PostService.h"
#import "MediaService.h"
#import "WPUploadStatusButton.h"
#import "WPTabBarController.h"
#import "WPMediaProgressTableViewController.h"
#import "WPPostViewController.h"
#import "WPProgressTableViewCell.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <WordPress-iOS-Shared/UIImage+Util.h>
#import <WordPress-iOS-Shared/WPFontManager.h>
#import <WPMediaPicker/WPMediaPickerViewController.h>
#import "WordPress-Swift.h"

NSString *const WPLegacyEditorNavigationRestorationID = @"WPLegacyEditorNavigationRestorationID";
NSString *const WPLegacyAbstractPostRestorationKey = @"WPLegacyAbstractPostRestorationKey";
static void *ProgressObserverContext = &ProgressObserverContext;

@interface WPLegacyEditPostViewController ()<UIPopoverControllerDelegate, WPMediaPickerViewControllerDelegate>

@property (nonatomic, strong) UIButton *titleBarButton;
@property (nonatomic, strong) UIButton *uploadStatusButton;
@property (nonatomic, strong) UIPopoverController *blogSelectorPopover;
@property (nonatomic, strong) UIPopoverController *mediaProgressPopover;
@property (nonatomic) BOOL dismissingBlogPicker;
@property (nonatomic) CGPoint scrollOffsetRestorePoint;
@property (nonatomic, strong) NSProgress * mediaGlobalProgress;
@property (nonatomic, strong) UIProgressView * mediaProgressView;
@property (nonatomic, strong) NSMutableDictionary *mediaInProgress;

@end

@implementation WPLegacyEditPostViewController

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    BOOL dontRestoreIfNewEditorIsEnabled = [WPPostViewController isNewEditorEnabled];
    
    if (dontRestoreIfNewEditorIsEnabled) {
        return nil;
    }

    if ([[identifierComponents lastObject] isEqualToString:WPLegacyEditorNavigationRestorationID]) {
        UINavigationController *navController = [[UINavigationController alloc] init];
        navController.restorationIdentifier = WPLegacyEditorNavigationRestorationID;
        navController.restorationClass = [self class];
        return navController;
    }

    NSString *postID = [coder decodeObjectForKey:WPLegacyAbstractPostRestorationKey];
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

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[[self.post.objectID URIRepresentation] absoluteString] forKey:WPLegacyAbstractPostRestorationKey];
    [super encodeRestorableStateWithCoder:coder];
}

- (void)dealloc
{
    _failedMediaAlertView.delegate = nil;
    [_mediaGlobalProgress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
    _mediaProgressPopover.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithTitle:(NSString *)title andContent:(NSString *)content andTags:(NSString *)tags andImage:(NSString *)image
{
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
            }
        }
    }
    return self;
}

- (id)initWithDraftForLastUsedBlog
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];

    Blog *blog = [blogService lastUsedOrFirstBlog];
    return [self initWithPost:[PostService createDraftPostInMainContextForBlog:blog]];
}

- (id)initWithPost:(AbstractPost *)post
{
    self = [super init];
    if (self) {
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
        _post = post;

        if (_post.remoteStatus == AbstractPostRemoteStatusLocal) {
            _editMode = EditPostViewControllerModeNewPost;
        } else {
            _editMode = EditPostViewControllerModeEditPost;
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupNavbar];
    [self createRevisionOfPost];
    [self removeIncompletelyUploadedMediaFilesAsAResultOfACrash];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self geotagNewPost];
    self.mediaInProgress = [NSMutableDictionary dictionary];
    self.mediaProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    self.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self refreshButtons];
    // setup media progress view on navbar
    [self.navigationController.navigationBar addSubview:self.mediaProgressView];
    [self.mediaProgressView setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.mediaProgressView.hidden = ![self isMediaUploading];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.mediaProgressView removeFromSuperview];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    //layout mediaProgressView 
    CGRect frame = self.mediaProgressView.frame;
    frame.size.width = self.view.frame.size.width;
    frame.origin.y = self.navigationController.navigationBar.frame.size.height-frame.size.height;
    [self.mediaProgressView setFrame:frame];
}

#pragma mark - View Setup

- (void)setupNavbar
{
    if (self.navigationItem.leftBarButtonItem == nil) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"Label for the button to close the post editor.") style:UIBarButtonItemStylePlain target:self action:@selector(cancelEditing)];
        self.navigationItem.leftBarButtonItem = cancelButton;
    }
    self.navigationItem.backBarButtonItem.title = [self editorTitle];
    self.title = [self editorTitle];

    // Configure the custom title view, or just set the navigationItem title.
    // Only show the blog selector in the nav title view if we're editing a new post
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    NSInteger blogCount = [blogService blogCountForAllAccounts];
    
    self.mediaProgressView.hidden = ![self isMediaUploading];
    if ([self isMediaUploading]) {
        [self refreshMediaProgress];
        UIButton *titleButton = self.uploadStatusButton;
        NSMutableAttributedString *titleText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", NSLocalizedString(@"Media Uploading...", @"Message to indicate progress of uploading media to server")]                                                                                      attributes:@{ NSFontAttributeName : [WPFontManager openSansBoldFontOfSize:14.0] }];
        [titleButton setAttributedTitle:titleText forState:UIControlStateNormal];
        [titleButton sizeToFit];
        if (self.navigationItem.titleView != titleButton){
            self.navigationItem.titleView = titleButton;
        }
    } else if (blogCount <= 1 || self.editMode == EditPostViewControllerModeEditPost || [[WPTabBarController sharedInstance] isNavigatingMySitesTab]) {
        self.navigationItem.titleView = nil;
        self.navigationItem.title = [self editorTitle];
    } else {
        UIButton *titleButton = self.titleBarButton;
        self.navigationItem.titleView = titleButton;
        NSMutableAttributedString *titleText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", [self editorTitle]]
                                                                                      attributes:@{ NSFontAttributeName : [WPFontManager openSansBoldFontOfSize:14.0] }];

        NSString *subtext = [self.post.blog.blogName length] == 0 ? self.post.blog.url : self.post.blog.blogName;
        NSDictionary *subtextAttributes = @{ NSFontAttributeName: [WPFontManager openSansRegularFontOfSize:10.0] };
        NSMutableAttributedString *titleSubtext = [[NSMutableAttributedString alloc] initWithString:subtext
                                                                                         attributes:subtextAttributes];
        [titleText appendAttributedString:titleSubtext];
        [titleButton setAttributedTitle:titleText forState:UIControlStateNormal];

        [titleButton sizeToFit];
    }
}

#pragma mark - Actions

- (void)showBlogSelectorPrompt
{
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

- (void)showBlogSelector
{
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
            BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];

            [blogService flagBlogAsLastUsed:blog];
            AbstractPost *newPost = [self createNewDraftForBlog:blog];
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

            NSManagedObjectContext* context = oldPost.original.managedObjectContext;
            
            [oldPost.original deleteRevision];
            [oldPost.original remove];
            
            [[ContextManager sharedInstance] saveContext:context];

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

- (Class)classForSettingsViewController
{
    return [PostSettingsViewController class];
}

#pragma mark - Post Options

- (void)showSettings
{
    Post *post = (Post *)self.post;
    UIViewController *vc = [[[self classForSettingsViewController] alloc] initWithPost:post shouldHideStatusBar:NO];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStyleBordered target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showPreview
{
    PostPreviewViewController *vc = [[PostPreviewViewController alloc] initWithPost:self.post shouldHideStatusBar:NO];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStyleBordered target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showMediaOptions
{
    WPMediaPickerViewController *picker = [[WPMediaPickerViewController alloc] init];
    picker.delegate = self;

    picker.filter = WPMediaTypeImage;

    [self presentViewController:picker animated:YES completion:nil];
}

- (void)cancelEditing
{
    if (_currentActionSheet) return;

    [self stopEditing];
    [self.postSettingsViewController endEditingAction:nil];

    if ([self isMediaUploading]) {
        [self showMediaInUploadingAlert];
        return;
    }

    if (![self.post hasUnsavedChanges]) {
        [WPAnalytics track:WPAnalyticsStatEditorClosed];
        [self discardChanges];
        [self dismissEditView];
        return;
    }

    UIActionSheet *actionSheet;
    if (![self.post.original.status isEqualToString:PostStatusDraft] && self.editMode != EditPostViewControllerModeNewPost) {
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

- (AbstractPost *)createNewDraftForBlog:(Blog *)blog {
    return [PostService createDraftPostInMainContextForBlog:blog];
}

- (void)geotagNewPost
{
    if (EditPostViewControllerModeNewPost != self.editMode) {
        return;
    }

    if (self.post.blog.geolocationEnabled && ![LocationService sharedService].locationServicesDisabled) {
        [[LocationService sharedService] getCurrentLocationAndAddress:^(CLLocation *location, NSString *address, NSError *error) {
            if (location) {
                if (self.post.isDeleted) {
                    return;
                }
                Coordinate *coord = [[Coordinate alloc] initWithCoordinate:location.coordinate];
                Post *post = (Post *)self.post;
                post.geolocation = coord;
            }
        }];
    }
}

/*
 Sync the blog if desired info is missing.

 Always sync after a blog switch to ensure options are updated. Otherwise,
 only sync for new posts when launched from the post tab vs the posts list.
 */
- (void)syncOptionsIfNecessaryForBlog:(Blog *)blog afterBlogChanged:(BOOL)blogChanged
{
    if (blogChanged) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        __block BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];

        [blogService syncBlog:blog success:^{
            blogService = nil;
        } failure:^(NSError *error) {
            blogService = nil;
        }];
    }
}

- (NSString *)editorTitle
{
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

#pragma mark - UI Manipulation

- (void)refreshButtons
{
    // Left nav button: Cancel Button
    if (self.navigationItem.leftBarButtonItem == nil) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelEditing)];
        self.navigationItem.leftBarButtonItem = cancelButton;
    }

    // Right nav button: Publish Button
    NSString *buttonTitle;
    if (![self.post hasRemote] || ![self.post.status isEqualToString:self.post.original.status]) {
        if ([self.post isScheduled]) {
            buttonTitle = NSLocalizedString(@"Schedule", @"Schedule button, this is what the Publish button changes to in the Post Editor if the post has been scheduled for posting later.");

        } else if ([self.post.status isEqualToString:PostStatusPublish]) {
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
        
        // Seems to be a bug with UIBarButtonItem respecting the UIControlStateDisabled text color
        [saveButton setTitleTextAttributes:@{NSFontAttributeName: [WPStyleGuide regularTextFont], NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
        [saveButton setTitleTextAttributes:@{NSFontAttributeName: [WPStyleGuide regularTextFont], NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.25]} forState:UIControlStateDisabled];
        self.navigationItem.rightBarButtonItem = saveButton;
    } else {
        self.navigationItem.rightBarButtonItem.title = buttonTitle;
    }

    BOOL updateEnabled = [self.post canSave];
    [self.navigationItem.rightBarButtonItem setEnabled:updateEnabled];
}

- (void)refreshUIForCurrentPost
{
    [self setupNavbar];
    self.titleText = self.post.postTitle;

    if (self.post.content == nil || [self.post.content isEmpty]) {
        self.bodyText = @"";
    } else {
        if ((self.post.mt_text_more != nil) && ([self.post.mt_text_more length] > 0)) {
            self.bodyText = [NSString stringWithFormat:@"%@\n<!--more-->\n%@", self.post.content, self.post.mt_text_more];
        } else {
            self.bodyText = self.post.content;
        }
    }
    [self refreshButtons];
}

- (UIButton *)titleBarButton
{
    if (!_titleBarButton) {
        UIButton *titleButton = [WPBlogSelectorButton buttonWithFrame:CGRectMake(0.0f, 0.0f, 200.0f, 33.0f) buttonStyle:WPBlogSelectorButtonTypeStacked];
        [titleButton addTarget:self action:@selector(showBlogSelectorPrompt) forControlEvents:UIControlEventTouchUpInside];
        _titleBarButton = titleButton;
    }
    return _titleBarButton;
}

- (UIButton *)uploadStatusButton
{
    if (!_uploadStatusButton) {
        UIButton *button = [WPBlogSelectorButton buttonWithFrame:CGRectMake(0.0f, 0.0f, 250.0f, 33.0f) buttonStyle:WPBlogSelectorButtonTypeStacked];
        [button addTarget:self action:@selector(showMediaProgress) forControlEvents:UIControlEventTouchUpInside];
        _uploadStatusButton = button;
    }
    return _uploadStatusButton;
}

# pragma mark - Model State Methods

- (void)createRevisionOfPost
{
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

// This will remove any media objects that are in the uploading status. The reason we do this is because if the editor crashes during an image upload the app
// will have an image stuck in the uploading state and the user will be unable to quit out of the app unless they remove the image by hand. In the absence of a media
// browser to see a users attached images we should remove this image from the post.
// NOTE: This is a temporary fix, long term we should explore other options such as automatically retrying after a crash
- (void)removeIncompletelyUploadedMediaFilesAsAResultOfACrash
{
    [self.post.managedObjectContext performBlock:^{
        NSMutableArray *mediaToRemove = [[NSMutableArray alloc] init];
        for (Media *media in self.post.media) {
            if (media.remoteStatus == MediaRemoteStatusPushing) {
                [mediaToRemove addObject:media];
            }
        }
        [mediaToRemove makeObjectsPerformSelector:@selector(remove)];
    }];
}

- (void)discardChanges
{
    [self.post.original deleteRevision];

    if (self.editMode == EditPostViewControllerModeNewPost) {
        NSManagedObjectContext* context = self.post.original.managedObjectContext;
        
        [self.post.original remove];
        
        [[ContextManager sharedInstance] saveContext:context];
    }
}

- (void)dismissEditView
{
    if (self.onClose) {
        self.onClose();
        self.onClose = nil;
    } else{
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)saveAction
{
    if (_currentActionSheet.isVisible) {
        [_currentActionSheet dismissWithClickedButtonIndex:-1 animated:YES];
        _currentActionSheet = nil;
    }

    if ([self isMediaUploading] ) {
        [self showMediaInUploadingAlert];
        return;
    }

    if ([self hasFailedMedia]) {
        [self showFailedMediaAlert];
        return;
    }

    [self savePost:YES];
    [self dismissEditView];
}

- (void)savePost:(BOOL)upload
{
    DDLogMethod();
    [self logSavePostStats];

    [self.view endEditing:YES];

    [self.post.original applyRevision];
    [self.post.original deleteRevision];

    if (upload) {
        NSString *postTitle = self.post.original.postTitle;
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        PostService *postService = [[PostService alloc] initWithManagedObjectContext:context];
        [postService uploadPost:(Post *)self.post.original
                        success:^{
                            DDLogInfo(@"post uploaded: %@", postTitle);
                        } failure:^(NSError *error) {
                            DDLogError(@"post failed: %@", [error localizedDescription]);
                        }];
    }

    [self didSaveNewPost];
}

- (void)didSaveNewPost
{
    if (_editMode == EditPostViewControllerModeNewPost) {
        [[WPTabBarController sharedInstance] switchTabToPostsListForPost:self.post];
    }
}

- (void)logSavePostStats
{
    NSString *buttonTitle = self.navigationItem.rightBarButtonItem.title;

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

    NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithCapacity:2];
    properties[@"word_count"] = @(wordCount);
    if ([self.post hasRemote]) {
        properties[@"word_diff_count"] = @(wordCount - originalWordCount);
    }

    if ([buttonTitle isEqualToString:NSLocalizedString(@"Publish", nil)]) {
        [WPAnalytics track:WPAnalyticsStatEditorPublishedPost withProperties:properties];

        if ([self.post hasPhoto]) {
            [WPAnalytics track:WPAnalyticsStatPublishedPostWithPhoto];
        }

        if ([self.post hasVideo]) {
            [WPAnalytics track:WPAnalyticsStatPublishedPostWithVideo];
        }

        if ([self.post hasCategories]) {
            [WPAnalytics track:WPAnalyticsStatPublishedPostWithCategories];
        }

        if ([self.post hasTags]) {
            [WPAnalytics track:WPAnalyticsStatPublishedPostWithTags];
        }
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Schedule", nil)]) {
        [WPAnalytics track:WPAnalyticsStatEditorScheduledPost withProperties:properties];
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Save", nil)]) {
        [WPAnalytics track:WPAnalyticsStatEditorSavedDraft];
    } else {
        [WPAnalytics track:WPAnalyticsStatEditorUpdatedPost withProperties:properties];
    }
}

// Save changes to core data
- (void)autosaveContent
{
    self.post.postTitle = self.titleText;
    self.navigationItem.title = [self editorTitle];

    self.post.content = self.bodyText;
    if ([self.post.content rangeOfString:@"<!--more-->"].location != NSNotFound) {
        self.post.mt_text_more = @"";
    }

    if ( self.post.original.password != nil ) { //original post was password protected
        if ( self.post.password == nil || [self.post.password isEqualToString:@""] ) { //removed the password
            self.post.password = @"";
        }
    }

    [self.post save];
}

#pragma mark - Media State Methods

- (NSString*)uniqueIdForMedia
{
    NSUUID * uuid = [[NSUUID alloc] init];
    return [uuid UUIDString];
}

- (void)refreshMediaProgress
{
    self.mediaProgressView.hidden = ![self isMediaUploading];
    float fractionOfUploadsCompleted = (float)(self.mediaGlobalProgress.completedUnitCount+1)/(float)self.mediaGlobalProgress.totalUnitCount;
    self.mediaProgressView.progress = MIN(fractionOfUploadsCompleted ,self.mediaGlobalProgress.fractionCompleted);
}

- (void)showMediaProgress
{
    if (IS_IPAD && self.blogSelectorPopover.isPopoverVisible) {
        [self.blogSelectorPopover dismissPopoverAnimated:YES];
        self.blogSelectorPopover = nil;
    }
    
    WPMediaProgressTableViewController *vc = [[WPMediaProgressTableViewController alloc] initWithMasterProgress:self.mediaGlobalProgress childrenProgress:self.mediaInProgress.allValues];
    
    vc.title = NSLocalizedString(@"Media Uploading", @"Title for view that shows progress of multiple uploads");
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    navController.navigationBar.translucent = NO;
    navController.navigationBar.barStyle = UIBarStyleBlack;
    
    if (IS_IPAD) {
        vc.preferredContentSize = CGSizeMake(320.0, 500);
        
        CGRect titleRect = self.navigationItem.titleView.frame;
        titleRect = [self.navigationController.view convertRect:titleRect fromView:self.navigationItem.titleView.superview];
        
        self.mediaProgressPopover = [[UIPopoverController alloc] initWithContentViewController:navController];
        self.mediaProgressPopover.delegate = self;
        [self.mediaProgressPopover presentPopoverFromRect:titleRect inView:self.navigationController.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        
    } else {
        navController.modalPresentationStyle = UIModalPresentationPageSheet;
        navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
        [self presentViewController:navController animated:YES completion:nil];
    }
}

- (void)showCancelMediaUploadPrompt
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cancel Media Uploads", @"Title for alert for cancelling all uploads") message:NSLocalizedString(@"This will stop the current media uploads in progress. Are you sure you want to proceed?", @"This is displayed if the user taps the uploading text in the post editor") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
    alertView.tag = EditPostViewControllerAlertCancelMediaUpload;
    [alertView show];
}

- (void)showFailedMediaAlert
{
    if (_failedMediaAlertView) {
        return;
    }

    _failedMediaAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Pending media", @"Title for alert when trying to publish a post with failed media items")
                                                       message:NSLocalizedString(@"There are media items in this post that aren't uploaded to the server. Do you want to continue?", @"")
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"No", @"")
                                             otherButtonTitles:NSLocalizedString(@"Post anyway", @""), nil];
    _failedMediaAlertView.tag = EditPostViewControllerAlertTagFailedMedia;
    [_failedMediaAlertView show];
}

- (void)showMediaInUploadingAlert
{
    //the post is using the network connection and cannot be stoped, show a message to the user
    UIAlertView *blogIsCurrentlyBusy = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Info", @"Info alert title")
                                                                  message:NSLocalizedString(@"A Media file is currently uploading. Please try later.", @"")
                                                                 delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
    [blogIsCurrentlyBusy show];
}

- (BOOL)hasFailedMedia
{
    for(NSProgress * progress in self.mediaInProgress.allValues) {
        if (progress.totalUnitCount == 0){
            return YES;
        }
    }
    return NO;
}

- (BOOL)isMediaUploading
{
    for(NSProgress * progress in self.mediaInProgress.allValues) {
        if (progress.totalUnitCount != 0){
            return YES;
        }
    }
    return NO;
}

- (void)cancelMediaUploads
{
    [self.mediaGlobalProgress cancel];
    NSMutableArray * keys = [NSMutableArray array];
    [self.mediaInProgress enumerateKeysAndObjectsUsingBlock:^(NSString * key, NSProgress * progress, BOOL *stop) {
        if (progress.isCancelled){
            [keys addObject:key];
        }
    }];
    [self.mediaInProgress removeObjectsForKeys:keys];
    [self autosaveContent];
    [self setupNavbar];
}

- (void)cancelUploadOfMediaWithId:(NSString *)uniqueMediaId
{
    NSProgress * progress = self.mediaInProgress[uniqueMediaId];
    if (!progress) {
        return;
    }
    [progress cancel];
}

- (void)removeAllFailedMedia
{
    NSMutableArray * keys = [NSMutableArray array];
    [self.mediaInProgress enumerateKeysAndObjectsUsingBlock:^(NSString * key, NSProgress * progress, BOOL *stop) {
        if (progress.totalUnitCount == 0){
            [keys addObject:key];
        }
    }];
    [self.mediaInProgress removeObjectsForKeys:keys];
    [self autosaveContent];
}

- (void)stopTrackingProgressOfMediaWithId:(NSString *)uniqueMediaId
{
    NSParameterAssert(uniqueMediaId != nil);
    if (!uniqueMediaId) {
        return;
    }
    NSProgress * progress = self.mediaInProgress[uniqueMediaId];
    [self.mediaInProgress removeObjectForKey:uniqueMediaId];
    if (progress.isCancelled){
        //on iOS 7 cancelled sub progress don't update the parent progress properly so we need to do it
        if ( ![UIDevice isOS8] ) {
            self.mediaGlobalProgress.completedUnitCount++;
        }
    }
}

- (void)trackMediaWithId:(NSString *)uniqueMediaId usingProgress:(NSProgress *)progress
{
    NSParameterAssert(uniqueMediaId != nil);
    if (!uniqueMediaId) {
        return;
    }
    
    self.mediaInProgress[uniqueMediaId] = progress;
}

- (void)prepareMediaProgressForNumberOfAssets:(NSUInteger)count
{
    if (self.mediaGlobalProgress.isCancelled ||
        self.mediaGlobalProgress.completedUnitCount >= self.mediaGlobalProgress.totalUnitCount){
        [self.mediaGlobalProgress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
        self.mediaGlobalProgress = nil;
    }
    
    if (!self.mediaGlobalProgress){
        self.mediaGlobalProgress = [[NSProgress alloc] initWithParent:[NSProgress currentProgress]
                                                             userInfo:nil];
        self.mediaGlobalProgress.totalUnitCount = count;
        [self.mediaGlobalProgress addObserver:self
                                   forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                                      options:NSKeyValueObservingOptionInitial
                                      context:ProgressObserverContext];
    } else {
        self.mediaGlobalProgress.totalUnitCount += count;
    }
}

- (void) addMediaAssets:(NSArray *)assets
{
    [self prepareMediaProgressForNumberOfAssets:assets.count];

    for (ALAsset *asset in assets) {
        if ([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
            MediaService *mediaService = [[MediaService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
            __weak __typeof__(self) weakSelf = self;
            NSString* imageUniqueId = [self uniqueIdForMedia];
            NSProgress *createMediaProgress = [[NSProgress alloc] initWithParent:nil userInfo:nil];
            createMediaProgress.totalUnitCount = 2;
            [self trackMediaWithId:imageUniqueId usingProgress:createMediaProgress];
            
            [mediaService createMediaWithAsset:asset forPostObjectID:self.post.objectID completion:^(Media *media, NSError * error) {
                if (error){
                    [WPError showAlertWithTitle:NSLocalizedString(@"Failed to export media", @"The title for an alert that says to the user the media (image or video) he selected couldn't be used on the post.") message:error.localizedDescription];
                    return;
                }
                __typeof__(self) strongSelf = weakSelf;
                if (!strongSelf) {
                    return;
                }
                createMediaProgress.completedUnitCount++;
                
                [strongSelf.mediaGlobalProgress becomeCurrentWithPendingUnitCount:1];
                NSProgress *uploadProgress = nil;
                [mediaService uploadMedia:media progress:&uploadProgress success:^{
                    [strongSelf insertMedia:media];
                    [strongSelf stopTrackingProgressOfMediaWithId:imageUniqueId];
                } failure:^(NSError *error) {
                    // the progress was completed event if it was an error state
                    strongSelf.mediaGlobalProgress.completedUnitCount++;
                    [strongSelf stopTrackingProgressOfMediaWithId:imageUniqueId];
                    if (error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled) {
                        DDLogWarn(@"Media uploader failed with cancelled upload: %@", error.localizedDescription);
                        return;
                    }
                    [WPError showAlertWithTitle:NSLocalizedString(@"Media upload failed", @"The title for an alert that says to the user the media (image or video) failed to be uploaded to the server.") message:error.localizedDescription];
                }];
                UIImage * image = [UIImage imageWithCGImage:asset.thumbnail];
                [uploadProgress setUserInfoObject:image forKey:WPProgressImageThumbnailKey];
                uploadProgress.kind = NSProgressKindFile;
                [uploadProgress setUserInfoObject:NSProgressFileOperationKindCopying forKey:NSProgressFileOperationKindKey];
                [strongSelf trackMediaWithId:imageUniqueId usingProgress:uploadProgress];
                [strongSelf.mediaGlobalProgress resignCurrent];
            }];
        }
    }
    // Need to refresh the post object. If we didn't, self.post.media would appear
    // to be unchanged causing the Media State Methods to fail.
    [self.post.managedObjectContext refreshObject:self.post mergeChanges:YES];
}
- (void)insertMediaBelow:(NSNotification *)notification
{
    Media *media = (Media *)[notification object];
    [self insertMedia:media];
}

- (void)insertMedia:(Media *)media
{
    [WPAnalytics track:WPAnalyticsStatEditorAddedPhotoViaLocalLibrary];
    
    NSString *prefix = @"<br /><br />";

    if (self.post.content == nil || [self.post.content isEqualToString:@""]) {
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
    } else {
        if (imgHTMLPre.location != NSNotFound) {
            [content replaceCharactersInRange:imgHTMLPre withString:@""];
        } else if (imgHTMLPost.location != NSNotFound) {
            [content replaceCharactersInRange:imgHTMLPost withString:@""];
        } else {
            [content replaceCharactersInRange:imgHTML withString:@""];
        }

        [content appendString:[NSString stringWithFormat:@"<br /><br />%@", media.html]];
        self.post.content = content;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshUIForCurrentPost];
    });
    [self.post save];
}

- (void)removeMedia:(NSNotification *)notification
{
    //remove the html string for the media object
    Media *media = (Media *)[notification object];
    self.titleText = [self removeMedia:media fromString:self.titleText];
    [self autosaveContent];
    [self refreshUIForCurrentPost];
}

- (NSString *)removeMedia:(Media *)media fromString:(NSString *)string
{
    string = [string stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"<br /><br />%@", media.html] withString:@""];
    string = [string stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@<br /><br />", media.html] withString:@""];
    string = [string stringByReplacingOccurrencesOfString:media.html withString:@""];

    return string;
}

#pragma mark - UIPopoverControllerDelegate methods

- (void)popoverController:(UIPopoverController *)popoverController
    willRepositionPopoverToRect:(inout CGRect *)rect
                   inView:(inout UIView **)view
{
    if (popoverController == self.blogSelectorPopover) {
        CGRect titleRect = self.navigationItem.titleView.frame;
        titleRect = [self.navigationController.view convertRect:titleRect fromView:self.navigationItem.titleView.superview];

        *view = self.navigationController.view;
        *rect = titleRect;
    }
}

#pragma mark - AlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == EditPostViewControllerAlertTagFailedMedia) {
        if (buttonIndex == 1) {
            DDLogInfo(@"Saving post even after some media failed to upload");
            [self savePost:YES];
            [self dismissEditView];
        }
        _failedMediaAlertView = nil;
    } else if (alertView.tag == EditPostViewControllerAlertTagSwitchBlogs) {
        if (buttonIndex == 1) {
            [self showBlogSelector];
        }
    } else if (alertView.tag == EditPostViewControllerAlertCancelMediaUpload) {
        if (buttonIndex == 1) {
            [self cancelMediaUploads];
        }
    }
    return;
}

#pragma mark - ActionSheet Delegate Methods

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet
{
    _currentActionSheet = actionSheet;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ([actionSheet tag] == 201) {
        // Discard
        if (buttonIndex == 0) {
            [self discardChanges];
            [self dismissEditView];
            [WPAnalytics track:WPAnalyticsStatEditorDiscardedChanges];
        }
        
        if (buttonIndex == 1) {
            // Cancel / Keep editing
            if ([actionSheet numberOfButtons] == 2) {
                [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
            } else {
                // Save draft
                // If you tapped on a button labeled "Save Draft", you probably expect the post to be saved as a draft
                if (![self.post hasRemote] && [self.post.status isEqualToString:PostStatusPublish]) {
                    self.post.status = PostStatusDraft;
                }
                DDLogInfo(@"Saving post as a draft after user initially attempted to cancel");
                [self savePost:YES];
                [self dismissEditView];
            }
        }
    }
    _currentActionSheet = nil;
}

#pragma mark - WPLegacyEditorViewControllerDelegate delegate

- (BOOL)editorShouldBeginEditing:(WPLegacyEditorViewController *)editorController
{
    self.post.postTitle = self.titleText;
    self.navigationItem.title = [self editorTitle];

    [self refreshButtons];
    return YES;
}

- (void)editorTitleDidChange:(WPLegacyEditorViewController *)editorController
{
    [self autosaveContent];
    [self refreshButtons];
}

- (void)editorTextDidChange:(WPLegacyEditorViewController *)editorController
{
    [self autosaveContent];
    [self refreshButtons];
}

- (void)editorDidPressSettings:(WPLegacyEditorViewController *)editorController
{
    [self showSettings];
}

- (void)editorDidPressMedia:(WPLegacyEditorViewController *)editorController
{
    [self showMediaOptions];
}

- (void)editorDidPressPreview:(WPLegacyEditorViewController *)editorController
{
    [self showPreview];
}

#pragma mark - WPMediaPickerViewController delegate

- (void)mediaPickerController:(WPMediaPickerViewController *)picker didFinishPickingAssets:(NSArray *)assets
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self addMediaAssets:assets];
    }];
}

- (BOOL)mediaPickerController:(WPMediaPickerViewController *)picker shouldSelectAsset:(ALAsset *)asset
{
    if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypePhoto) {
        // If the image is from a shared photo stream it may not be available locally to be used
        if (!asset.defaultRepresentation) {
            [WPError showAlertWithTitle:NSLocalizedString(@"Image unavailable", @"The title for an alert that says the image the user selected isn't available.")
                                message:NSLocalizedString(@"This Photo Stream image cannot be added to your WordPress. Try saving it to your Camera Roll before uploading.", @"User information explaining that the image is not available locally. This is normally related to share photo stream images.")  withSupportButton:NO];
            return NO;
        }
        return YES;
    }

    return YES;
}

- (void)mediaPickerControllerDidCancel:(WPMediaPickerViewController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == ProgressObserverContext && object == self.mediaGlobalProgress) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self setupNavbar];
        }];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
