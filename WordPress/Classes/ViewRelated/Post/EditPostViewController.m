#import "EditPostViewController.h"
#import "EditPostViewController_Internal.h"
#import "ContextManager.h"
#import "Post.h"
#import "WPTableViewCell.h"
#import "BlogSelectorViewController.h"
#import "WPBlogSelectorButton.h"
#import "LocationService.h"
#import "BlogService.h"
#import "MediaService.h"
#import "WPMediaUploader.h"
#import "WPUploadStatusView.h"
#import <AssetsLibrary/AssetsLibrary.h>

NSString *const WPEditorNavigationRestorationID = @"WPEditorNavigationRestorationID";
NSString *const WPAbstractPostRestorationKey = @"WPAbstractPostRestorationKey";

@interface EditPostViewController ()<UIPopoverControllerDelegate> {
    NSOperationQueue *_mediaUploadQueue;
}

@property (nonatomic, strong) UIButton *titleBarButton;
@property (nonatomic, strong) UIView *uploadStatusView;
@property (nonatomic, strong) UIPopoverController *blogSelectorPopover;
@property (nonatomic) BOOL dismissingBlogPicker;
@property (nonatomic) CGPoint scrollOffsetRestorePoint;

@end

@implementation EditPostViewController

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    
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

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[[self.post.objectID URIRepresentation] absoluteString] forKey:WPAbstractPostRestorationKey];
    [super encodeRestorableStateWithCoder:coder];
}


- (void)dealloc
{
    _failedMediaAlertView.delegate = nil;
    [_mediaUploadQueue removeObserver:self forKeyPath:@"operationCount"];
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
            } else {
                // Assume image as base64 encoded string.
                // TODO: Wrangle a base64 encoded image.
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
    return [self initWithPost:[Post newDraftForBlog:blog]];
}

- (id)initWithPost:(AbstractPost *)post
{
    self = [super init];
    if (self) {
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
        _post = post;
        [self configureMediaUploadQueue];

        if (_post.remoteStatus == AbstractPostRemoteStatusLocal) {
            _editMode = EditPostViewControllerModeNewPost;
        } else {
            _editMode = EditPostViewControllerModeEditPost;
        }
    }
    return self;
}

- (void)configureMediaUploadQueue
{
    _mediaUploadQueue = [NSOperationQueue new];
    _mediaUploadQueue.maxConcurrentOperationCount = 4;
    [_mediaUploadQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupNavbar];
    [self createRevisionOfPost];
    [self removeIncompletelyUploadedMediaFilesAsAResultOfACrash];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(insertMediaBelow:) name:MediaShouldInsertBelowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeMedia:) name:@"ShouldRemoveMedia" object:nil];
    
    [self geotagNewPost];
    self.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [self refreshButtons];
}

#pragma mark - View Setup

