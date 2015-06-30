#import "WPPostViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <WordPress-iOS-Editor/WPEditorField.h>
#import <WordPress-iOS-Editor/WPEditorView.h>
#import <WordPress-iOS-Shared/NSString+Util.h>
#import <WordPress-iOS-Shared/UIImage+Util.h>
#import <WordPress-iOS-Shared/WPFontManager.h>
#import <WordPress-iOS-Shared/WPStyleGuide.h>
#import <WordPressCom-Analytics-iOS/WPAnalytics.h>
#import <SVProgressHUD.h>
#import <WPMediaPicker/WPMediaPickerViewController.h>
#import "BlogSelectorViewController.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "Coordinate.h"
#import "EditImageDetailsViewController.h"
#import "LocationService.h"
#import "Media.h"
#import "MediaService.h"
#import "NSString+Helpers.h"
#import "Post.h"
#import "PostPreviewViewController.h"
#import "PostService.h"
#import "PostSettingsViewController.h"
#import "PrivateSiteURLProtocol.h"
#import "WordPressAppDelegate.h"
#import "WPButtonForNavigationBar.h"
#import "WPBlogSelectorButton.h"
#import "WPButtonForNavigationBar.h"
#import "WPMediaProgressTableViewController.h"
#import "WPProgressTableViewCell.h"
#import "WPTableViewCell.h"
#import "WPTabBarController.h"
#import "WPUploadStatusButton.h"
#import "WordPress-Swift.h"
#import "WPTooltip.h"

typedef NS_ENUM(NSInteger, EditPostViewControllerAlertTag) {
    EditPostViewControllerAlertTagNone,
    EditPostViewControllerAlertTagLinkHelper,
    EditPostViewControllerAlertTagFailedMedia,
    EditPostViewControllerAlertTagFailedMediaBeforeEdit,
    EditPostViewControllerAlertTagFailedMediaBeforeSave,
    EditPostViewControllerAlertTagSwitchBlogs,
    EditPostViewControllerAlertCancelMediaUpload,
};

// State Restoration
NSString* const WPEditorNavigationRestorationID = @"WPEditorNavigationRestorationID";
static NSString* const WPPostViewControllerEditModeRestorationKey = @"WPPostViewControllerEditModeRestorationKey";
static NSString* const WPPostViewControllerOwnsPostRestorationKey = @"WPPostViewControllerOwnsPostRestorationKey";
static NSString* const WPPostViewControllerPostRestorationKey = @"WPPostViewControllerPostRestorationKey";
static NSString* const WPProgressMediaID = @"WPProgressMediaID";
static NSString* const WPProgressMedia = @"WPProgressMedia";

NSString* const kUserDefaultsNewEditorAvailable = @"kUserDefaultsNewEditorAvailable";
NSString* const kUserDefaultsNewEditorEnabled = @"kUserDefaultsNewEditorEnabled";
NSString* const OnboardingWasShown = @"OnboardingWasShown";

const CGRect NavigationBarButtonRect = {
    .origin.x = 0.0f,
    .origin.y = 0.0f,
    .size.width = 30.0f,
    .size.height = 30.0f
};

// Secret URL config parameters
NSString *const kWPEditorConfigURLParamAvailable = @"available";
NSString *const kWPEditorConfigURLParamEnabled = @"enabled";

NS_ENUM(NSUInteger, WPPostViewControllerActionSheet) {
    WPPostViewControllerActionSheetSaveOnExit = 201,
    WPPostViewControllerActionSheetCancelUpload = 202,
    WPPostViewControllerActionSheetRetryUpload = 203,
    WPPostViewControllerActionSheetCancelVideoUpload = 204,
    WPPostViewControllerActionSheetRetryVideoUpload = 205
};

static CGFloat const SpacingBetweeenNavbarButtons = 20.0f;
static CGFloat const RightSpacingOnExitNavbarButton = 5.0f;
static NSDictionary *DisabledButtonBarStyle;
static NSDictionary *EnabledButtonBarStyle;

static void *ProgressObserverContext = &ProgressObserverContext;
@interface WPPostViewController () <
WPMediaPickerViewControllerDelegate,
UIActionSheetDelegate,
UIPopoverControllerDelegate,
UITextFieldDelegate,
UITextViewDelegate,
UIViewControllerRestoration,
EditImageDetailsViewControllerDelegate
>

#pragma mark - Misc properties
@property (nonatomic, strong) UIButton *blogPickerButton;
@property (nonatomic, strong) UIBarButtonItem *uploadStatusButton;
@property (nonatomic, strong) UIPopoverController *blogSelectorPopover;
@property (nonatomic) BOOL dismissingBlogPicker;
@property (nonatomic) CGPoint scrollOffsetRestorePoint;
@property (nonatomic, strong) NSProgress * mediaGlobalProgress;
@property (nonatomic, strong) NSMutableDictionary *mediaInProgress;
@property (nonatomic, strong) UIProgressView *mediaProgressView;
@property (nonatomic, strong) NSString * selectedMediaID;

#pragma mark - Bar Button Items
@property (nonatomic, strong) UIBarButtonItem *secondaryLeftUIBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *negativeSeparator;
@property (nonatomic, strong) UIBarButtonItem *cancelXButton;
@property (nonatomic, strong) UIBarButtonItem *cancelChevronButton;
@property (nonatomic, strong) UIBarButtonItem *currentCancelButton;
@property (nonatomic, strong) UIBarButtonItem *editBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *saveBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *previewBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *optionsBarButtonItem;

#pragma mark - Post info
@property (nonatomic, assign, readwrite) BOOL ownsPost;

#pragma mark - Unsaved changes support
@property (nonatomic, assign, readonly) BOOL changedToEditModeDueToUnsavedChanges;

#pragma mark - State restoration
/**
 *  @brief      In failed state restoration, this VC will be restored empty and closed immediately.
 *  @details    The reason why this VC will be restored and closed, as opposed to not restored at
 *              all is that we have no way of preventing the restoration of this VC's parent
 *              navigation controller.  Restoring this VC and closing it means the parent nav
 *              controller will be closed too.
 */
@property (nonatomic, assign, readwrite) BOOL failedStateRestorationMode;
@end

@implementation WPPostViewController

#pragma mark - Dealloc

- (void)dealloc
{
    _failedMediaAlertView.delegate = nil;
    [_mediaGlobalProgress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
    [PrivateSiteURLProtocol unregisterPrivateSiteURLProtocol];
}

#pragma mark - Initializers

- (instancetype)initInFailedStateRestorationMode
{
    self = [super init];
    
    if (self) {
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
        self.hidesBottomBarWhenPushed = YES;
        
        _failedStateRestorationMode = YES;
    }
    
    return self;
}

- (instancetype)initWithDraftForLastUsedBlog
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];

    Blog *blog = [blogService lastUsedOrFirstBlog];
    NSAssert([blog isKindOfClass:[Blog class]],
             @"There should be no issues in obtaining the last used blog.");
    
    [self syncOptionsIfNecessaryForBlog:blog afterBlogChanged:YES];

    return [self initWithDraftForBlog:blog];
}

- (instancetype)initWithDraftForBlog:(Blog*)blog
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    
    AbstractPost *post = [self createNewDraftForBlog:blog];
    NSAssert([post isKindOfClass:[AbstractPost class]],
             @"There should be no issues in creating a draft post.");
    
    if (self = [self initWithPost:post mode:kWPPostViewControllerModeEdit]) {
        _ownsPost = YES;
    }
    
    return self;
}

- (instancetype)initWithPost:(AbstractPost *)post
{
    NSParameterAssert([post isKindOfClass:[Post class]]);
    
    return [self initWithPost:post
                         mode:kWPPostViewControllerModePreview];
}

