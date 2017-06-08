#import "WPPostViewController.h"

#import <Photos/Photos.h>
#import <WordPressEditor/WPEditorField.h>
#import <WordPressEditor/WPEditorView.h>
#import <WordPressEditor/WPEditorFormatbarView.h>
#import <WordPressShared/NSString+Util.h>
#import <WordPressShared/UIImage+Util.h>
#import <WordPressShared/WPFontManager.h>
#import <WordPressShared/WPStyleGuide.h>
#import <WordPressComAnalytics/WPAnalytics.h>
#import <WPMediaPicker/WPMediaPicker.h>
#import "BlogSelectorViewController.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "Coordinate.h"
#import "EditImageDetailsViewController.h"
#import "LocationService.h"
#import "Media.h"
#import "MediaService.h"
#import "NSString+Helpers.h"
#import "PostPreviewViewController.h"
#import "PostService.h"
#import "PostSettingsViewController.h"
#import "PrivateSiteURLProtocol.h"
#import "SVProgressHUD+Dismiss.h"
#import "WordPressAppDelegate.h"
#import "WPButtonForNavigationBar.h"
#import "WPBlogSelectorButton.h"
#import "WPButtonForNavigationBar.h"
#import "WPMediaProgressTableViewController.h"
#import "WPProgressTableViewCell.h"
#import "WPTabBarController.h"
#import "WPUploadStatusButton.h"
#import "WordPress-Swift.h"
#import "MediaLibraryPickerDataSource.h"
#import "WPAndDeviceMediaLibraryDataSource.h"
#import "WPAppAnalytics.h"
#import "Media+HTML.h"
#import <WordPressShared/WPTableViewCell.h>

@import Gridicons;

// State Restoration
NSString* const WPEditorNavigationRestorationID = @"WPEditorNavigationRestorationID";
static NSString* const WPPostViewControllerEditModeRestorationKey = @"WPPostViewControllerEditModeRestorationKey";
static NSString* const WPPostViewControllerOwnsPostRestorationKey = @"WPPostViewControllerOwnsPostRestorationKey";
static NSString* const WPPostViewControllerPostRestorationKey = @"WPPostViewControllerPostRestorationKey";

NSString* const WPPostViewControllerOptionOpenMediaPicker = @"WPPostViewControllerMediaPicker";
NSString* const WPPostViewControllerOptionNotAnimated = @"WPPostViewControllerNotAnimated";

NSString* const WPAppAnalyticsEditorSourceValueHybrid = @"hybrid";

// Secret URL config parameters
NSString *const kWPEditorConfigURLParamAvailable = @"available";
NSString *const kWPEditorConfigURLParamEnabled = @"enabled";

static CGFloat const RightSpacingOnExitNavbarButton = 5.0f;
static CGFloat const CompactTitleButtonWidth = 125.0f;
static CGFloat const RegularTitleButtonWidth = 300.0f;
static CGFloat const RegularTitleButtonHeight = 30.0f;
static NSDictionary *DisabledButtonBarStyle;
static NSDictionary *EnabledButtonBarStyle;

static void * const DateChangeObserverContext = (void*)&DateChangeObserverContext;

@interface WPEditorViewController ()
@property (nonatomic, strong, readwrite) WPEditorFormatbarView *toolbarView;
@end

@interface WPPostViewController () <
WPMediaPickerViewControllerDelegate,
UITextFieldDelegate,
UITextViewDelegate,
UIViewControllerRestoration,
EditImageDetailsViewControllerDelegate,
MediaProgressCoordinatorDelegate
>

#pragma mark - Misc properties
@property (nonatomic, strong) UIButton *blogPickerButton;
@property (nonatomic, strong) UIBarButtonItem *uploadStatusButton;
@property (nonatomic) CGPoint scrollOffsetRestorePoint;
@property (nonatomic) BOOL isOpenedDirectlyForEditing;
@property (nonatomic) CGRect keyboardRect;
@property (nonatomic, strong) UIAlertController *currentAlertController;

#pragma mark - Media related properties
@property (nonatomic, strong) MediaProgressCoordinator * mediaProgressCoordinator;
@property (nonatomic, strong) UIProgressView *mediaProgressView;
@property (nonatomic, strong) NSString *selectedMediaID;
@property (nonatomic, strong) WPAndDeviceMediaLibraryDataSource *mediaLibraryDataSource;

#pragma mark - Bar Button Items
@property (nonatomic, strong) UIBarButtonItem *secondaryLeftUIBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *negativeSeparator;
@property (nonatomic, strong) UIBarButtonItem *cancelXButton;
@property (nonatomic, strong) UIBarButtonItem *cancelChevronButton;
@property (nonatomic, strong) UIBarButtonItem *currentCancelButton;
@property (nonatomic, strong) UIBarButtonItem *saveBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *editBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *moreBarButtonItem;

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
    [self removePostObserver];
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