- (void)setupNavbar {
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
    
    if (_mediaUploadQueue.operationCount > 0) {
        self.navigationItem.titleView = self.uploadStatusView;
    } else if(blogCount <= 1 || self.editMode == EditPostViewControllerModeEditPost || [[WordPressAppDelegate sharedWordPressApplicationDelegate] isNavigatingMeTab]) {
        self.navigationItem.title = [self editorTitle];
    } else {
        UIButton *titleButton = self.titleBarButton;
        self.navigationItem.titleView = titleButton;
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

- (void)showCancelMediaUploadPrompt
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cancel Media Uploads", nil) message:NSLocalizedString(@"This will stop the current media uploads in progress. Are you sure you want to proceed?", @"This is displayed if the user taps the uploading text in the post editor") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
    alertView.tag = EditPostViewControllerAlertCancelMediaUpload;
    [alertView show];
}

- (void)cancelMediaUploads
{
    [_mediaUploadQueue cancelAllOperations];
}

- (void)showSettings
{
    Post *post = (Post *)self.post;
    PostSettingsViewController *vc = [[[self classForSettingsViewController] alloc] initWithPost:post];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStyleBordered target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showPreview
{
    PostPreviewViewController *vc = [[PostPreviewViewController alloc] initWithPost:self.post];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStyleBordered target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showMediaOptions
{
    CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
	picker.delegate = self;
    
    // Only show photos for now (not videos)
    picker.assetsFilter = [ALAssetsFilter allPhotos];
    
    [self presentViewController:picker animated:YES completion:nil];
    picker.navigationBar.translucent = NO;
}

- (void)cancelEditing
{
    if(_currentActionSheet) return;
    
    [self stopEditing];
    [self.postSettingsViewController endEditingAction:nil];
    
	if ([self isMediaInUploading]) {
		[self showMediaInUploadingAlert];
		return;
	}
    
    if (![self hasChanges]) {
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

- (BOOL)hasChanges
{
    return [self.post hasChanged];
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

- (void)refreshUIForCurrentPost
{
    [self setupNavbar];
    self.titleText = self.post.postTitle;
    
    if(self.post.content == nil || [self.post.content isEmpty]) {
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
    
    return _titleBarButton;
}

- (UIView *)uploadStatusView
{
    if (_uploadStatusView) {
        return _uploadStatusView;
    }
    WPUploadStatusView *uploadStatusView = [[WPUploadStatusView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 33.0)];
    uploadStatusView.tappedView = ^{
        [self showCancelMediaUploadPrompt];
    };
    _uploadStatusView = uploadStatusView;
    return _uploadStatusView;
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

- (void)discardChangesAndDismiss
{
    [self.post.original deleteRevision];
    
    if (self.editMode == EditPostViewControllerModeNewPost) {
        [self.post.original remove];
    }
    
    [self dismissEditView];
}

- (void)dismissEditView
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)saveAction
{
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

- (void)savePost:(BOOL)upload
{
    DDLogMethod();
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

- (void)didSaveNewPost
{
    if (_editMode == EditPostViewControllerModeNewPost) {
        [[WordPressAppDelegate sharedWordPressApplicationDelegate] switchTabToPostsListForPost:self.post];
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
	if ([self.post.content rangeOfString:@"<!--more-->"].location != NSNotFound)
		self.post.mt_text_more = @"";
    
    if ( self.post.original.password != nil ) { //original post was password protected
        if ( self.post.password == nil || [self.post.password isEqualToString:@""] ) { //removed the password
            self.post.password = @"";
        }
    }
    
    [self.post save];
}

#pragma mark - Media State Methods

- (BOOL)hasFailedMedia
{
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
- (BOOL)isMediaInUploading
{
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

- (void)showFailedMediaAlert
{
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

- (void)showMediaInUploadingAlert
{
	//the post is using the network connection and cannot be stoped, show a message to the user
	UIAlertView *blogIsCurrentlyBusy = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Info", @"Info alert title")
																  message:NSLocalizedString(@"A Media file is currently uploading. Please try later.", @"")
																 delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
	[blogIsCurrentlyBusy show];
}

#pragma mark - Media Formatting

- (void)insertMediaBelow:(NSNotification *)notification
{
	Media *media = (Media *)[notification object];
    [self insertMedia:media];
}

- (void)insertMedia:(Media *)media
{
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

- (void)popoverController:(UIPopoverController *)popoverController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView **)view {
    if (popoverController == self.blogSelectorPopover) {
        CGRect titleRect = self.navigationItem.titleView.frame;
        titleRect = [self.navigationController.view convertRect:titleRect fromView:self.navigationItem.titleView.superview];
        
        *view = self.navigationController.view;
        *rect = titleRect;
    }
}

#pragma mark - AlertView Delegate Methods

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
    } else if (alertView.tag == EditPostViewControllerAlertCancelMediaUpload) {
        if (buttonIndex == 1) {
            [self cancelMediaUploads];
        }
    }
    return;
}

#pragma mark - ActionSheet Delegate Methods

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
            [self discardChangesAndDismiss];
        }
        
        if (buttonIndex == 1) {
            // Cancel / Keep editing
			if ([actionSheet numberOfButtons] == 2) {
                
				[actionSheet dismissWithClickedButtonIndex:0 animated:YES];
                // Save draft
			} else {
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

#pragma mark - WPEditorViewControllerDelegate delegate

- (BOOL)editorShouldBeginEditing:(WPEditorViewController *)editorController
{
    self.post.postTitle = self.titleText;
    self.navigationItem.title = [self editorTitle];
    
    [self refreshButtons];
    return YES;
}

- (void)editorTitleDidChange:(WPEditorViewController *)editorController
{
    [self autosaveContent];
    [self refreshButtons];
}

- (void)editorTextDidChange:(WPEditorViewController *)editorController
{
    [self autosaveContent];
    [self refreshButtons];
}

- (void)editorDidPressSettings:(WPEditorViewController *)editorController
{
    [self showSettings];
}

- (void)editorDidPressMedia:(WPEditorViewController *)editorController
{
    [self showMediaOptions];
}

- (void)editorDidPressPreview:(WPEditorViewController *)editorController
{
    [self showPreview];
}

#pragma mark - CTAssetsPickerController delegate

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    for (ALAsset *asset in assets) {
        if ([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
            // Could handle videos here
        } else if ([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
            MediaService *mediaService = [[MediaService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
            [mediaService createMediaWithAsset:asset forPostObjectID:self.post.objectID completion:^(Media *media) {
                AFHTTPRequestOperation *operation = [mediaService operationToUploadMedia:media withSuccess:^{
                    [self insertMedia:media];
                } failure:^(NSError *error) {
                    if (error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled) {
                        DDLogWarn(@"Media uploader failed with cancelled upload: %@", error.localizedDescription);
                        return;
                    }

                    [WPError showAlertWithTitle:NSLocalizedString(@"Upload failed", nil) message:error.localizedDescription];
                }];
                [_mediaUploadQueue addOperation:operation];
            }];
        }
    }
    [self setupNavbar];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:_mediaUploadQueue]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupNavbar];
        });
    }
}

@end