- (instancetype)initWithPost:(AbstractPost *)post
                        mode:(WPPostViewControllerMode)mode
{
    BOOL changeToEditModeDueToUnsavedChanges = (mode == kWPEditorViewControllerModePreview
                                                && [post hasUnsavedChanges]);
    
    if (changeToEditModeDueToUnsavedChanges) {
        mode = kWPEditorViewControllerModeEdit;
    }
    
    self = [super initWithMode:mode];
	
    if (self) {
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
        self.hidesBottomBarWhenPushed = YES;
        
        _changedToEditModeDueToUnsavedChanges = changeToEditModeDueToUnsavedChanges;
        _post = post;
        
        if (post.blog.isHostedAtWPcom) {
            [PrivateSiteURLProtocol registerPrivateSiteURLProtocol];
        }
    }
	
    return self;
}

- (id)initWithTitle:(NSString *)title
		 andContent:(NSString *)content
			andTags:(NSString *)tags
		   andImage:(NSString *)image
{
    self = [self initWithDraftForLastUsedBlog];
	
    if (self) {
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
        self.modalTransitionStyle = UIModalPresentationCustom;
        Post *post = (Post *)self.post;
        post.postTitle = title;
        post.content = content;
        post.tags = tags;
        
        if (image) {
            NSURL *imageURL = [NSURL URLWithString:image];
			
            if (imageURL) {
				static NSString* const kFormat = @"<a href=\"%@\"><img src=\"%@\"></a>";
				
                NSString *aimg = [NSString stringWithFormat:kFormat, [imageURL absoluteString], [imageURL absoluteString]];
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


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    DisabledButtonBarStyle = @{NSFontAttributeName: [WPStyleGuide regularTextFontSemiBold], NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.25]};
    EnabledButtonBarStyle = @{NSFontAttributeName: [WPStyleGuide regularTextFontSemiBold], NSForegroundColorAttributeName: [UIColor whiteColor]};
    
    // This is a trick to kick the starting UIButtonBarItem to the left
    self.negativeSeparator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    self.negativeSeparator.width = -12;
    
    [self removeIncompletelyUploadedMediaFilesAsAResultOfACrash];
    
    [self geotagNewPost];
    self.delegate = self;
    self.failedMediaAlertView = nil;
    [self configureMediaUpload];
    [self refreshNavigationBarButtons:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.failedStateRestorationMode) {
        [self dismissEditView];
    } else {
        [self refreshNavigationBarButtons:NO];
        [self.navigationController.navigationBar addSubview:self.mediaProgressView];
        if (self.isEditing) {
            [self setNeedsStatusBarAppearanceUpdate];
        } else {
            // Preview mode...show the onboarding hint the first time through only
            if (!self.wasOnboardingShown) {
                [self showOnboardingTips];
                [self setOnboardingShown:YES];
            }
        }
    }

    if (self.changedToEditModeDueToUnsavedChanges) {
        [self showUnsavedChangesAlert];
    }
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
    self.mediaProgressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.mediaProgressView setFrame:frame];

}

#pragma mark - UIViewControllerRestoration

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents
															coder:(NSCoder *)coder
{
    UIViewController* restoredViewController = nil;
    
    BOOL restoreOnlyIfNewEditorIsEnabled = [WPPostViewController isNewEditorEnabled];
    
    if (restoreOnlyIfNewEditorIsEnabled) {
        restoredViewController = [self restoreViewControllerWithIdentifierPath:identifierComponents
                                                                         coder:coder];
    }
    
    return restoredViewController;
}

#pragma mark - Restoration helpers

+ (UIViewController*)restoreParentNavigationController
{
    UINavigationController *navController = [[UINavigationController alloc] init];
    navController.restorationIdentifier = WPEditorNavigationRestorationID;
    navController.restorationClass = self;
    
    return navController;
}

+ (UIViewController*)restoreViewControllerWithIdentifierPath:(NSArray *)identifierComponents
                                                       coder:(NSCoder *)coder
{
    UIViewController *restoredViewController = nil;
    
    if ([self isParentNavigationControllerIdentifierPath:identifierComponents]) {
        
        restoredViewController = [self restoreParentNavigationController];
    } else if ([self isSelfIdentifierPath:identifierComponents]) {
        restoredViewController = [self restoreViewControllerWithCoder:coder];
    }
    
    return restoredViewController;
}

+ (UIViewController*)restoreViewControllerWithCoder:(NSCoder *)coder
{
    UIViewController *restoredViewController = nil;
    AbstractPost *restoredPost = [self decodePostFromCoder:coder];
    
    if (restoredPost) {
        WPPostViewControllerMode mode = [self decodeEditModeFromCoder:coder];
        
        restoredViewController = [[self alloc] initWithPost:restoredPost
                                                       mode:mode];
    } else {
        restoredViewController = [[self alloc] initInFailedStateRestorationMode];
    }
    
    return restoredViewController;
}

#pragma mark - UIViewController (UIStateRestoration)

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    BOOL ownsPost = [[self class] decodeOwnsPostFromCoder:coder];
    
    self.ownsPost = ownsPost;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [self encodeEditModeInCoder:coder];
    [self encodeOwnsPostInCoder:coder];
    [self encodePostInCoder:coder];
    
    [super encodeRestorableStateWithCoder:coder];
}

#pragma mark - State Restoration Helpers

+ (BOOL)isParentNavigationControllerIdentifierPath:(NSArray*)identifierComponents
{
    return [[identifierComponents lastObject] isEqualToString:WPEditorNavigationRestorationID];
}

+ (BOOL)isSelfIdentifierPath:(NSArray*)identifierComponents
{
    return [[identifierComponents lastObject] isEqualToString:NSStringFromClass([self class])];
}

#pragma mark - Restoration: encoding

/**
 *  @brief      Encodes the edit mode info from this VC into the specified coder.
 *
 *  @param      coder       The coder to store the information.  Cannot be nil.
 */
- (void)encodeEditModeInCoder:(NSCoder*)coder
{
    BOOL isInEditMode = self.isEditing;
    
    [coder encodeBool:isInEditMode forKey:WPPostViewControllerEditModeRestorationKey];
}

/**
 *  @brief      Encodes the ownsPost property from this VC into the specified coder.
 *
 *  @param      coder       The coder to store the information.  Cannot be nil.
 */
- (void)encodeOwnsPostInCoder:(NSCoder*)coder
{
    BOOL ownsPost = self.ownsPost;
    
    [coder encodeBool:ownsPost forKey:WPPostViewControllerOwnsPostRestorationKey];
}

/**
 *  @brief      Encodes the post ID info from this VC into the specified coder.
 *
 *  @param      coder       The coder to store the information.  Cannot be nil.
 */
- (void)encodePostInCoder:(NSCoder*)coder
{
    NSURL* postURIRepresentation = [self.post.objectID URIRepresentation];
    [coder encodeObject:postURIRepresentation forKey:WPPostViewControllerPostRestorationKey];
}

#pragma mark - Restoration: decoding

/**
 *  @brief      Obtains the edit mode for this VC from the specified coder.
 *
 *  @param      coder       The coder to retrieve the information from.  Cannot be nil.
 *
 *  @return     The edit mode stored in the coder.
 */
+ (WPPostViewControllerMode)decodeEditModeFromCoder:(NSCoder*)coder
{
    NSParameterAssert([coder isKindOfClass:[NSCoder class]]);
    
    BOOL isInEditMode = [coder decodeBoolForKey:WPPostViewControllerEditModeRestorationKey];
    
    WPPostViewControllerMode mode = kWPEditorViewControllerModePreview;
    
    if (isInEditMode) {
        mode = kWPEditorViewControllerModeEdit;
    }
    
    return mode;
}

/**
 *  @brief      Obtains the ownsPost property for this VC from the specified coder.
 *
 *  @param      coder       The coder to retrieve the information from.  Cannot be nil.
 *
 *  @return     The ownsPost value stored in the coder.
 */