- (instancetype)initWithDraftForLastUsedBlogAndPhotoPost
{
    _isOpenedDirectlyForPhotoPost = YES;
    return [self initWithDraftForLastUsedBlog];
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

+ (Class)supportedPostClass {
    return [Post class];
}

- (instancetype)initWithPost:(AbstractPost *)post
{
    NSParameterAssert([post isKindOfClass:[self.class supportedPostClass]]);
    
    return [self initWithPost:post
                         mode:kWPPostViewControllerModePreview];
}

- (instancetype)initWithPost:(AbstractPost *)post
                        mode:(WPPostViewControllerMode)mode
{
    NSParameterAssert([post isKindOfClass:[self.class supportedPostClass]]);

    BOOL changeToEditModeDueToUnsavedChanges = (mode == kWPPostViewControllerModePreview
                                                && [post hasUnsavedChanges]);
    
    if (changeToEditModeDueToUnsavedChanges) {
        mode = kWPPostViewControllerModeEdit;
    }

    WPEditorViewControllerMode editorMode = (WPEditorViewControllerMode)mode;
    self = [super initWithMode:editorMode];
	
    if (self) {
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
        self.hidesBottomBarWhenPushed = YES;
        
        _changedToEditModeDueToUnsavedChanges = changeToEditModeDueToUnsavedChanges;
        _post = post;
        _isOpenedDirectlyForEditing = (mode == kWPEditorViewControllerModeEdit);
        
        if (post.blog.isHostedAtWPcom) {
            [PrivateSiteURLProtocol registerPrivateSiteURLProtocol];
        }
        
        if ([post isRevision]
            && [post hasLocalChanges]
            && post.original.postTitle.length == 0
            && post.original.content.length == 0) {
            
            _ownsPost = YES;
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

    self.delegate = self;
    [self configureMediaUpload];
    if (self.isOpenedDirectlyForPhotoPost) {
        [self showMediaPickerAnimated:NO];
    } else if (!self.isOpenedDirectlyForEditing) {
        [self refreshNavigationBarButtons:NO];
    }
}

- (void)customizeAppearance
{
    [super customizeAppearance];
    [WPFontManager notoBoldFontOfSize:16.0];
    [WPFontManager notoBoldItalicFontOfSize:16.0];
    [WPFontManager notoItalicFontOfSize:16.0];
    [WPFontManager notoRegularFontOfSize:16.0];

    self.placeholderColor = [WPStyleGuide grey];
    self.editorView.sourceViewTitleField.font = [WPFontManager notoBoldFontOfSize:24.0];
    self.editorView.sourceContentDividerView.backgroundColor = [WPStyleGuide greyLighten30];
    [self.toolbarView setBorderColor:[WPStyleGuide greyLighten10]];
    [self.toolbarView setItemTintColor: [WPStyleGuide greyLighten10]];
    [self.toolbarView setSelectedItemTintColor: [WPStyleGuide baseDarkerBlue]];
    [self.toolbarView setDisabledItemTintColor:[UIColor colorWithRed:0.78 green:0.84 blue:0.88 alpha:0.5]];
    // Explicit design decision to use non-standard colors. See:
    // https://github.com/wordpress-mobile/WordPress-Editor-iOS/issues/657#issuecomment-113651034
    [self.toolbarView setBackgroundColor: [UIColor colorWithRed:0xF9/255.0 green:0xFB/255.0 blue:0xFC/255.0 alpha:1]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.failedStateRestorationMode) {
        [self dismissEditView:NO];
    } else {
        [self refreshNavigationBarButtons:NO];
        [self.navigationController.navigationBar addSubview:self.mediaProgressView];
        if (self.isEditing) {
            [self setNeedsStatusBarAppearanceUpdate];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.mediaProgressView removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidShowNotification
                                                  object:nil];
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
    
    BOOL restoreOnlyIfNewEditorIsEnabled = [[EditorSettings new] visualEditorEnabled];
    
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
    [super decodeRestorableStateWithCoder:coder];
    
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
    
    WPPostViewControllerMode mode = kWPPostViewControllerModePreview;
    
    if (isInEditMode) {
        mode = kWPPostViewControllerModeEdit;
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
    self.mediaProgressCoordinator = [MediaProgressCoordinator new];
    self.mediaProgressCoordinator.delegate = self;
    self.mediaProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
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
    if ([self isSingleSiteMode]) {
        [self cancelEditing];
        return;
    } else if (![self.post hasSiteSpecificChanges]) {
        [self showBlogSelector];
        return;
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Change Site", @"Title of an alert prompting the user that they are about to change the blog they are posting to.")
                                                                             message:NSLocalizedString(@"Choosing a different site will lose edits to site specific content like media and categories. Are you sure?", @"And alert message warning the user they will loose blog specific edits like categories, and media if they change the blog being posted to.")
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addDefaultActionWithTitle:NSLocalizedString(@"OK",@"") handler:^(UIAlertAction *action) {
       [self showBlogSelector]; 
    }];
    [alertController addCancelActionWithTitle:NSLocalizedString(@"Cancel",@"") handler:nil];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showBlogSelector
{
    void (^dismissHandler)() = ^(void) {
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    void (^successHandler)(NSManagedObjectID *) = ^(NSManagedObjectID *selectedObjectID) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        Blog *blog = (Blog *)[context objectWithID:selectedObjectID];
        
        if (blog) {
            RecentSitesService *recentSites = [RecentSitesService new];
            [recentSites touchBlog:blog];

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
            newPost.dateModified = oldPost.dateModified;

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
                                                                                       successHandler:successHandler
                                                                                       dismissHandler:dismissHandler];
    vc.title = NSLocalizedString(@"Select Site", @"");
    vc.displaysPrimaryBlogOnTop = YES;

    if ([WPDeviceIdentification isiPad] && ![self hasHorizontallyCompactView]) {
        [self presentBlogSelectorViewControllerAsPopover:vc];
    } else {
        [self presentBlogSelectorViewControllerAsModal:vc];
    }
}

- (void)presentBlogSelectorViewControllerAsPopover:(BlogSelectorViewController *)viewController
{
    viewController.modalPresentationStyle = UIModalPresentationPopover;
    viewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
    viewController.popoverPresentationController.backgroundColor = [WPStyleGuide greyLighten20];
    // A little extra vertical padding...
    CGFloat padding = -10;
    viewController.popoverPresentationController.sourceRect = CGRectInset(self.blogPickerButton.imageView.bounds, 0, padding);
    viewController.popoverPresentationController.sourceView = self.blogPickerButton.imageView;

    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)presentBlogSelectorViewControllerAsModal:(BlogSelectorViewController *)viewController
{
    viewController.displaysCancelButton = YES;

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    navController.navigationBar.translucent = NO;
    [self presentViewController:navController animated:YES completion:nil];
}

- (Class)classForSettingsViewController
{
    return [PostSettingsViewController class];
}

- (void)showCancelMediaUploadPrompt
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Cancel media uploads", "Dialog box title for when the user is cancelling an upload.")
                                                                             message:NSLocalizedString(@"You are currently uploading media. This action will cancel uploads in progress.\n\nAre you sure?", @"This prompt is displayed when the user attempts to stop media uploads in the post editor.")
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addDefaultActionWithTitle:NSLocalizedString(@"Yes", "Yes") handler:^(UIAlertAction *action) {
        [self cancelMediaUploads];
    }];
    [alertController addCancelActionWithTitle:NSLocalizedString(@"Not Now", "Nicer dialog answer for \"No\".") handler:nil];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showMediaUploadingAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Uploading media", @"Title for alert when trying to save/exit a post before media upload process is complete.")
                                                                             message:NSLocalizedString(@"You are currently uploading media. Please wait until this completes.", @"This is a notification the user receives if they are trying to save a post (or exit) before the media upload process is complete.")
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addDefaultActionWithTitle:NSLocalizedString(@"OK", "") handler:nil];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showFailedMediaRemovalAlertAndDismissEditorOnSave:(BOOL)shouldDismiss
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Uploads failed", @"Title for alert when trying to save post with failed media items")
                                                                             message:NSLocalizedString(@"Some media uploads failed. This action will remove all failed media from the post.\nSave anyway?", @"Confirms with the user if they save the post all media that failed to upload will be removed from it.")
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addDefaultActionWithTitle:NSLocalizedString(@"Yes", "Yes") handler:^(UIAlertAction *action) {
        [self removeAllFailedMedia];
        [self savePostAndDismiss:shouldDismiss];
    }];
    [alertController addCancelActionWithTitle:NSLocalizedString(@"Not Now", "Nicer dialog answer for \"No\".") handler:nil];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showFailedMediaBeforeEditAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Uploads failed", @"Title for alert when trying to edit html post with failed media items")
                                                                             message:NSLocalizedString(@"Some media uploads failed. Switching to the HTML view of this post will remove failed media.\nSwitch anyway?", @"Confirms with the user if they manually edit the post HTML all media that failed to upload will be removed from it.")
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addDefaultActionWithTitle:NSLocalizedString(@"Yes", "Yes") handler:^(UIAlertAction *action) {
        [self removeAllFailedMedia];
        [self.editorView showHTMLSource];
    }];
    [alertController addCancelActionWithTitle:NSLocalizedString(@"Not Now", "Nicer dialog answer for \"No\".") handler:nil];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Toolbar options

- (void)showMoreSheet
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *quickSaveAction = [self quickSaveAlertAction];
    if (quickSaveAction) {
        [alertController addAction:quickSaveAction];
    }
    
    [alertController addAction:[self previewAlertAction]];

    if ([self isEditing]) {
        [alertController addAction:[self optionsAlertAction]];
    } else {
        if ([self.post isKindOfClass:[Post class]]) {
            [alertController addAction:[self shareAlertAction]];
        }
    }

    [alertController addCancelActionWithTitle:NSLocalizedString(@"Cancel", @"Action button to close editor 'More' menu.") handler:nil];
    alertController.popoverPresentationController.barButtonItem = self.moreBarButtonItem;

    [self presentViewController:alertController animated:YES completion:^{
        // Prevents being able to tap on any other nav bar buttons during popover display
        alertController.popoverPresentationController.passthroughViews = nil;
    }];
}

- (void)sharePost
{
    if ([self.post isKindOfClass:[Post class]]) {
        Post *post = (Post *)self.post;
        
        PostSharingController *sharingController = [[PostSharingController alloc] init];
        
        [sharingController sharePost:post
                   fromBarButtonItem:self.moreBarButtonItem
                    inViewController:self];
    }
}

- (void)showSettings
{
    Post *post = (Post *)self.post;
    PostSettingsViewController *vc = [[[self classForSettingsViewController] alloc] initWithPost:post];
	vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showPreview
{
    if ([self isMediaUploading]) {
        [self showMediaUploadingAlert];
        return;
    }
    
    PostPreviewViewController *vc = [[PostPreviewViewController alloc] initWithPost:self.post];
	vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showMediaPickerAnimated:(BOOL)animated
{
    self.mediaLibraryDataSource = [[WPAndDeviceMediaLibraryDataSource alloc] initWithPost:self.post];
    WPNavigationMediaPickerViewController *picker = [[WPNavigationMediaPickerViewController alloc] init];
    picker.dataSource = self.mediaLibraryDataSource;
    picker.showMostRecentFirst = YES;
    picker.delegate = self;
    [self presentViewController:picker animated:animated completion:nil];
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
	
    if ([self.post canSave] && [self.post hasUnsavedChanges]) {
        [self showPostHasChangesAlert];
    } else {
        [self stopEditing];
        [self discardChangesAndUpdateGUI];
    }
}

- (void)showPostHasChangesAlert
{
    UIAlertController *alertController;
    alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"You have unsaved changes.", @"Title of message with options that shown when there are unsaved changes and the author is trying to move away from the post.")
                                                          message:nil
                                                   preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addActionWithTitle:NSLocalizedString(@"Keep Editing", @"Button shown if there are unsaved changes and the author is trying to move away from the post.")
                                  style:UIAlertActionStyleCancel
                                handler:^(UIAlertAction * action) {
        [self actionSheetKeepEditingButtonPressed];
    }];
    
    if ([self.post hasLocalChanges]) {
        if (![self.post hasRemote]) {
            // The post is a local draft or an autosaved draft: Discard or Save
            [alertController addActionWithTitle:NSLocalizedString(@"Save Draft", @"Button shown if there are unsaved changes and the author is trying to move away from the post.")
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {
                [self actionSheetSaveDraftButtonPressed];
            }];
        } else if ([self.post.status isEqualToString:PostStatusDraft]) {
            // The post was already a draft
            [alertController addActionWithTitle:NSLocalizedString(@"Update Draft", @"Button shown if there are unsaved changes and the author is trying to move away from an already published/saved post.")
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {
                [self actionSheetSaveDraftButtonPressed];
            }];
        }
    }
    
    [alertController addActionWithTitle:NSLocalizedString(@"Discard", @"Button shown if there are unsaved changes and the author is trying to move away from the post.")
                                  style:UIAlertActionStyleDestructive
                                handler:^(UIAlertAction * action) {
                                    [self actionSheetDiscardButtonPressed];
                                }];

    alertController.popoverPresentationController.barButtonItem = self.currentCancelButton;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)startEditing
{
    [self createRevisionOfPost];
    
    [super startEditing];
}

- (void)setEditing:(BOOL)editing
{
    [super setEditing:editing];

    [UIView animateWithDuration:0.3 animations:^{
        self.splitViewController.preferredDisplayMode = (editing) ? UISplitViewControllerDisplayModePrimaryHidden : UISplitViewControllerDisplayModeAllVisible;
    }];
}

#pragma mark - Instance Methods

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary *info = [aNotification userInfo];
    CGRect rawKeyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect kRect = [self.view convertRect:rawKeyboardRect fromView:self.view.window];
    self.keyboardRect = kRect;
}

- (void)cancelEditingOrDismiss
{
    if (self.isEditing) {
        [self cancelEditing];
    } else {
        [self dismissEditView:NO];
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
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:context];
    AbstractPost *post = [postService createDraftPostForBlog:blog];

    return post;
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
        BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
        [blogService syncBlogAndAllMetadata:blog completionHandler:nil];
    }
}

- (NSString *)editorTitle
{
    NSString *title = @"";
    if ([self.post hasNeverAttemptedToUpload]) {
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

- (BOOL)isSingleSiteMode
{
    // The blog picker is in single site mode if one of the following is true:
    // editor screen is in preview mode, there is only 1 blog, or the user
    // is editing an existing post.

    if (self.currentBlogCount <= 1 || !self.isEditing || (self.isEditing && self.post.hasRemote)) {
        return YES;
    }
    return NO;
}

- (void)setPost:(AbstractPost *)post
{
    if (_post != nil) {
        [self removePostObserver];
    }
    _post = post;
    [self setupPostObserver];
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

    if ([self isModal]) {
        self.currentCancelButton = self.cancelXButton;
    } else {
        self.currentCancelButton = self.cancelChevronButton;
    }
    leftBarButtons = @[self.negativeSeparator, self.currentCancelButton, secondaryleftHandButton];
    
    if (![leftBarButtons isEqualToArray:self.navigationItem.leftBarButtonItems]) {
        [self.navigationItem setLeftBarButtonItems:nil];
        [self.navigationItem setLeftBarButtonItems:leftBarButtons];
    }
}

- (void)refreshNavigationBarRightButtons:(BOOL)editingChanged
{
    if ([self isEditing]) {
        if (editingChanged) {
            [self.navigationItem setRightBarButtonItems:@[self.moreBarButtonItem,
                                                          self.saveBarButtonItem] animated:YES];
        } else {
            self.saveBarButtonItem.title = [self saveBarButtonItemTitle];
        }

        self.saveBarButtonItem.enabled = [self.post canSave];
	} else {
        NSMutableArray* rightBarButtons = [[NSMutableArray alloc] initWithArray:@[self.moreBarButtonItem,
                                                                                  self.editBarButtonItem]];

		[self.navigationItem setRightBarButtonItems:rightBarButtons animated:NO];
	}
}

- (void)refreshUIForCurrentPost
{
    self.titleText = self.post.postTitle;
    self.bodyText = self.post.content ?: @"";
    
    [self refreshNavigationBarButtons:YES];
}

#pragma mark - Custom UI elements

- (UIBarButtonItem *)moreBarButtonItem
{
    if (_moreBarButtonItem) {
        return _moreBarButtonItem;
    }

    UIImage *image = [Gridicon iconOfType:GridiconTypeEllipsis];
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(showMoreSheet)];
    _moreBarButtonItem = button;

    return _moreBarButtonItem;
}

- (UIBarButtonItem*)cancelChevronButton
{
    if (_cancelChevronButton) {
        return _cancelChevronButton;
    }
    
    UIImage *image = [[UIImage imageNamed:@"icon-posts-editor-chevron"] imageFlippedForRightToLeftLayoutDirection];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    WPButtonForNavigationBar* cancelButton = [WPStyleGuide buttonForBarWithImage:image
                                                                  target:self
                                                                selector:@selector(cancelEditing)];

    cancelButton.leftSpacing = 0;
    cancelButton.rightSpacing = RightSpacingOnExitNavbarButton;
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:cancelButton];
    button.accessibilityIdentifier = @"Cancel";
    button.accessibilityLabel = NSLocalizedString(@"Cancel", @"Action button to close editor and cancel changes or insertion of post");
    _cancelChevronButton = button;
    return _cancelChevronButton;
}