+ (BOOL)decodeOwnsPostFromCoder:(NSCoder*)coder
{
    NSParameterAssert([coder isKindOfClass:[NSCoder class]]);
    
    BOOL ownsPost = [coder decodeBoolForKey:WPPostViewControllerOwnsPostRestorationKey];
    
    return ownsPost;
}

/**
 *  @brief      Obtains the post for this VC from the specified coder.
 *
 *  @param      coder       The coder to retrieve the information from.  Cannot be nil.
 *
 *  @return     The post for this VC.  Can be nil.
 */
+ (AbstractPost*)decodePostFromCoder:(NSCoder*)coder
{
    NSParameterAssert([coder isKindOfClass:[NSCoder class]]);
    
    AbstractPost* post = nil;
    NSURL* postURIRepresentation = [coder decodeObjectForKey:WPPostViewControllerPostRestorationKey];
    
    if (postURIRepresentation) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:postURIRepresentation];
        
        if (objectID) {
            NSError *error = nil;
            AbstractPost *restoredPost = (AbstractPost *)[context existingObjectWithID:objectID error:&error];
            if (!error && restoredPost) {
                post = restoredPost;
            }
        }
    }
    
    return post;
}

#pragma mark - Media upload configuration

- (void)configureMediaUpload
{
    self.mediaInProgress = [NSMutableDictionary dictionary];
    self.mediaProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
}

#pragma mark - Alerts

- (void)showUnsavedChangesAlert
{
    NSString *title = NSLocalizedString(@"Unsaved changes.",
                                        @"Title of the alert that lets the users know there are unsaved changes in a post they're opening.");
    NSString *message = NSLocalizedString(@"This post has local changes that were not saved. You can now save them or discard them.",
                                          @"Message of the alert that lets the users know there are unsaved changes in a post they're opening.");
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"OK",@""), nil];
    
    [alertView show];
}

#pragma mark - Onboarding

- (void)setOnboardingShown:(BOOL)wasShown
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:wasShown forKey:OnboardingWasShown];
    [defaults synchronize];
}

- (BOOL)wasOnboardingShown
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:OnboardingWasShown];
}

- (void)showOnboardingTips
{
    CGFloat xValue = CGRectGetMaxX(self.view.frame) - NavigationBarButtonRect.size.width;
    if (IS_IPAD) {
        xValue -= 20.0;
    } else {
        xValue -= 10.0;
    }
    CGRect targetFrame = CGRectMake(xValue, 0.0, NavigationBarButtonRect.size.width, 0.0);
    NSString *tooltipText = NSLocalizedString(@"Tap to edit post", @"Tooltip for the button that allows the user to edit the current post.");
    [WPTooltip displayToolTipInView:self.view fromFrame:targetFrame withText:tooltipText];
}

#pragma mark - Actions

/**
 *	@brief      Handles the UIControlEventTouchUpInside event for the blog selector button.
 *	@details    This method handles a the touch up inside event for the blog selector button.
                Since there are two different modes this button can have, we have a few
                different scenarios to consider:  1) If the user is editing an existing post 
                exit the screen we are currently on and return. 2) If the user is creating a
                new post and the post does not have site-specific changes, show the blog selector
                3) If the user is creating a new post and the post does have site-specific 
                changes, display a blog change warning.
 *
 *	@param      sender The WPBlogSelectorButton triggering this action.
 */
- (void)showBlogSelectorPrompt:(WPBlogSelectorButton*)sender
{
    if (sender.buttonMode == WPBlogSelectorButtonSingleSite) {
        [self cancelEditingOrDismiss];
        return;
    }
    
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
            
            NSAssert(self.isEditing,
                     @"We assume that changing blogs is only enabled during editing.");
            
            [self discardChanges];
            self.post = newPost;
            [self createRevisionOfPost];

            [self syncOptionsIfNecessaryForBlog:blog afterBlogChanged:YES];
        }
        
        [self refreshUIForCurrentPost];
        [self refreshNavigationBarButtons:NO];
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
        self.blogSelectorPopover = [[UIPopoverController alloc] initWithContentViewController:navController];
        self.blogSelectorPopover.backgroundColor = [WPStyleGuide newKidOnTheBlockBlue];
        self.blogSelectorPopover.delegate = self;
        [self.blogSelectorPopover presentPopoverFromBarButtonItem:self.secondaryLeftUIBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];

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
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cancel media uploads", "Dialog box title for when the user is cancelling an upload.")
                                                        message:NSLocalizedString(@"You are currently uploading media. This action will cancel uploads in progress.\n\nAre you sure?", @"This prompt is displayed when the user attempts to stop media uploads in the post editor.")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Not Now", "Nicer dialog answer for \"No\".")
                                              otherButtonTitles:NSLocalizedString(@"Yes", "Yes"), nil];
    alertView.tag = EditPostViewControllerAlertCancelMediaUpload;
    [alertView show];
}

- (void)showMediaUploadingAlert
{
    //the post is using the network connection and cannot be stoped, show a message to the user
    UIAlertView *blogIsCurrentlyBusy = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Uploading media", @"Title for alert when trying to save/exit a post before media upload process is complete.")
                                                                  message:NSLocalizedString(@"You are currently uploading media. Please wait until this completes.", @"This is a notification the user receives if they are trying to save a post (or exit) before the media upload process is complete.")
                                                                 delegate:nil
                                                        cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                        otherButtonTitles:nil];
    [blogIsCurrentlyBusy show];
}

- (void)showFailedMediaRemovalAlert
{
    UIAlertView * failedMediaAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Uploads failed", @"Title for alert when trying to save post with failed media items")
                                                                              message:NSLocalizedString(@"Some media uploads failed. This action will remove all failed media from the post.\nSave anyway?", @"Confirms with the user if they save the post all media that failed to upload will be removed from it.")
                                                                             delegate:self
                                                                    cancelButtonTitle:NSLocalizedString(@"Not Now", @"")
                                                                    otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
    failedMediaAlertView.tag = EditPostViewControllerAlertTagFailedMediaBeforeSave;
    [failedMediaAlertView show];

    
}

- (void)showFailedMediaBeforeEditAlert
{
    UIAlertView * failedMediaBeforeEditAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Uploads failed", @"Title for alert when trying to edit html post with failed media items")
                                                           message:NSLocalizedString(@"Some media uploads failed. Switching to the HTML view of this post will remove failed media.\nSwitch anyway?", @"Confirms with the user if they manually edit the post HTML all media that failed to upload will be removed from it.")
                                                          delegate:self
                                                 cancelButtonTitle:NSLocalizedString(@"Not Now", @"")
                                                 otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
    failedMediaBeforeEditAlertView.tag = EditPostViewControllerAlertTagFailedMediaBeforeEdit;
    [failedMediaBeforeEditAlertView show];
}