- (UIBarButtonItem*)cancelXButton
{
    if (_cancelXButton) {
        return _cancelXButton;
    }
    
    UIImage *image = [Gridicon iconOfType:GridiconTypeCross];
    WPButtonForNavigationBar* cancelButton = [WPStyleGuide buttonForBarWithImage:image
                                                                  target:self
                                                                selector:@selector(cancelEditing)];

    cancelButton.leftSpacing = 0;
    cancelButton.rightSpacing = RightSpacingOnExitNavbarButton;
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:cancelButton];
    _cancelXButton = button;
    button.accessibilityIdentifier = @"Cancel";
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

- (UIBarButtonItem *)saveBarButtonItem
{
    if (!_saveBarButtonItem) {
        NSString *buttonTitle = [self saveBarButtonItemTitle];

        UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:buttonTitle
                                                                       style:[WPStyleGuide barButtonStyleForDone]
                                                                      target:self
                                                                      action:@selector(saveAction:)];

        // Seems to be an issue witht the appearance proxy not being respected, so resetting these here
        [saveButton setTitleTextAttributes:EnabledButtonBarStyle forState:UIControlStateNormal];
        [saveButton setTitleTextAttributes:DisabledButtonBarStyle forState:UIControlStateDisabled];
        _saveBarButtonItem = saveButton;
    }

    return _saveBarButtonItem;
}

- (UIBarButtonItem *)secondaryLeftUIBarButtonItem
{
    UIBarButtonItem *aUIButtonBarItem;
    
    if ([self isMediaUploading]) {
        aUIButtonBarItem = self.uploadStatusButton;
    } else {
        WPBlogSelectorButton *blogButton = (WPBlogSelectorButton*)self.blogPickerButton;
        NSString *blogName = self.post.blog.settings.name;
        if (blogName.length == 0) {
            blogName = self.post.blog.url;
        }
        
        NSMutableAttributedString *titleText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", blogName]
                                                                                      attributes:@{ NSFontAttributeName : [WPFontManager systemSemiBoldFontOfSize:16.0] }];
        
        [blogButton setAttributedTitle:titleText forState:UIControlStateNormal];
        if (![self hasHorizontallyCompactView]) {
            //size to fit here so the iPad popover works properly
            [blogButton sizeToFit];
        }
        
        if ([self isSingleSiteMode]) {
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
        UIButton *button = [WPBlogSelectorButton buttonWithFrame:CGRectMake(0.0f, 0.0f, RegularTitleButtonWidth , RegularTitleButtonHeight) buttonStyle:WPBlogSelectorButtonTypeSingleLine];

        [button addTarget:self action:@selector(showBlogSelectorPrompt:) forControlEvents:UIControlEventTouchUpInside];
        _blogPickerButton = button;
    }
    
    // Update the width to the appropriate size for the horizontal size class
    CGFloat titleButtonWidth = CompactTitleButtonWidth;
    if (![self hasHorizontallyCompactView]) {
        titleButtonWidth = RegularTitleButtonWidth;
    }
    _blogPickerButton.frame = CGRectMake(_blogPickerButton.frame.origin.x, _blogPickerButton.frame.origin.y, titleButtonWidth, RegularTitleButtonHeight);
    
    return _blogPickerButton;
}

- (UIBarButtonItem *)uploadStatusButton
{
    if (!_uploadStatusButton) {
        UIButton *button = [WPUploadStatusButton buttonWithFrame:CGRectMake(0.0f, 0.0f, CompactTitleButtonWidth , RegularTitleButtonHeight)];
        button.titleLabel.text = NSLocalizedString(@"Media Uploading...", @"Message to indicate progress of uploading media to server");
        [button addTarget:self action:@selector(showCancelMediaUploadPrompt) forControlEvents:UIControlEventTouchUpInside];
        _uploadStatusButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    
    return _uploadStatusButton;
}

#pragma mark - More Action Sheet Actions

- (UIAlertAction *)shareAlertAction
{
    return [UIAlertAction actionWithTitle:NSLocalizedString(@"Share", @"Title of the share button in the Post Editor.")
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                                      [self sharePost];
                                  }];
}

- (UIAlertAction *)previewAlertAction
{
    return [UIAlertAction actionWithTitle:NSLocalizedString(@"Preview", @"Title of button to preview the content of post or page on the  live site")
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                                      [self showPreview];
                                  }];
}

- (UIAlertAction *)optionsAlertAction
{
    return [UIAlertAction actionWithTitle:NSLocalizedString(@"Options", @"Title of the Post Settings navigation button in the Post Editor. Tapping shows settings and options related to the post being edited.")
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                                      [self showSettings];
                                  }];
}

- (UIAlertAction *)quickSaveAlertAction
{
    if ([self.post.status isEqualToString:PostStatusDraft]) {
        // Self-hosted non-Jetpack blogs have no capabilities, so we'll default
        // to showing Publish Now instead of Submit for Review.
        if (!self.post.blog.capabilities || [self.post.blog isPublishingPostsAllowed]) {
            if (self.post.hasFuturePublishDate) {
                // We don't want a Publish action for a Draft scheduled for a future date
                return nil;
            } else {
                return [UIAlertAction actionWithTitle:NSLocalizedString(@"Publish Now", @"Title of button allowing the user to immediately publish the post they are editing.")
                                                style:UIAlertActionStyleDestructive
                                              handler:^(UIAlertAction * _Nonnull action) {
                                                  [self.post publishImmediately];
                                                  [self saveAction:action];
                                              }];
            }
        } else {
            return [UIAlertAction actionWithTitle:NSLocalizedString(@"Submit for Review", @"Title of button allowing a contributor to a site to submit the post they are editing for review.")
                                            style:UIAlertActionStyleDestructive
                                          handler:^(UIAlertAction * _Nonnull action) {
                                              [self.post publishImmediately];
                                              [self saveAction:action];
                                          }];
        }
    } else if (![self.post hasRemote] && [self.post.status isEqualToString:PostStatusPublish]) {
        return [UIAlertAction actionWithTitle:NSLocalizedString(@"Save as Draft", @"Title of button allowing users to change the status of the post they are currently editing to Draft.")
                                        style:UIAlertActionStyleDefault
                                      handler:^(UIAlertAction * _Nonnull action) {
                                          self.post.status = PostStatusDraft;
                                          [self saveAction:action];
                                          [self refreshNavigationBarButtons:NO];
                                      }];
    }

    return nil;
}

# pragma mark - Model State Methods