- (void)showSettings
{
    if ([self isMediaUploading]) {
        [self showMediaUploadingAlert];
        return;
    }
    
    Post *post = (Post *)self.post;
    PostSettingsViewController *vc = [[[self classForSettingsViewController] alloc] initWithPost:post shouldHideStatusBar:YES];
	vc.hidesBottomBarWhenPushed = YES;
    [self.editorView saveSelection];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showPreview
{
    if ([self isMediaUploading]) {
        [self showMediaUploadingAlert];
        return;
    }
    
    PostPreviewViewController *vc = [[PostPreviewViewController alloc] initWithPost:self.post shouldHideStatusBar:self.isEditing];
	vc.hidesBottomBarWhenPushed = YES;
    [self.editorView saveSelection];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showMediaOptions
{
    [self.editorView saveSelection];
    
    WPMediaPickerViewController *picker = [[WPMediaPickerViewController alloc] init];
	picker.delegate = self;        
    
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - Data Model: Post

- (BOOL)isPostLocal
{
    return self.post.remoteStatus == AbstractPostRemoteStatusLocal;
}

#pragma mark - Editing

- (void)cancelEditing
{
    if ([self isMediaUploading]) {
        [self showMediaUploadingAlert];
        return;
    }
    
    [self.editorView saveSelection];
    [self.editorView.focusedField blur];
	
    if ([self.post hasLocalChanges]) {
        [self showPostHasChangesActionSheet];
    } else {
        [self stopEditing];
        [self discardChangesAndUpdateGUI];
    }
}

- (void)showPostHasChangesActionSheet
{
	UIActionSheet *actionSheet;
	if (![self.post.original.status isEqualToString:PostStatusDraft] && ![self isPostLocal]) {
        // The post is already published in the server or it was intended to be and failed: Discard changes or keep editing
		actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"You have unsaved changes.", @"Title of message with options that shown when there are unsaved changes and the author is trying to move away from the post.")
												  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Keep Editing", @"Button shown if there are unsaved changes and the author is trying to move away from the post.")
                                    destructiveButtonTitle:NSLocalizedString(@"Discard", @"Button shown if there are unsaved changes and the author is trying to move away from the post.")
										 otherButtonTitles:nil];
    } else if ([self isPostLocal]) {
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
    
    actionSheet.tag = WPPostViewControllerActionSheetSaveOnExit;
    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    if (IS_IPAD) {
        [actionSheet showFromBarButtonItem:self.currentCancelButton animated:YES];
    } else {
        [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
    }
}

- (void)startEditing
{
    [self createRevisionOfPost];
    
    [super startEditing];
}

#pragma mark - Visual editor in settings

+ (void)setNewEditorAvailable:(BOOL)isAvailable
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:isAvailable forKey:kUserDefaultsNewEditorAvailable];
	[defaults synchronize];
}

+ (void)setNewEditorEnabled:(BOOL)isEnabled
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:isEnabled forKey:kUserDefaultsNewEditorEnabled];
    [defaults synchronize];
    
    if (isEnabled) {
        [WPAnalytics track:WPAnalyticsStatEditorEnabledNewVersion];
    }
}

+ (BOOL)makeNewEditorAvailable
{
    BOOL result = NO;
    BOOL newVisualEditorNotAvailable = ![WPPostViewController isNewEditorAvailable];
    
    if (newVisualEditorNotAvailable) {
        
        result = YES;
        [WPPostViewController setNewEditorAvailable:YES];
        [WPPostViewController setNewEditorEnabled:YES];
    }
    
    return result;
}

+ (BOOL)isNewEditorAvailable
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsNewEditorAvailable];
}

+ (BOOL)isNewEditorEnabled
{    
    return [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsNewEditorEnabled];
}

#pragma mark - Instance Methods

- (void)cancelEditingOrDismiss
{
    if (self.isEditing) {
        [self cancelEditing];
    } else {
        [self dismissEditView];
    }
}