- (void)createRevisionOfPost
{
    // Using performBlock: with the AbstractPost on the main context:
    // Prevents a hang on opening this view on slow and fast devices
    // by deferring the cloning and UI update.
    // Slower devices have the effect of the content appearing after
    // a short delay
    [self.post.managedObjectContext performBlockAndWait:^{
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
    NSAssert([_post isKindOfClass:[self.class supportedPostClass]],
             @"The post should exist here.");

    NSManagedObjectContext* context = self.post.managedObjectContext;
    NSAssert([context isKindOfClass:[NSManagedObjectContext class]],
             @"The object should be related to a managed object context here.");
    
    [WPAppAnalytics track:WPAnalyticsStatEditorDiscardedChanges withProperties:@{WPAppAnalyticsKeyEditorSource: WPAppAnalyticsEditorSourceValueHybrid} withPost:self.post];
    self.post = self.post.original;
    [self.post deleteRevision];
    
    if (self.ownsPost) {
        [self.post remove];
        self.post = nil;
    }
    
    [[ContextManager sharedInstance] saveContext:context];
}

/**
 *  @brief      Discards all changes in the last editing session and updates the GUI accordingly.
 *  @details    The GUI will be affected by this method.  If you want to avoid updating the GUI you
 *              can call `discardChanges` instead.
 */
- (void)discardChangesAndUpdateGUI
{
    [self discardChanges];
    
    if (!self.post || self.isOpenedDirectlyForEditing) {
        [self dismissEditView:NO];
    } else {
        [self refreshUIForCurrentPost];
    }
}

- (void)dismissEditViewAnimated:(BOOL)animated
                   changesSaved:(BOOL)changesSaved
{
    [WPAppAnalytics track:WPAnalyticsStatEditorClosed withProperties:@{WPAppAnalyticsKeyEditorSource: WPAppAnalyticsEditorSourceValueHybrid} withPost:self.post];
    [self removePostObserver];

    if (self.onClose) {
        self.onClose(self, changesSaved);
        self.onClose = nil;
    } else if ([self isModal]) {
        [self.presentingViewController dismissViewControllerAnimated:animated completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:animated];
    }
}

- (void)dismissEditView:(BOOL)changesSaved
{
    [self dismissEditViewAnimated:YES changesSaved:changesSaved];
}

- (void)saveAction:(id)sender
{
    if (self.currentAlertController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        self.currentAlertController = nil;
    }
    
	if ([self isMediaUploading] ) {
		[self showMediaUploadingAlert];
		return;
	}

    if (sender == [self saveBarButtonItem]) {
        [self savePost];
    } else {
        [self quickSavePost];
    }
}

- (void)savePost
{
    PostEditorSaveAction saveAction = [self currentSaveAction];
    BOOL shouldDismiss = saveAction != PostEditorSaveActionSave;
    [self savePostAndDismiss:shouldDismiss];

    [self trackSavePostAnalyticsWithStat:[self analyticsStatForSaveAction:saveAction]];
}

- (void)quickSavePost
{
    switch ([self currentSaveAction]) {
        case PostEditorSaveActionSchedule:
        case PostEditorSaveActionPost:
            [self trackSavePostAnalyticsWithStat:WPAnalyticsStatEditorQuickPublishedPost];
            [self savePostAndDismiss:YES];
            break;
        case PostEditorSaveActionSave:
        case PostEditorSaveActionUpdate:
            [self trackSavePostAnalyticsWithStat:WPAnalyticsStatEditorQuickSavedDraft];
            [self savePostAndDismiss:NO];
            break;
    }
}

- (void)savePostAndDismiss:(BOOL)shouldDismiss
{
    if ([self hasFailedMedia]) {
        [self showFailedMediaRemovalAlertAndDismissEditorOnSave:shouldDismiss];
        return;
    }
    __weak __typeof__(self) weakSelf = self;
    __block NSString *postTitle = self.post.postTitle;
    __block PostEditorSaveAction currentSaveAction = self.currentSaveAction;

    void (^stopEditingAndDismiss)() = ^{
        __typeof__(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (shouldDismiss) {
            [strongSelf stopEditing];
            [strongSelf.view endEditing:YES];
            [strongSelf didSaveNewPost];
            [strongSelf dismissEditView:YES];
        } else {
            [strongSelf startEditing];
        }
    };

    DDLogMethod();

    // Make sure that we are saving the latest content on the editor.
    [self autosaveContent];

    NSString *hudText;
    switch (currentSaveAction) {
        case PostEditorSaveActionSchedule:
            hudText = NSLocalizedString(@"Scheduling...", @"Text displayed in HUD while a post is being scheduled to be published.");
            break;
        case PostEditorSaveActionUpdate:
            hudText = NSLocalizedString(@"Updating...", @"Text displayed in HUD while a published or draft post is being updated.");
            break;
        case PostEditorSaveActionPost:
            hudText = NSLocalizedString(@"Publishing...", @"Text displayed in HUD while a post is being published.");
            break;
        default:
            hudText = NSLocalizedString(@"Saving...", @"Text displayed in HUD while a post is being saved as a draft.");
            break;
    }
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD showWithStatus:hudText];

    UINotificationFeedbackGenerator *generator = [UINotificationFeedbackGenerator new];
    [generator prepare];

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:context];
    [postService uploadPost:self.post
                    success:^(AbstractPost *post) {
                        DDLogInfo(@"post uploaded: %@", postTitle);
                        __typeof__(self) strongSelf = weakSelf;
                        if (!strongSelf) {
                            return;
                        }
                        strongSelf.post = post;

                        switch (currentSaveAction) {
                            case PostEditorSaveActionSave: {
                                NSString *hudText = NSLocalizedString(@"Saved!", @"Text displayed in HUD after a post was successfully saved as a draft.");
                                [SVProgressHUD showDismissibleSuccessWithStatus:hudText];
                                break;
                            }
                            case PostEditorSaveActionUpdate: {
                                NSString *hudText = NSLocalizedString(@"Updated!", @"Text displayed in HUD after a post was successfully updated.");
                                [SVProgressHUD showDismissibleSuccessWithStatus:hudText];
                                break;
                            }
                            default:
                                [SVProgressHUD dismiss];
                                break;
                        }                        
                        [generator notificationOccurred:UINotificationFeedbackTypeSuccess];
                        stopEditingAndDismiss();
                    } failure:^(NSError *error) {
                        DDLogError(@"post failed: %@", [error localizedDescription]);
                        NSString *hudText;
                        switch (currentSaveAction) {
                            case PostEditorSaveActionSchedule:
                                hudText = NSLocalizedString(@"Error occurred\nduring scheduling. Your changes were saved on the device.", @"Text displayed in HUD after attempting to schedule a post and an error occurred.");
                                break;
                            case PostEditorSaveActionUpdate:
                                hudText = NSLocalizedString(@"Error occurred\nduring updating. Your changes were saved on the device", @"Text displayed in HUD after attempting to update a post and an error occurred.");
                                break;
                            case PostEditorSaveActionPost:
                                hudText = NSLocalizedString(@"Error occurred\nduring publishing. Your changes were saved on the device", @"Text displayed in HUD after attempting to publish a post and an error occurred.");
                                break;
                            default:
                                hudText = NSLocalizedString(@"Error occurred\nduring saving. Your changes were saved on the device.", @"Text displayed in HUD after attempting to save a draft post and an error occurred.");
                                break;
                        }
                        [SVProgressHUD showDismissibleErrorWithStatus:hudText];
                        [generator notificationOccurred:UINotificationFeedbackTypeError];
                        stopEditingAndDismiss();
                    }];
}

- (void)didSaveNewPost
{
    if ([self.post hasLocalChanges]) {
        // Only attempt to switch to the posts list if the editor was presented modally
        if ([self isModal]) {
            [[WPTabBarController sharedInstance] switchTabToPostsListForPost:self.post];
        }
    }
}

- (void)trackSavePostAnalyticsWithStat:(WPAnalyticsStat)stat
{
    if (stat == WPAnalyticsStatEditorSavedDraft || stat == WPAnalyticsStatEditorQuickSavedDraft) {
        [WPAppAnalytics track:stat withProperties:@{WPAppAnalyticsKeyEditorSource: WPAppAnalyticsEditorSourceValueHybrid} withPost:self.post];
        return;
    }

    NSInteger originalWordCount = [self.post.original.content wordCount];
    NSInteger wordCount = [self.post.content wordCount];
    
    NSMutableDictionary *properties = [NSMutableDictionary new];
    properties[WPAppAnalyticsKeyEditorSource] = WPAppAnalyticsEditorSourceValueHybrid;
    properties[@"word_count"] = @(wordCount);
    if ([self.post hasRemote]) {
        properties[@"word_diff_count"] = @(wordCount - originalWordCount);
    }

    if (stat == WPAnalyticsStatEditorPublishedPost) {
        properties[WPAnalyticsStatEditorPublishedPostPropertyCategory] = @([self.post hasCategories]);
        properties[WPAnalyticsStatEditorPublishedPostPropertyPhoto] = @([self.post hasPhoto]);
        properties[WPAnalyticsStatEditorPublishedPostPropertyTag] = @([self.post hasTags]);
        properties[WPAnalyticsStatEditorPublishedPostPropertyVideo] = @([self.post hasVideo]);
    }

    [WPAppAnalytics track:stat withProperties:properties withPost:self.post];
}

/**
 *  @brief      Save changes to core data
 */
- (void)autosaveContent
{
    self.post.postTitle = self.titleText;
    
    self.post.content = self.bodyText;
    
    if ( self.post.original.password != nil ) { //original post was password protected
        if ( self.post.password == nil || [self.post.password isEqualToString:@""] ) { //removed the password
            self.post.password = @"";
        }
    }
    
    [self.post save];
}

- (void)setupPostObserver
{
    [self.post addObserver:self forKeyPath:@"dateCreated" options:NSKeyValueObservingOptionNew context:DateChangeObserverContext];
    [self.post addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:DateChangeObserverContext];
}

- (void)removePostObserver
{
    @try {
        [self.post removeObserver:self forKeyPath:@"dateCreated"];
        [self.post removeObserver:self forKeyPath:@"status"];
    } @catch (NSException *exception) {}
}

#pragma mark - MediaProgressCoordinator

- (void)mediaProgressCoordinatorDidFinishUpload:(MediaProgressCoordinator *)mediaProgressCoordinator {    
    [self refreshNavigationBarButtons:NO];
}

- (void)mediaProgressCoordinatorDidStartUploading:(MediaProgressCoordinator *)mediaProgressCoordinator {

}

- (void)mediaProgressCoordinator:(MediaProgressCoordinator *)mediaProgressCoordinator progressDidChange:(float)progress {
    [self refreshMediaProgress];
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
    self.mediaProgressView.progress = self.mediaProgressCoordinator.totalProgress;
    for(NSString * mediaID in self.mediaProgressCoordinator.pendingUploadIDs) {
        NSProgress *progress = [self.mediaProgressCoordinator progressForMediaID:mediaID];
        if (progress) {
            [self.editorView setProgress:progress.fractionCompleted onImage:mediaID];
            [self.editorView setProgress:progress.fractionCompleted onVideo:mediaID];
        }
    }
}

- (BOOL)hasFailedMedia
{
    return [self.mediaProgressCoordinator hasFailedMedia];
}

- (BOOL)isMediaUploading
{
    return [self.mediaProgressCoordinator isRunning];
}

- (void)cancelMediaUploads
{
    [self.mediaProgressCoordinator cancelAllPendingUploads];
    for (NSString *mediaID in self.mediaProgressCoordinator.allCancelledIDs) {
        [self.editorView removeImage:mediaID];
        [self.editorView removeVideo:mediaID];
    }
    [self.mediaProgressCoordinator stopTrackingOfAllUploads];
    [self autosaveContent];
    [self refreshNavigationBarButtons:NO];
}

- (void)cancelUploadOfMediaWithId:(NSString *)uniqueMediaId
{
    [self.mediaProgressCoordinator cancelAndStopTrackOf:uniqueMediaId];
}

- (void)removeAllFailedMedia
{
    NSArray<NSString *> *faileMediaIDs = [self.mediaProgressCoordinator failedMediaIDs];
    for (NSString *key in faileMediaIDs) {
        [self.editorView removeImage:key];
        [self.editorView removeVideo:key];
    }
    [self.mediaProgressCoordinator stopTrackingAllFailedMedia];
    [self autosaveContent];
}

- (void)stopTrackingProgressOfMediaWithId:(NSString *)uniqueMediaId
{
    NSParameterAssert(uniqueMediaId != nil);
    if (!uniqueMediaId) {
        return;
    }
    [self dismissAssociatedAlertControllerIfVisible:uniqueMediaId];
    [self refreshNavigationBarButtons:NO];
}

- (void)setError:(NSError *)error inProgressOfMediaWithId:(NSString *)uniqueMediaId
{
    NSParameterAssert(uniqueMediaId != nil);
    if (!uniqueMediaId) {
        return;
    }
    [self.mediaProgressCoordinator attachWithError:error toMediaID:uniqueMediaId];
}

- (void)dismissAssociatedAlertControllerIfVisible:(NSString *)uniqueMediaId {
    // let's see if we where displaying an action sheet for this image
    if (self.currentAlertController && [uniqueMediaId isEqualToString:self.selectedMediaID]){
        [self.currentAlertController dismissViewControllerAnimated:YES completion:nil];
        self.currentAlertController = nil;
    }
}

- (void)prepareMediaProgressForNumberOfAssets:(NSUInteger)count
{
    [self.mediaProgressCoordinator trackWithNumberOfItems:count];
}

- (void)uploadMedia:(Media *)media trackingId:(NSString *)mediaUniqueId
{
    MediaService *mediaService = [[MediaService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    NSProgress *uploadProgress = nil;
    [mediaService uploadMedia:media progress:&uploadProgress success:^{
        if (media.mediaType == MediaTypeImage) {
            [self.editorView replaceLocalImageWithRemoteImage:media.remoteURL uniqueId:mediaUniqueId mediaId:[media.mediaID stringValue]];
        } else if (media.mediaType == MediaTypeVideo) {
            [self.editorView replaceLocalVideoWithID:mediaUniqueId
                                      forRemoteVideo:media.remoteURL
                                        remotePoster:media.posterAttributeImageURL
                                          videoPress:media.videopressGUID];
        }
    } failure:^(NSError *error) {
        if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
            [self stopTrackingProgressOfMediaWithId:mediaUniqueId];
            if (media.mediaType == MediaTypeImage) {
                [self.editorView removeImage:mediaUniqueId];
            } else if (media.mediaType == MediaTypeVideo) {
                [self.editorView removeVideo:mediaUniqueId];
            }
            [media remove];
        } else {
            DDLogError(@"Failed Media Upload: %@", error.localizedDescription);
            [WPAppAnalytics track:WPAnalyticsStatEditorUploadMediaFailed
                   withProperties:@{ @"error_condition": @"WPPostViewController uploadMedia:trackingID:",
                                     @"error_details": [NSString stringWithFormat:@"Uploading %@ (%@). Error: %@", media.filename, media.filesize, error.localizedDescription],
                                     WPAppAnalyticsKeyEditorSource: WPAppAnalyticsEditorSourceValueHybrid }
                         withPost:self.post];

            [self dismissAssociatedAlertControllerIfVisible:mediaUniqueId];
            if (media.mediaType == MediaTypeImage) {
                [self.editorView markImage:mediaUniqueId
                   failedUploadWithMessage:[error localizedDescription]];
            } else if (media.mediaType == MediaTypeVideo) {
                [self.editorView markVideo:mediaUniqueId
                   failedUploadWithMessage:[error localizedDescription]];
            }
            [self setError:error inProgressOfMediaWithId:mediaUniqueId];
        }
    }];

    // The service won't initialize `uploadProgress` if something goes wrong
    // during serialization, and we'll get a crash if we attempt to add a nil
    // child to mediaGlobalProgress.
    if (uploadProgress) {
        [self.mediaProgressCoordinator trackWithProgress:uploadProgress ofObject:media withMediaID:mediaUniqueId];
    }
}

- (void)retryUploadOfMediaWithId:(NSString *)imageUniqueId
{
    [WPAppAnalytics track:WPAnalyticsStatEditorUploadMediaRetried withProperties:@{WPAppAnalyticsKeyEditorSource: WPAppAnalyticsEditorSourceValueHybrid} withPost:self.post];

    Media *media = [self.mediaProgressCoordinator objectForMediaID:imageUniqueId];
    if (!media) {
        return;
    }
    
    [self prepareMediaProgressForNumberOfAssets:1];
    [self uploadMedia:media trackingId:imageUniqueId];
}

- (void)addMediaAssets:(NSArray *)assets
{
    if (assets.count == 0) {
        return;
    }
    
    [self.editorView.contentField focus];
    
    [self prepareMediaProgressForNumberOfAssets:assets.count];
    for (id<WPMediaAsset> asset in [assets reverseObjectEnumerator]) {
        if ([asset isKindOfClass:[PHAsset class]]){
            [self addDeviceMediaAsset:(PHAsset *)asset];
        } else if ([asset isKindOfClass:[Media class]]) {
            [self addSiteMediaAsset:(Media *)asset];
        }
    }
    // Need to refresh the post object. If we didn't, self.post.media would appear
    // to be unchanged causing the Media State Methods to fail.
    [self.post.managedObjectContext refreshObject:self.post mergeChanges:YES];
}

- (void)addDeviceMediaAsset:(PHAsset *)asset
{
    MediaService *mediaService = [[MediaService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    __weak __typeof__(self) weakSelf = self;
    NSString *mediaUniqueID = [self uniqueIdForMedia];
    [mediaService createMediaWithPHAsset:asset
                         forPostObjectID:self.post.objectID
                       thumbnailCallback:^(NSURL *thumbnailURL) {
                           __typeof__(self) strongSelf = weakSelf;
                           if (!strongSelf) {
                               return;
                           }
                           [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                               if (asset.mediaType == PHAssetMediaTypeImage) {
                                   [strongSelf.editorView insertLocalImage:thumbnailURL.path uniqueId:mediaUniqueID];
                               } else if (asset.mediaType == PHAssetMediaTypeVideo) {
                                   [strongSelf.editorView insertInProgressVideoWithID:mediaUniqueID usingPosterImage:thumbnailURL.path];
                               }
                           }];
                       }
                              completion:^(Media *media, NSError *error){
                                  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                      __typeof__(self) strongSelf = weakSelf;
                                      if (!strongSelf) {
                                          return;
                                      }
                                      if (error || !media || !media.absoluteLocalURL) {
                                          [strongSelf.editorView removeImage:mediaUniqueID];
                                          [strongSelf.editorView removeVideo:mediaUniqueID];
                                          [strongSelf stopTrackingProgressOfMediaWithId:mediaUniqueID];
                                          [WPError showAlertWithTitle:NSLocalizedString(@"Failed to export media",
                                                                                        @"The title for an alert that says to the user the media (image or video) he selected couldn't be used on the post.")
                                                              message:error.localizedDescription];
                                          return;
                                      }
                                      if (media.mediaType == MediaTypeImage) {
                                          [WPAppAnalytics track:WPAnalyticsStatEditorAddedPhotoViaLocalLibrary
                                                 withProperties:[WPAppAnalytics propertiesFor:media]
                                                       withPost:self.post];
                                      } else if (media.mediaType == MediaTypeVideo) {
                                          [WPAppAnalytics track:WPAnalyticsStatEditorAddedVideoViaLocalLibrary
                                                 withProperties:[WPAppAnalytics propertiesFor:media]
                                                       withPost:self.post];
                                      }
                                      [strongSelf uploadMedia:media trackingId:mediaUniqueID];                                      
                                  }];
                              }];
}

- (void)addSiteMediaAsset:(Media *)media
{
    NSString *mediaUniqueID = [self uniqueIdForMedia];
    if ([media hasRemote]) {
        if ([media mediaType] == MediaTypeImage) {
            [WPAppAnalytics track:WPAnalyticsStatEditorAddedPhotoViaWPMediaLibrary withProperties:@{WPAppAnalyticsKeyEditorSource: WPAppAnalyticsEditorSourceValueHybrid} withPost:self.post];
            [self.editorView insertLocalImage:media.remoteURL uniqueId:mediaUniqueID];
            [self.editorView replaceLocalImageWithRemoteImage:media.remoteURL uniqueId:mediaUniqueID mediaId:[media.mediaID stringValue]];
        } else if ([media mediaType] == MediaTypeVideo) {
            [WPAppAnalytics track:WPAnalyticsStatEditorAddedVideoViaWPMediaLibrary withProperties:@{WPAppAnalyticsKeyEditorSource: WPAppAnalyticsEditorSourceValueHybrid} withPost:self.post];
            [self.editorView insertInProgressVideoWithID:[media.mediaID stringValue] usingPosterImage:media.absoluteThumbnailLocalURL.path];
            [self.editorView replaceLocalVideoWithID:[media.mediaID stringValue] forRemoteVideo:media.remoteURL remotePoster:media.posterAttributeImageURL videoPress:media.videopressGUID];
        }
        [self.mediaProgressCoordinator finishOneItem];
    } else {
        if ([media mediaType] == MediaTypeImage) {
            [WPAppAnalytics track:WPAnalyticsStatEditorAddedPhotoViaLocalLibrary
                   withProperties:[WPAppAnalytics propertiesFor:media]
                         withPost:self.post];
            [self.editorView insertLocalImage:media.absoluteLocalURL.path uniqueId:mediaUniqueID];
        } else if ([media mediaType] == MediaTypeVideo) {
            [WPAppAnalytics track:WPAnalyticsStatEditorAddedVideoViaLocalLibrary
                   withProperties:[WPAppAnalytics propertiesFor:media]
                         withPost:self.post];
            [self.editorView insertInProgressVideoWithID:mediaUniqueID usingPosterImage:media.posterAttributeImageURL];
        }
        [self uploadMedia:media trackingId:mediaUniqueID];
    }
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
    if (![self.post hasRemote] && (self.post.isScheduled || [self.post.status isEqualToString:PostStatusPublish])) {
        self.post.status = PostStatusDraft;
    }
    
    DDLogInfo(@"Saving post as a draft after user initially attempted to cancel");
    
    [self savePostAndDismiss:YES];
    [self trackSavePostAnalyticsWithStat:WPAnalyticsStatEditorSavedDraft];
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
    [self showMediaPickerAnimated:YES];
}

- (void)editorDidPressPreview:(WPEditorViewController *)editorController
{
    [self showPreview];
}

- (void)editorDidFinishLoadingDOM:(WPEditorViewController *)editorController
{
    [self.editorView setImageEditText:NSLocalizedString(@"Edit",
                                                        @"Title of the edit-image button in the post editor.")];
    
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

- (void)editorViewController:(WPEditorViewController *)editorViewController imagePasted:(UIImage *)image
{
    MediaService *mediaService = [[MediaService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    __weak __typeof__(self) weakSelf = self;
    NSString *mediaUniqueID = [self uniqueIdForMedia];
    [mediaService createMediaWithImage:image
                           withMediaID:mediaUniqueID
                       forPostObjectID:self.post.objectID
                     thumbnailCallback:^(NSURL *thumbnailURL) {
                         __typeof__(self) strongSelf = weakSelf;
                         if (!strongSelf) {
                             return;
                         }
                         [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                             [strongSelf.editorView insertLocalImage:thumbnailURL.path uniqueId:mediaUniqueID];
                         }];
                     }
                            completion:^(Media *media, NSError *error) {
                                __typeof__(self) strongSelf = weakSelf;
                                if (!strongSelf) {
                                    return;
                                }
                                if (error || !media || !media.absoluteLocalURL) {
                                    [strongSelf stopTrackingProgressOfMediaWithId:mediaUniqueID];
                                    [WPError showAlertWithTitle:NSLocalizedString(@"Failed to paste image",
                                                                                  @"The title for an alert that says to the user the image they pasted couldn't be used on the post.")
                                                        message:error.localizedDescription];
                                    return;
                                }
                                [strongSelf uploadMedia:media trackingId:mediaUniqueID];
                            }];
    
    [self.post.managedObjectContext refreshObject:self.post mergeChanges:YES];
    [WPAppAnalytics track:WPAnalyticsStatEditorAddedPhotoViaLocalLibrary withProperties:@{WPAppAnalyticsKeyEditorSource: WPAppAnalyticsEditorSourceValueHybrid} withPost:self.post];
}


- (void)editorViewController:(WPEditorViewController *)editorViewController
                 imageTapped:(NSString *)imageId
                         url:(NSURL *)url
                   imageMeta:(WPImageMeta *)imageMeta
{
    // Note: imageId is an editor specified data attribute, not the image's ID attribute.
    if (imageId.length == 0) {
        [self displayImageDetailsForMeta:imageMeta url:url];
    } else {
        [self promptForActionForTappedMedia:imageId url:url];
    }
}

- (void)editorViewController:(WPEditorViewController *)editorViewController
                 videoTapped:(NSString *)videoID
                         url:(NSURL *)url
{
    if (videoID.length > 0) {
        [self promptForActionForTappedMedia:videoID url:url];
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
                               url:(NSURL *)url
{
    [WPAppAnalytics track:WPAnalyticsStatEditorEditedImage withProperties:@{WPAppAnalyticsKeyEditorSource: WPAppAnalyticsEditorSourceValueHybrid} withPost:self.post];

    Media *media = [Media existingMediaWithRemoteURL:[url absoluteString]
                                              inBlog:self.post.blog];

    EditImageDetailsViewController *controller = [EditImageDetailsViewController controllerForDetails:imageMeta
                                                                                                media:media
                                                                                              forPost:self.post];
    controller.delegate = self;

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)promptForActionForTappedMedia:(NSString *)mediaId url:(NSURL *)url
{
    if (mediaId.length == 0) {
        return;
    }
    
    self.selectedMediaID = mediaId;

    if (![self.mediaProgressCoordinator isMediaUploadingWithMediaID:mediaId] && ![self.mediaProgressCoordinator errorForMediaID:mediaId]){
        // The image is already uploaded so nothing to here, but in the future we could plug in image actions here
        return;
    }

    //Are we showing another action sheet?
    if (self.currentAlertController != nil){
        return;
    }
    NSString *title = nil;
    NSString *message = nil;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    // Is upload still going?
    if ([self.mediaProgressCoordinator isMediaUploadingWithMediaID:mediaId]) {
        [alertController addActionWithTitle:NSLocalizedString(@"Cancel", @"User action to dismiss stop upload question")
                                      style:UIAlertActionStyleCancel
                                    handler:^(UIAlertAction *action) {
                                        self.selectedMediaID = nil;
                                        self.currentAlertController = nil;
                                    }];
        [alertController addActionWithTitle:NSLocalizedString(@"Stop Upload",@"User action to stop upload")
                                      style:UIAlertActionStyleDestructive
                                    handler:^(UIAlertAction *action) {
                                        [self cancelUploadOfMediaWithId:self.selectedMediaID];
                                        self.selectedMediaID = nil;
                                        self.currentAlertController = nil;
                                    }];
    } else {

        NSError *errorDetails = [self.mediaProgressCoordinator errorForMediaID:mediaId];
        if (errorDetails) {
            title = NSLocalizedString(@"Media upload failed", @"Title for action sheet for failed media");
            message = errorDetails.localizedDescription;
        }
        [alertController addActionWithTitle:NSLocalizedString(@"Cancel", @"User action to dismiss retry upload question")
                                      style:UIAlertActionStyleCancel
                                    handler:^(UIAlertAction *action) {
                                        self.selectedMediaID = nil;
                                        self.currentAlertController = nil;
                                    }];
        [alertController addActionWithTitle:NSLocalizedString(@"Remove Media", @"User action to remove media that failed upload")
                                      style:UIAlertActionStyleDestructive
                                    handler:^(UIAlertAction *action) {
                                        [self stopTrackingProgressOfMediaWithId:self.selectedMediaID];
                                        [self.editorView removeImage:self.selectedMediaID];
                                        [self.editorView removeVideo:self.selectedMediaID];
                                        self.selectedMediaID = nil;
                                        self.currentAlertController = nil;
                                    }];


        [alertController addActionWithTitle:NSLocalizedString(@"Retry Upload", @"User action to retry upload the image")
                                      style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction *action) {
                                        [self.editorView unmarkImageFailedUpload:self.selectedMediaID];
                                        [self.editorView unmarkVideoFailedUpload:self.selectedMediaID];
                                        [self retryUploadOfMediaWithId:self.selectedMediaID];
                                        self.selectedMediaID = nil;
                                        self.currentAlertController = nil;
                                    }];
    }
    self.currentAlertController = alertController;
    alertController.title = title;
    alertController.message = message;
    alertController.popoverPresentationController.sourceView = self.editorView;
    alertController.popoverPresentationController.sourceRect = CGRectMake(self.editorView.center.x, self.editorView.center.y, 1, 1);
    alertController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
    [self presentViewController:alertController animated:YES completion:nil];

}

#pragma mark - WPMediaPickerViewControllerDelegate

- (void)mediaPickerController:(WPMediaPickerViewController *)picker didFinishPickingAssets:(NSArray *)assets
{
    [self.editorView.focusedField focus];
    [self dismissViewControllerAnimated:YES completion:^{
        [self addMediaAssets:assets];
    }];
}

- (void)mediaPickerControllerDidCancel:(WPMediaPickerViewController *)picker
{
    if (self.isOpenedDirectlyForPhotoPost) {
        [self dismissEditViewAnimated:NO changesSaved:NO];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.editorView.focusedField focus];
    }
}

- (BOOL)mediaPickerController:(WPMediaPickerViewController *)picker shouldSelectAsset:(id<WPMediaAsset>)mediaAsset
{
    if ([mediaAsset isKindOfClass:[Media class]]){
        return YES;
    }
    if ([mediaAsset isKindOfClass:[PHAsset class]]){        
        return YES;
    }
    
    return NO;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {    
    if (context == DateChangeObserverContext) {
        [self refreshNavigationBarButtons:NO];
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

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationSlide;
}

@end