- (UIImage *)tintedImageWithColor:(UIColor *)tintColor image:(UIImage *)image
{
    UIGraphicsBeginImageContextWithOptions(image.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    // draw alpha-mask
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextDrawImage(context, rect, image.CGImage);
    
    // draw tint color, preserving alpha values of original image
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    [tintColor setFill];
    CGContextFillRect(context, rect);
    
    UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return coloredImage;
}

- (AbstractPost *)createNewDraftForBlog:(Blog *)blog {
    return [PostService createDraftPostInMainContextForBlog:blog];
}

- (void)geotagNewPost {
    if (![self isPostLocal]) {
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
    if ([self isPostLocal]) {
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

- (NSInteger)currentBlogCount
{
    NSInteger blogCount = 0;
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    blogCount = [blogService blogCountForAllAccounts];
    
    return blogCount;
}

#pragma mark - UI Manipulation

/**
 *  @brief      Refreshes the navigation bar buttons.
 *  
 *  @param      editingChanged      Should be YES if this call is triggered by an editing status
 *                                  change (ie: it it's triggered by the VC going into edit mode
 *                                  or vice-versa).
 */
- (void)refreshNavigationBarButtons:(BOOL)editingChanged
{
    [self refreshNavigationBarLeftButtons:editingChanged];
    [self refreshNavigationBarRightButtons:editingChanged];
    [self refreshMediaProgress];
}

- (void)refreshNavigationBarLeftButtons:(BOOL)editingChanged
{
    UIBarButtonItem *secondaryleftHandButton = self.secondaryLeftUIBarButtonItem;
    NSArray* leftBarButtons;
    
    if ([self isEditing] && !self.post.hasRemote) {
        // Editing a new post
        leftBarButtons = @[self.negativeSeparator, self.cancelXButton, secondaryleftHandButton];
        self.currentCancelButton = self.cancelXButton;
    } else if ([self isEditing] && self.post.hasRemote) {
        // Editing an existing post (draft or published)
        leftBarButtons = @[self.negativeSeparator, self.cancelChevronButton, secondaryleftHandButton];
        self.currentCancelButton = self.cancelChevronButton;
	} else {
        // Previewing a post (no edit)
        leftBarButtons = @[self.negativeSeparator, self.cancelChevronButton, secondaryleftHandButton];
        self.currentCancelButton = self.cancelChevronButton;
	}
    
    if (![leftBarButtons isEqualToArray:self.navigationItem.leftBarButtonItems]) {
        [self.navigationItem setLeftBarButtonItems:nil];
        [self.navigationItem setLeftBarButtonItems:leftBarButtons];
    }
}

- (void)refreshNavigationBarRightButtons:(BOOL)editingChanged
{
    if ([self isEditing]) {
        if (editingChanged) {
            NSArray* rightBarButtons = @[self.saveBarButtonItem,
                                         [self optionsBarButtonItem],
                                         [self previewBarButtonItem]];
            
            [self.navigationItem setRightBarButtonItems:rightBarButtons animated:YES];
        } else {
            self.saveBarButtonItem.title = [self saveBarButtonItemTitle];
        }

		BOOL updateEnabled = [self.post canSave];
        
		[self.navigationItem.rightBarButtonItem setEnabled:updateEnabled];		
	} else {
		NSArray* rightBarButtons = @[self.editBarButtonItem,
									 [self previewBarButtonItem]];
		
		[self.navigationItem setRightBarButtonItems:rightBarButtons animated:YES];
	}
}

- (void)refreshUIForCurrentPost
{
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
    
    [self refreshNavigationBarButtons:YES];
}

#pragma mark - Custom UI elements

- (WPButtonForNavigationBar*)buttonForBarWithImageNamed:(NSString*)imageName
												  frame:(CGRect)frame
												 target:(id)target
											   selector:(SEL)selector
{
	NSAssert([imageName isKindOfClass:[NSString class]],
			 @"Expected imageName to be a non nil string.");

	UIImage* image = [UIImage imageNamed:imageName];
	
	WPButtonForNavigationBar* button = [[WPButtonForNavigationBar alloc] initWithFrame:frame];
	
	[button setImage:image forState:UIControlStateNormal];
	[button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
	
	return button;
}

- (UIBarButtonItem*)cancelChevronButton
{
    if (_cancelChevronButton) {
        return _cancelChevronButton;
    }
    
    WPButtonForNavigationBar* cancelButton = [self buttonForBarWithImageNamed:@"icon-posts-editor-chevron"
                                                                        frame:NavigationBarButtonRect
                                                                       target:self
                                                                     selector:@selector(cancelEditing)];
    cancelButton.removeDefaultLeftSpacing = YES;
    cancelButton.removeDefaultRightSpacing = YES;
    cancelButton.rightSpacing = RightSpacingOnExitNavbarButton;
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:cancelButton];
    button.accessibilityLabel = NSLocalizedString(@"Cancel", @"Action button to close editor and cancel changes or insertion of post");
    _cancelChevronButton = button;
    return _cancelChevronButton;
}

- (UIBarButtonItem*)cancelXButton
{
    if (_cancelXButton) {
        return _cancelXButton;
    }
    
    WPButtonForNavigationBar* cancelButton = [self buttonForBarWithImageNamed:@"icon-posts-editor-x"
                                                                        frame:NavigationBarButtonRect
                                                                       target:self
                                                                     selector:@selector(cancelEditing)];
    cancelButton.removeDefaultLeftSpacing = YES;
    cancelButton.removeDefaultRightSpacing = YES;
    cancelButton.rightSpacing = RightSpacingOnExitNavbarButton;
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:cancelButton];
    _cancelXButton = button;
    button.accessibilityLabel = NSLocalizedString(@"Cancel", @"Action button to close edior and cancel changes or insertion of post");
	return _cancelXButton;
}

- (UIBarButtonItem *)editBarButtonItem
{
    if (!_editBarButtonItem) {
        NSString* buttonTitle = NSLocalizedString(@"Edit",
                                                  @"Label for the button to edit the current post.");
        
        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:buttonTitle
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(startEditing)];
        
        // Seems to be an issue witht the appearance proxy not being respected, so resetting these here
        [editButton setTitleTextAttributes:EnabledButtonBarStyle forState:UIControlStateNormal];
        [editButton setTitleTextAttributes:DisabledButtonBarStyle forState:UIControlStateDisabled];
        _editBarButtonItem = editButton;
    }
    
	return _editBarButtonItem;
}

- (UIBarButtonItem *)optionsBarButtonItem
{
	if (!_optionsBarButtonItem) {
        WPButtonForNavigationBar *button = [self buttonForBarWithImageNamed:@"icon-posts-editor-options"
                                                                      frame:NavigationBarButtonRect
                                                                     target:self
                                                                   selector:@selector(showSettings)];
        
        button.removeDefaultRightSpacing = YES;
        button.rightSpacing = SpacingBetweeenNavbarButtons / 2.0f;
        button.removeDefaultLeftSpacing = YES;
        button.leftSpacing = SpacingBetweeenNavbarButtons / 2.0f;
        NSString *optionsTitle = NSLocalizedString(@"Options", @"Title of the Post Settings navigation button in the Post Editor. Tapping shows settings and options related to the post being edited.");
        button.accessibilityLabel = optionsTitle;
        button.accessibilityIdentifier = @"Options";
        _optionsBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    
	return _optionsBarButtonItem;
}

- (UIBarButtonItem *)previewBarButtonItem
{
	if (!_previewBarButtonItem) {
        WPButtonForNavigationBar* button = [self buttonForBarWithImageNamed:@"icon-posts-editor-preview"
                                                                      frame:NavigationBarButtonRect
                                                                     target:self
                                                                   selector:@selector(showPreview)];
        
        button.removeDefaultRightSpacing = YES;
        button.rightSpacing = SpacingBetweeenNavbarButtons / 2.0f;
        button.removeDefaultLeftSpacing = YES;
        button.leftSpacing = SpacingBetweeenNavbarButtons / 2.0f;
        _previewBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
        _previewBarButtonItem.accessibilityLabel = NSLocalizedString(@"Preview", @"Action button to preview the content of post or page on the  live site");
    }
	
	return _previewBarButtonItem;
}

- (UIBarButtonItem *)saveBarButtonItem
{
    if (!_saveBarButtonItem) {
        NSString *buttonTitle = [self saveBarButtonItemTitle];

        UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:buttonTitle
                                                                       style:[WPStyleGuide barButtonStyleForDone]
                                                                      target:self
                                                                      action:@selector(saveAction)];
        
        // Seems to be an issue witht the appearance proxy not being respected, so resetting these here
        [saveButton setTitleTextAttributes:EnabledButtonBarStyle forState:UIControlStateNormal];
        [saveButton setTitleTextAttributes:DisabledButtonBarStyle forState:UIControlStateDisabled];
        _saveBarButtonItem = saveButton;
    }

	return _saveBarButtonItem;
}

- (NSString*)saveBarButtonItemTitle
{
    NSString *buttonTitle = nil;
    
    if(![self.post hasRemote] || ![self.post.status isEqualToString:self.post.original.status]) {
        if ([self.post isScheduled]) {
            buttonTitle = NSLocalizedString(@"Schedule", @"Schedule button, this is what the Publish button changes to in the Post Editor if the post has been scheduled for posting later.");
            
        } else if ([self.post.status isEqualToString:PostStatusPublish]){
            buttonTitle = NSLocalizedString(@"Post", @"Publish button label.");
            
        } else {
            buttonTitle = NSLocalizedString(@"Save", @"Save button label (saving content, ex: Post, Page, Comment).");
        }
    } else {
        buttonTitle = NSLocalizedString(@"Update", @"Update button label (saving content, ex: Post, Page, Comment).");
    }
    NSAssert([buttonTitle isKindOfClass:[NSString class]], @"Expected to have a title at this point.");
    
    return buttonTitle;
}

- (UIBarButtonItem *)secondaryLeftUIBarButtonItem
{
    UIBarButtonItem *aUIButtonBarItem;
    
    if ([self isMediaUploading]) {
        aUIButtonBarItem = self.uploadStatusButton;
    } else {
        WPBlogSelectorButton *blogButton = (WPBlogSelectorButton*)self.blogPickerButton;
        NSString *blogName = [self.post.blog.blogName length] == 0 ? self.post.blog.url : self.post.blog.blogName;
        NSMutableAttributedString *titleText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", blogName]
                                                                                      attributes:@{ NSFontAttributeName : [WPFontManager openSansSemiBoldFontOfSize:16.0] }];
        
        [blogButton setAttributedTitle:titleText forState:UIControlStateNormal];
        if (IS_IPAD) {
            //size to fit here so the iPad popover works properly
            [blogButton sizeToFit];
        }
        
        // The blog picker is in single site mode if one of the following is true:
        // editor screen is in preview mode, there is only 1 blog, or the user
        // is editing an existing post.
        if (self.currentBlogCount <= 1 || !self.isEditing || (self.isEditing && self.post.hasRemote)) {
            blogButton.buttonMode = WPBlogSelectorButtonSingleSite;
        } else {
            blogButton.buttonMode = WPBlogSelectorButtonMultipleSite;
        }
        aUIButtonBarItem = [[UIBarButtonItem alloc] initWithCustomView:blogButton];
    }
    
    _secondaryLeftUIBarButtonItem = aUIButtonBarItem;
    return _secondaryLeftUIBarButtonItem;
}

- (UIButton *)blogPickerButton
{
    if (!_blogPickerButton) {
        CGFloat titleButtonWidth = (IS_IPAD) ? 300.0f : 170.0f;
        UIButton *button = [WPBlogSelectorButton buttonWithFrame:CGRectMake(0.0f, 0.0f, titleButtonWidth , 30.0f) buttonStyle:WPBlogSelectorButtonTypeSingleLine];
        [button addTarget:self action:@selector(showBlogSelectorPrompt:) forControlEvents:UIControlEventTouchUpInside];
        _blogPickerButton = button;
    }
    
    return _blogPickerButton;
}

- (UIBarButtonItem *)uploadStatusButton
{
    if (!_uploadStatusButton) {
        UIButton *button = [WPUploadStatusButton buttonWithFrame:CGRectMake(0.0f, 0.0f, 125.0f , 30.0f)];
        button.titleLabel.text = NSLocalizedString(@"Media Uploading...", @"Message to indicate progress of uploading media to server");
        [button addTarget:self action:@selector(showCancelMediaUploadPrompt) forControlEvents:UIControlEventTouchUpInside];
        _uploadStatusButton = [[UIBarButtonItem alloc] initWithCustomView:button];
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
    NSManagedObjectContext* context = self.post.managedObjectContext;
    NSAssert([context isKindOfClass:[NSManagedObjectContext class]],
             @"The object should be related to a managed object context here.");
    
    self.post = self.post.original;
    [self.post deleteRevision];
    
    if (self.ownsPost) {
        [self.post remove];
        self.post = nil;
    }
    
    [[ContextManager sharedInstance] saveContext:context];
    
    [WPAnalytics track:WPAnalyticsStatEditorDiscardedChanges];
}

/**
 *  @brief      Discards all changes in the last editing session and updates the GUI accordingly.
 *  @details    The GUI will be affected by this method.  If you want to avoid updating the GUI you
 *              can call `discardChanges` instead.
 */
- (void)discardChangesAndUpdateGUI
{
    [self discardChanges];
    
    if (!self.post) {
        [self dismissEditView];
    } else {
        [self refreshUIForCurrentPost];
    }
}

- (void)dismissEditView
{
    if (self.onClose) {
        self.onClose();
        self.onClose = nil;
	} else if (self.presentingViewController) {
		[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
	} else {
		[self.navigationController popViewControllerAnimated:YES];
	}
    
    [WPAnalytics track:WPAnalyticsStatEditorClosed];
}

- (void)saveAction
{
    if (_currentActionSheet.isVisible) {
        [_currentActionSheet dismissWithClickedButtonIndex:-1 animated:YES];
        _currentActionSheet = nil;
    }
    
	if ([self isMediaUploading] ) {
		[self showMediaUploadingAlert];
		return;
	}
    
	[self savePostAndDismissVC];
}

/**
 *	@brief		Saves the post being edited and closes this VC.
 */
- (void)savePostAndDismissVC
{
    if ([self hasFailedMedia]) {
        [self showFailedMediaRemovalAlert];
        return;
    }
    [self stopEditing];
    [self savePost];
    [self dismissEditView];
}

/**
 *  @brief      Saves the post being edited and uploads it.
 *  @details    Saves the post being edited and uploads it. If the post is NOT already scheduled, 
 *              changing from 'draft' status to 'publish' will set the date to now.
 */
- (void)savePost
{
    DDLogMethod();
    [self logSavePostStats];

    [self.view endEditing:YES];
    
    if (!self.post.isScheduled && [self.post.original.status isEqualToString:PostStatusDraft]  && [self.post.status isEqualToString:PostStatusPublish]) {
        self.post.dateCreated = [NSDate date];
    }
    self.post = self.post.original;
    [self.post applyRevision];
    [self.post deleteRevision];
    
	__block NSString *postTitle = self.post.postTitle;
    __block NSString *postStatus = self.post.status;
    __block BOOL postIsScheduled = self.post.isScheduled;
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:context];
    [postService uploadPost:self.post
                    success:^{
                        DDLogInfo(@"post uploaded: %@", postTitle);
                        NSString *hudText;
                        if (postIsScheduled) {
                            hudText = NSLocalizedString(@"Scheduled!", @"Text displayed in HUD after a post was successfully scheduled to be published.");
                        } else if ([postStatus isEqualToString:@"publish"]){
                            hudText = NSLocalizedString(@"Published!", @"Text displayed in HUD after a post was successfully published.");
                        } else {
                            hudText = NSLocalizedString(@"Saved!", @"Text displayed in HUD after a post was successfully saved as a draft.");
                        }
                        [SVProgressHUD showSuccessWithStatus:hudText];
                    } failure:^(NSError *error) {
                        DDLogError(@"post failed: %@", [error localizedDescription]);
                        NSString *hudText;
                        if (postIsScheduled) {
                            hudText = NSLocalizedString(@"Error occurred\nduring scheduling", @"Text displayed in HUD after attempting to schedule a post and an error occurred.");
                        } else if ([postStatus isEqualToString:@"publish"]){
                            hudText = NSLocalizedString(@"Error occurred\nduring publishing", @"Text displayed in HUD after attempting to publish a post and an error occurred.");
                        } else {
                            hudText = NSLocalizedString(@"Error occurred\nduring saving", @"Text displayed in HUD after attempting to save a draft post and an error occurred.");
                        }
                        [SVProgressHUD showErrorWithStatus:hudText];
                    }];

    [self didSaveNewPost];
}

- (void)didSaveNewPost
{
    if ([self isPostLocal]) {
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
    
    if ([buttonTitle isEqualToString:NSLocalizedString(@"Post", nil)]) {
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

/**
 *  @brief      Save changes to core data
 */
- (void)autosaveContent
{
    self.post.postTitle = self.titleText;
    
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
    for(NSProgress * progress in [self.mediaInProgress allValues]){
        if (progress.totalUnitCount != 0 && !progress.cancelled){
            [self.editorView setProgress:progress.fractionCompleted onImage:progress.userInfo[WPProgressMediaID]];
            [self.editorView setProgress:progress.fractionCompleted onVideo:progress.userInfo[WPProgressMediaID]];
        }
    }
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
            [self.editorView removeImage:key];
            [self.editorView removeVideo:key];
            [keys addObject:key];
        }
    }];
    [self.mediaInProgress removeObjectsForKeys:keys];
    [self autosaveContent];
    [self refreshNavigationBarButtons:NO];
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
            [self.editorView removeImage:key];
            [self.editorView removeVideo:key];
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
    [self dismissAssociatedActionSheetIfVisible:uniqueMediaId];
}

- (void)dismissAssociatedActionSheetIfVisible:(NSString *)uniqueMediaId {
    // let's see if we where displaying an action sheet for this image
    if (self.currentActionSheet && [uniqueMediaId isEqualToString:self.selectedMediaID]){
        if (self.currentActionSheet.tag == WPPostViewControllerActionSheetCancelUpload ||
            self.currentActionSheet.tag == WPPostViewControllerActionSheetRetryUpload ) {
            [self.currentActionSheet dismissWithClickedButtonIndex:self.currentActionSheet.cancelButtonIndex animated:YES];
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

- (void)uploadMedia:(Media *)media trackingId:(NSString *)mediaUniqueId
{
    MediaService *mediaService = [[MediaService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [self.mediaGlobalProgress becomeCurrentWithPendingUnitCount:1];
    NSProgress *uploadProgress = nil;
    [mediaService uploadMedia:media progress:&uploadProgress success:^{
        if (media.mediaType == MediaTypeImage) {
            [WPAnalytics track:WPAnalyticsStatEditorAddedPhotoViaLocalLibrary];
            [self.editorView replaceLocalImageWithRemoteImage:media.remoteURL uniqueId:mediaUniqueId];
        } else if (media.mediaType == MediaTypeVideo) {
            [WPAnalytics track:WPAnalyticsStatEditorAddedVideoViaLocalLibrary];
            [self.editorView replaceLocalVideoWithID:mediaUniqueId
                                      forRemoteVideo:media.remoteURL
                                        remotePoster:media.thumbnailLocalURL
                                          videoPress:media.shortcode];
        }
    } failure:^(NSError *error) {
        if (error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled) {
            [self stopTrackingProgressOfMediaWithId:mediaUniqueId];
            if (media.mediaType == MediaTypeImage) {
                [self.editorView removeImage:mediaUniqueId];
            } else if (media.mediaType == MediaTypeVideo) {
                [self.editorView removeVideo:mediaUniqueId];
            }
            [media remove];
        } else {
            [WPAnalytics track:WPAnalyticsStatEditorUploadMediaFailed];
            [self dismissAssociatedActionSheetIfVisible:mediaUniqueId];
            self.mediaGlobalProgress.completedUnitCount++;
            if (media.mediaType == MediaTypeImage) {
                [self.editorView markImage:mediaUniqueId
                   failedUploadWithMessage:NSLocalizedString(@"Failed", @"The message that is overlay on media when the upload to server fails")];
            } else if (media.mediaType == MediaTypeVideo) {
                [self.editorView markVideo:mediaUniqueId
                   failedUploadWithMessage:NSLocalizedString(@"Failed", @"The message that is overlay on media when the upload to server fails")];
            }
        }
    }];
    [uploadProgress setUserInfoObject:mediaUniqueId forKey:WPProgressMediaID];
    [uploadProgress setUserInfoObject:media forKey:WPProgressMedia];
    [self trackMediaWithId:mediaUniqueId usingProgress:uploadProgress];
    [self.mediaGlobalProgress resignCurrent];
}

- (void)retryUploadOfMediaWithId:(NSString *)imageUniqueId
{
    [WPAnalytics track:WPAnalyticsStatEditorUploadMediaRetried];

    NSProgress *progress = self.mediaInProgress[imageUniqueId];
    if (!progress) {
        return;
    }
    
    Media *media = progress.userInfo[WPProgressMedia];
    if (!media) {
        return;
    }
    
    [self prepareMediaProgressForNumberOfAssets:1];
    [self uploadMedia:media trackingId:imageUniqueId];
}

- (void)addMediaAssets:(NSArray *)assets
{

    [self prepareMediaProgressForNumberOfAssets:assets.count];

    for (ALAsset *asset in assets) {
        MediaService *mediaService = [[MediaService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
        __weak __typeof__(self) weakSelf = self;
        NSString *mediaUniqueID = [self uniqueIdForMedia];
        NSProgress *createMediaProgress = [[NSProgress alloc] initWithParent:nil userInfo:nil];
        createMediaProgress.totalUnitCount = 2;
        [self trackMediaWithId:mediaUniqueID usingProgress:createMediaProgress];
        [mediaService createMediaWithAsset:asset forPostObjectID:self.post.objectID completion:^(Media *media, NSError *error) {
            __typeof__(self) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            createMediaProgress.completedUnitCount++;
            if (error || !media || !media.localURL) {
                [WPError showAlertWithTitle:NSLocalizedString(@"Failed to export media",
                                                              @"The title for an alert that says to the user the media (image or video) he selected couldn't be used on the post.")
                                    message:error.localizedDescription];
                return;
            }
            NSURL* url = [[NSURL alloc] initFileURLWithPath:media.localURL];
            if ([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
                [strongSelf.editorView insertLocalImage:[url absoluteString] uniqueId:mediaUniqueID];
            } else if ([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
                UIImage * posterImage = [UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage];
                NSData *data = UIImageJPEGRepresentation(posterImage, 0.7);
                NSString *posterImagePath = [NSString stringWithFormat:@"%@/%@.jpg", NSTemporaryDirectory(), mediaUniqueID];
                [data writeToFile:posterImagePath atomically:YES];
                NSURL * posterURL = [[NSURL alloc] initFileURLWithPath:posterImagePath];
                [strongSelf.editorView insertInProgressVideoWithID:mediaUniqueID usingPosterImage:[posterURL absoluteString]];
            }
            
            [self uploadMedia:media trackingId:mediaUniqueID];
        }];
    }
    // Need to refresh the post object. If we didn't, self.post.media would appear
    // to be unchanged causing the Media State Methods to fail.
    [self.post.managedObjectContext refreshObject:self.post mergeChanges:YES];
}

- (void)insertImage:(NSString *)url alt:(NSString *)alt
{
    [self.editorView insertImage:url alt:alt];
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
    switch(alertView.tag){
        case (EditPostViewControllerAlertTagFailedMedia): {
            if (buttonIndex == alertView.firstOtherButtonIndex) {
                DDLogInfo(@"Saving post even after some media failed to upload");
                [self savePostAndDismissVC];
            }
            self.failedMediaAlertView = nil;
        } break;
        case (EditPostViewControllerAlertTagSwitchBlogs): {
            if (buttonIndex == alertView.firstOtherButtonIndex) {
                [self showBlogSelector];
            }
        } break;
        case (EditPostViewControllerAlertCancelMediaUpload): {
            if (buttonIndex == alertView.firstOtherButtonIndex) {
                [self cancelMediaUploads];
            }
        } break;
        case (EditPostViewControllerAlertTagFailedMediaBeforeEdit): {
            if (buttonIndex == alertView.firstOtherButtonIndex) {
                [self removeAllFailedMedia];
                [self.editorView showHTMLSource];
            }
        } break;
        case (EditPostViewControllerAlertTagFailedMediaBeforeSave): {
            if (buttonIndex == alertView.firstOtherButtonIndex) {
                [self removeAllFailedMedia];
                [self savePostAndDismissVC];
            }
        } break;
    }
    
    return;
}

#pragma mark - ActionSheet Delegate Methods

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    _currentActionSheet = actionSheet;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    switch ([actionSheet tag]){
        case(WPPostViewControllerActionSheetSaveOnExit): {
            if (buttonIndex == actionSheet.destructiveButtonIndex) {
                [self actionSheetDiscardButtonPressed];
            } else if (buttonIndex == actionSheet.cancelButtonIndex) {
                [self actionSheetKeepEditingButtonPressed];
            } else if (buttonIndex == actionSheet.firstOtherButtonIndex) {
                [self actionSheetSaveDraftButtonPressed];
            }
        } break;
        case (WPPostViewControllerActionSheetCancelUpload): {
            if (buttonIndex == actionSheet.destructiveButtonIndex){
                [self cancelUploadOfMediaWithId:self.selectedMediaID];
            }
            self.selectedMediaID = nil;
        } break;
        case (WPPostViewControllerActionSheetRetryUpload): {
            if (buttonIndex == actionSheet.destructiveButtonIndex){
                [self stopTrackingProgressOfMediaWithId:self.selectedMediaID];
                [self.editorView removeImage:self.selectedMediaID];
                [self.editorView removeVideo:self.selectedMediaID];
            } else if (buttonIndex == 1) {
                [self.editorView unmarkImageFailedUpload:self.selectedMediaID];
                [self.editorView unmarkVideoFailedUpload:self.selectedMediaID];
                [self retryUploadOfMediaWithId:self.selectedMediaID];
            }
            self.selectedMediaID = nil;
        } break;
        case (WPPostViewControllerActionSheetCancelVideoUpload): {
            if (buttonIndex == actionSheet.destructiveButtonIndex){
                [self cancelUploadOfMediaWithId:self.selectedMediaID];
            }
            self.selectedMediaID = nil;
        } break;
        case (WPPostViewControllerActionSheetRetryVideoUpload): {
            if (buttonIndex == actionSheet.destructiveButtonIndex){
                [self stopTrackingProgressOfMediaWithId:self.selectedMediaID];
                [self.editorView removeVideo:self.selectedMediaID];
            } else if (buttonIndex == 1) {
                [self.editorView unmarkVideoFailedUpload:self.selectedMediaID];
                [self retryUploadOfMediaWithId:self.selectedMediaID];
            }
            self.selectedMediaID = nil;
        } break;
    }
    
    _currentActionSheet = nil;
}

#pragma mark - UIActionSheet helper methods

- (void)actionSheetDiscardButtonPressed
{
    [self stopEditing];
    [self discardChangesAndUpdateGUI];
}

- (void)actionSheetKeepEditingButtonPressed
{
    [self.editorView restoreSelection];
}

- (void)actionSheetSaveDraftButtonPressed
{
    if (![self.post hasRemote] && [self.post.status isEqualToString:PostStatusPublish]) {
        self.post.status = PostStatusDraft;
    }
    
    DDLogInfo(@"Saving post as a draft after user initially attempted to cancel");
    
    [self savePostAndDismissVC];
}

#pragma mark - WPEditorViewControllerDelegate delegate

- (void)editorDidBeginEditing:(WPEditorViewController *)editorController
{
    [self setNeedsStatusBarAppearanceUpdate];
    [self refreshNavigationBarButtons:YES];
}

- (void)editorDidEndEditing:(WPEditorViewController *)editorController
{
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)editorTitleDidChange:(WPEditorViewController *)editorController
{
    [self autosaveContent];
    [self refreshNavigationBarButtons:NO];
}

- (void)editorTextDidChange:(WPEditorViewController *)editorController
{
    [self autosaveContent];
    [self refreshNavigationBarButtons:NO];
}

- (BOOL)editorShouldDisplaySourceView:(WPEditorViewController *)editorController
{
    if ([self isMediaUploading]) {
        [self showMediaUploadingAlert];
        return NO;        
    }
    
    if ([self hasFailedMedia]) {
        [self showFailedMediaBeforeEditAlert];
        return NO;
    }
    
    return YES;
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

- (void)editorDidFinishLoadingDOM:(WPEditorViewController *)editorController
{
    [self refreshUIForCurrentPost];
}

- (void)editorViewController:(WPEditorViewController *)editorViewController imageReplaced:(NSString *)imageId
{
    [self stopTrackingProgressOfMediaWithId:imageId];
    [self refreshNavigationBarButtons:NO];
}

- (void)editorViewController:(WPEditorViewController *)editorViewController videoReplaced:(NSString *)videoId
{
    [self stopTrackingProgressOfMediaWithId:videoId];
    [self refreshNavigationBarButtons:NO];
}


- (void)editorViewController:(WPEditorViewController *)editorViewController
                 imageTapped:(NSString *)imageId
                         url:(NSURL *)url
                   imageMeta:(WPImageMeta *)imageMeta
{
    // Note: imageId is an editor specified data attribute, not the image's ID attribute.
    if (imageId.length == 0) {
        [self displayImageDetailsForMeta:imageMeta];
    } else {
        [self promptForActionForTappedImage:imageId url:url];
    }
}

- (void)editorViewController:(WPEditorViewController *)editorViewController
                 videoTapped:(NSString *)videoID
                         url:(NSURL *)url
{
    if (videoID.length > 0) {
        [self promptForActionForTappedVideo:videoID url:url];
    }
}

- (void)editorViewController:(WPEditorViewController *)editorViewController videoPressInfoRequest:(NSString *)videoID
{
    MediaService *mediaService = [[MediaService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    __weak __typeof__(self) weakSelf = self;
    [mediaService getMediaURLFromVideoPressID:videoID
        inBlog:self.post.blog
        success:^(NSString *videoURL, NSString *posterURL) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.editorView setVideoPress:videoID source:videoURL poster:posterURL];
            });            
        }
        failure:^(NSError *error){

        }];
}

- (void)editorViewController:(WPEditorViewController *)editorViewController mediaRemoved:(NSString *)mediaID
{
    [self cancelUploadOfMediaWithId:mediaID];
}

- (void)displayImageDetailsForMeta:(WPImageMeta *)imageMeta
{
    [WPAnalytics track:WPAnalyticsStatEditorEditedImage];
    
    EditImageDetailsViewController *controller = [EditImageDetailsViewController controllerForDetails:imageMeta forPost:self.post];
    controller.delegate = self;

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)promptForActionForTappedImage:(NSString *)imageId url:(NSURL *)url
{
    if (imageId.length == 0) {
        return;
    }
    
    self.selectedMediaID= imageId;
    
    NSProgress * mediaProgress = self.mediaInProgress[imageId];
    if (!mediaProgress){
        // The image is already uploaded so nothing to here, but in the future we could plug in image actions here
        return;
    }

    //Are we showing another action sheet?
    if (self.currentActionSheet != nil){
        return;
    }
    
    // Is upload still going?
    if (mediaProgress.completedUnitCount < mediaProgress.totalUnitCount) {
        UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                  delegate:self
                                                         cancelButtonTitle:NSLocalizedString(@"Cancel", @"User action to dismiss stop upload question")
                                                    destructiveButtonTitle:NSLocalizedString(@"Stop Upload",@"User action to stop upload")otherButtonTitles:nil];
        actionSheet.tag = WPPostViewControllerActionSheetCancelUpload;
        [actionSheet showInView:self.editorView];
    } else {
        UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                  delegate:self
                                                         cancelButtonTitle:NSLocalizedString(@"Cancel", @"User action to dismiss retry upload question")
                                                    destructiveButtonTitle:NSLocalizedString(@"Remove Image", @"User action to remove image that failed upload")
                                                         otherButtonTitles:NSLocalizedString(@"Retry Upload", @"User action to retry upload the image"), nil];
        actionSheet.tag = WPPostViewControllerActionSheetRetryUpload;
        [actionSheet showInView:self.editorView];        
    }
}

- (void)promptForActionForTappedVideo:(NSString *)videoID url:(NSURL *)aURL
{
    if (videoID.length == 0) {
        return;
    }
    
    self.selectedMediaID= videoID;
    
    NSProgress * mediaProgress = self.mediaInProgress[videoID];
    if (!mediaProgress){
        return;
    }
    
    //Are we showing another action sheet?
    if (self.currentActionSheet != nil){
        return;
    }
    
    // Is upload still going?
    if (mediaProgress.completedUnitCount < mediaProgress.totalUnitCount) {
        UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                  delegate:self
                                                         cancelButtonTitle:NSLocalizedString(@"Cancel", @"User action to dismiss stop upload question")
                                                    destructiveButtonTitle:NSLocalizedString(@"Stop Upload",@"User action to stop upload")otherButtonTitles:nil];
        actionSheet.tag = WPPostViewControllerActionSheetCancelVideoUpload;
        [actionSheet showInView:self.editorView];
    } else {
        UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                  delegate:self
                                                         cancelButtonTitle:NSLocalizedString(@"Cancel", @"User action to dismiss retry upload question")
                                                    destructiveButtonTitle:NSLocalizedString(@"Remove Video", @"User action to remove video that failed upload")
                                                         otherButtonTitles:NSLocalizedString(@"Retry Upload", @"User action to retry upload the video"), nil];
        actionSheet.tag = WPPostViewControllerActionSheetRetryVideoUpload;
        [actionSheet showInView:self.editorView];
    }
}

#pragma mark - WPMediaPickerViewControllerDelegate

- (void)mediaPickerController:(WPMediaPickerViewController *)picker didFinishPickingAssets:(NSArray *)assets
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self addMediaAssets:assets];
    }];
}

- (void)mediaPickerControllerDidCancel:(WPMediaPickerViewController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)mediaPickerController:(WPMediaPickerViewController *)picker shouldSelectAsset:(ALAsset *)asset
{
    NSString * assetType = [asset valueForProperty:ALAssetPropertyType];
    
    if (assetType == ALAssetTypeUnknown) {
        return NO;
    }
    
    // If the media is from a shared photo stream it may not be available locally to be used
    if (!asset.defaultRepresentation) {
        if (assetType == ALAssetTypePhoto) {
            [WPError showAlertWithTitle:NSLocalizedString(@"Image unavailable", @"The title for an alert that says the image the user selected isn't available.")
                                message:NSLocalizedString(@"This Photo Stream image cannot be added to your WordPress. Try saving it to your Camera Roll before uploading.", @"User information explaining that the video is not available locally. This is normally related to share photo stream images.")
                      withSupportButton:NO];
        } else {
            [WPError showAlertWithTitle:NSLocalizedString(@"Video unavailable", @"The title for an alert that says the video the user selected isn't available.")
                                message:NSLocalizedString(@"This Photo Stream video cannot be added to your WordPress. Try saving it to your Camera Roll before uploading.", @"User information explaining that the video is not available locally. This is normally related to share photo stream images.")
                      withSupportButton:NO];
        }
        return NO;
    }
    
    return YES;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {    
    if (context == ProgressObserverContext && object == self.mediaGlobalProgress) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self refreshNavigationBarButtons:NO];
        }];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - EditImageDetailsViewControllerDelegate

- (void)editImageDetailsViewController:(EditImageDetailsViewController *)controller didFinishEditingImageDetails:(WPImageMeta *)imageMeta
{
    [self.editorView updateCurrentImageMeta:imageMeta];
}



#pragma mark - Status bar management

- (BOOL)prefersStatusBarHidden
{
    /**
     Never hide for the iPad. 
     Always hide on the iPhone except when user is not editing
     */
    if (IS_IPAD || !self.isEditing) {
        return NO;
    }
    return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationSlide;
}

@end
