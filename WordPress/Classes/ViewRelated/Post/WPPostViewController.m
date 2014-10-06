#import "WPPostViewController.h"
#import "WPPostViewController_Internal.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <WordPress-iOS-Shared/NSString+Util.h>
#import <WordPress-iOS-Shared/UIImage+Util.h>
#import <WordPress-iOS-Shared/WPFontManager.h>
#import <WordPress-iOS-Shared/WPStyleGuide.h>
#import <WordPressCom-Analytics-iOS/WPAnalytics.h>
#import "ContextManager.h"
#import "Post.h"
#import "WPTableViewCell.h"
#import "BlogSelectorViewController.h"
#import "WPBlogSelectorButton.h"
#import "LocationService.h"
#import "BlogService.h"
#import "MediaService.h"
#import "WPMediaUploader.h"
#import "WPButtonForNavigationBar.h"
#import "WPUploadStatusView.h"


NSString *const WPEditorNavigationRestorationID = @"WPEditorNavigationRestorationID";
NSString *const WPAbstractPostRestorationKey = @"WPAbstractPostRestorationKey";
NSString *const kUserDefaultsNewEditorAvailable = @"kUserDefaultsNewEditorAvailable";
NSString *const kUserDefaultsNewEditorEnabled = @"kUserDefaultsNewEditorEnabled";

// Secret URL config parameters
NSString *const kWPEditorConfigURLParamAvailable = @"available";
NSString *const kWPEditorConfigURLParamEnabled = @"enabled";

static NSInteger const MaximumNumberOfPictures = 5;
static CGFloat const kNavigationBarButtonSpacer = 15.0;
static NSUInteger const kWPPostViewControllerSaveOnExitActionSheetTag = 201;
static NSDictionary *kDisabledButtonBarStyle;
static NSDictionary *kEnabledButtonBarStyle;

@interface WPPostViewController ()<UIPopoverControllerDelegate> {
    NSOperationQueue *_mediaUploadQueue;
}

@property (nonatomic, strong) UIButton *titleBarButton;
@property (nonatomic, strong) UIView *uploadStatusView;
@property (nonatomic, strong) UIPopoverController *blogSelectorPopover;
@property (nonatomic) BOOL dismissingBlogPicker;
@property (nonatomic) CGPoint scrollOffsetRestorePoint;

#pragma mark - Bar Button Items
@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@property (nonatomic, strong) UIBarButtonItem *editBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *saveBarButtonItem;

@end

@implementation WPPostViewController

#pragma mark - Initializers & dealloc

- (void)dealloc
{
    _failedMediaAlertView.delegate = nil;
    [_mediaUploadQueue removeObserver:self forKeyPath:@"operationCount"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithDraftForLastUsedBlog
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
	
    Blog *blog = [blogService lastUsedOrFirstBlog];
    [self syncOptionsIfNecessaryForBlog:blog afterBlogChanged:YES];

    Post *post = [Post newDraftForBlog:blog];
    return [self initWithPost:post
						 mode:kWPPostViewControllerModeEdit];
}

- (id)initWithPost:(AbstractPost *)post
			  mode:(WPPostViewControllerMode)mode
{
    self = [super initWithMode:mode];
	
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

#pragma mark - UIViewControllerRestoration

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents
															coder:(NSCoder *)coder
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

#pragma mark - Media upload configuration

- (void)configureMediaUploadQueue
{
    _mediaUploadQueue = [NSOperationQueue new];
    _mediaUploadQueue.maxConcurrentOperationCount = 4;
    [_mediaUploadQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    kDisabledButtonBarStyle = @{NSFontAttributeName: [WPStyleGuide regularTextFont], NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.25]};
    kEnabledButtonBarStyle = @{NSFontAttributeName: [WPStyleGuide regularTextFont], NSForegroundColorAttributeName: [UIColor whiteColor]};
    
    [self createRevisionOfPost];
    [self removeIncompletelyUploadedMediaFilesAsAResultOfACrash];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(insertMediaBelow:)
                                                 name:MediaShouldInsertBelowNotification
                                               object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(removeMedia:)
                                                 name:@"ShouldRemoveMedia"
                                               object:nil];
    
    [self geotagNewPost];
    self.delegate = self;
	
    // Display the "back" chevron without text
    self.navigationController.navigationBar.topItem.title = @"";
    [self refreshNavigationBar:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self refreshNavigationBarButtons:NO];
	if (self.isEditing) {
		if ([self shouldHideStatusBarWhileTyping]) {
			[[UIApplication sharedApplication] setStatusBarHidden:YES
													withAnimation:UIStatusBarAnimationSlide];
		}
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[[UIApplication sharedApplication] setStatusBarHidden:NO
											withAnimation:UIStatusBarAnimationSlide];
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
	vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showPreview
{
    PostPreviewViewController *vc = [[PostPreviewViewController alloc] initWithPost:self.post shouldHideStatusBar:self.isEditing];
	vc.hidesBottomBarWhenPushed = YES;
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

#pragma mark - Editing

- (void)cancelEditing
{
    if (_currentActionSheet) return;
    
	[self stopEditing];
    [self.postSettingsViewController endEditingAction:nil];
	
	if ([self isMediaInUploading]) {
		[self showMediaInUploadingAlert];
		return;
	}
    
    if (![self hasChanges]) {
        [WPAnalytics track:WPAnalyticsStatEditorClosed];
		
		if (self.editMode == EditPostViewControllerModeNewPost) {
			[self discardChangesAndDismiss];
		} else {
            [self refreshNavigationBar:YES];
            [self discardChanges];
		}
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
    
    actionSheet.tag = kWPPostViewControllerSaveOnExitActionSheetTag;
    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    if (IS_IPAD) {
        [actionSheet showFromBarButtonItem:self.cancelButton animated:YES];
    } else {
        [actionSheet showFromToolbar:self.navigationController.toolbar];
    }
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

- (void)refreshNavigationBar:(BOOL)editingChanged
{
    [self refreshNavigationBarButtons:editingChanged];
	
    // Configure the custom title view, or just set the navigationItem title.
    // Only show the blog selector in the nav title view if we're editing a new post
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    NSInteger blogCount = [blogService blogCountForAllAccounts];
    
    if (_mediaUploadQueue.operationCount > 0) {
        self.navigationItem.titleView = self.uploadStatusView;
    } else if(blogCount <= 1 || self.editMode == EditPostViewControllerModeEditPost || [[WordPressAppDelegate sharedWordPressApplicationDelegate] isNavigatingMeTab]) {
        self.navigationItem.titleView = nil;
    } else {
        UIButton *titleButton = self.titleBarButton;
        self.navigationItem.titleView = titleButton;
        
        
        NSString *blogName = [self.post.blog.blogName length] == 0 ? self.post.blog.url : self.post.blog.blogName;
        
        NSMutableAttributedString *titleText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", blogName]
                                                                                      attributes:@{ NSFontAttributeName : [WPFontManager openSansBoldFontOfSize:14.0] }];

        [titleButton setAttributedTitle:titleText forState:UIControlStateNormal];
        
        [titleButton sizeToFit];
    }
}

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
}

- (void)refreshNavigationBarLeftButtons:(BOOL)editingChanged
{
	if ([self isEditing] && !self.post.hasRemote) {
        // Editing a new post
        [self.navigationItem setLeftBarButtonItems:nil];
        UIBarButtonItem *negativeSeparator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                           target:nil
                                                                                           action:nil];
        negativeSeparator.width = -10;
        NSArray* leftBarButtons = @[negativeSeparator, self.cancelXButton, negativeSeparator];
        [self.navigationItem setLeftBarButtonItems:leftBarButtons animated:NO];
    } else if ([self isEditing] && self.post.hasRemote) {
        // Editing an existing post (draft or published)
        [self.navigationItem setLeftBarButtonItems:nil];
        UIBarButtonItem *negativeSeparator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                           target:nil
                                                                                           action:nil];
        negativeSeparator.width = -10;
        NSArray* leftBarButtons = @[negativeSeparator, self.cancelChevronButton, negativeSeparator];
        [self.navigationItem setLeftBarButtonItems:leftBarButtons animated:NO];
	} else {
        [self.navigationItem setLeftBarButtonItems:nil];
        [self.navigationItem setLeftBarButtonItem:self.navigationItem.backBarButtonItem animated:NO];
	}
}

- (void)refreshNavigationBarRightButtons:(BOOL)editingChanged
{
    UIBarButtonItem *separator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                               target:nil
                                                                               action:nil];
    separator.width = kNavigationBarButtonSpacer;
    
    if ([self isEditing]) {
        if (editingChanged) {
            NSArray* rightBarButtons = @[self.saveBarButtonItem,
                                         separator,
                                         [self optionsBarButtonItem],
                                         separator,
                                         [self previewBarButtonItem]];
            
            [self.navigationItem setRightBarButtonItems:rightBarButtons animated:YES];
        } else {
            self.saveBarButtonItem.title = [self saveBarButtonItemTitle];
        }

		BOOL updateEnabled = self.hasChanges || self.post.remoteStatus == AbstractPostRemoteStatusFailed;
		[self.navigationItem.rightBarButtonItem setEnabled:updateEnabled];
		
		// Seems to be a bug with UIBarButtonItem respecting the UIControlStateDisabled text color
		NSDictionary *titleTextAttributes;
		UIColor *color = updateEnabled ? [UIColor whiteColor] : [UIColor colorWithWhite:1.0 alpha:0.5];
		UIControlState controlState = updateEnabled ? UIControlStateNormal : UIControlStateDisabled;
		titleTextAttributes = @{NSFontAttributeName: [WPStyleGuide regularTextFont], NSForegroundColorAttributeName : color};
		[self.navigationItem.rightBarButtonItem setTitleTextAttributes:titleTextAttributes forState:controlState];
	} else {
		NSArray* rightBarButtons = @[self.editBarButtonItem,
                                     separator, separator,
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
}

/**
 *	@brief		Returns a BOOL specifying if the status bar should be hidden while typing.
 *	@details	The status bar should never hide on the iPad.
 *
 *	@returns	YES if the keyboard should be hidden, NO otherwise.
 */
- (BOOL)shouldHideStatusBarWhileTyping
{
    /*
     Never hide for the iPad.
     Always hide on the iPhone except for portrait + external keyboard
     */
    if (IS_IPAD) {
        return NO;
    }
    return YES;
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
    WPButtonForNavigationBar* cancelButton = [self buttonForBarWithImageNamed:@"icon-posts-editor-chevron"
                                                                        frame:CGRectMake(0.0f, 0.0f, 40.0f, 40.0f)
                                                                       target:self
                                                                     selector:@selector(cancelEditing)];
    cancelButton.removeDefaultLeftSpacing = YES;
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:cancelButton];
    _cancelButton = button;
    return _cancelButton;
}

- (UIBarButtonItem*)cancelXButton
{
    WPButtonForNavigationBar* cancelButton = [self buttonForBarWithImageNamed:@"icon-posts-editor-x"
                                                                        frame:CGRectMake(0.0f, 0.0f, 40.0f, 40.0f)
                                                                       target:self
                                                                     selector:@selector(cancelEditing)];
    cancelButton.removeDefaultLeftSpacing = YES;        
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:cancelButton];
    _cancelButton = button;
	return _cancelButton;
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
        [editButton setTitleTextAttributes:kEnabledButtonBarStyle forState:UIControlStateNormal];
        [editButton setTitleTextAttributes:kDisabledButtonBarStyle forState:UIControlStateDisabled];
        _editBarButtonItem = editButton;
    }
    
	return _editBarButtonItem;
}

- (UIBarButtonItem *)optionsBarButtonItem
{
	WPButtonForNavigationBar *button = [self buttonForBarWithImageNamed:@"icon-posts-editor-options"
																  frame:CGRectMake(0.0f, 0.0f, 40.0f, 40.0f)
																 target:self
															   selector:@selector(showSettings)];

	button.removeDefaultRightSpacing = YES;
	button.rightSpacing = 5.0f;
	
	UIBarButtonItem* barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
	
	return barButtonItem;
}

- (UIBarButtonItem *)previewBarButtonItem
{
	WPButtonForNavigationBar* button = [self buttonForBarWithImageNamed:@"icon-posts-editor-preview"
                                                                  frame:CGRectMake(0.0f, 0.0f, 40.0f, 40.0f)
																 target:self
															   selector:@selector(showPreview)];
	
	button.removeDefaultRightSpacing = YES;
	
	UIBarButtonItem* barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
	
	return barButtonItem;
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
        [saveButton setTitleTextAttributes:kEnabledButtonBarStyle forState:UIControlStateNormal];
        [saveButton setTitleTextAttributes:kDisabledButtonBarStyle forState:UIControlStateDisabled];
        _saveBarButtonItem = saveButton;
    }

	return _saveBarButtonItem;
}

- (NSString*)saveBarButtonItemTitle
{
    NSString *buttonTitle = nil;
    
    if(![self.post hasRemote] || ![self.post.status isEqualToString:self.post.original.status]) {
        if ([self.post.status isEqualToString:@"publish"] && ([self.post.dateCreated compare:[NSDate date]] == NSOrderedDescending)) {
            buttonTitle = NSLocalizedString(@"Schedule", @"Schedule button, this is what the Publish button changes to in the Post Editor if the post has been scheduled for posting later.");
            
        } else if ([self.post.status isEqualToString:@"publish"]){
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

- (UIButton *)titleBarButton
{
    if (_titleBarButton) {
        return _titleBarButton;
    }
    UIButton *titleButton = [WPBlogSelectorButton buttonWithType:UIButtonTypeSystem];
    titleButton.frame = CGRectMake(0.0f, 0.0f, 200.0f, 33.0f);
    titleButton.titleLabel.numberOfLines = 1;
    titleButton.titleLabel.textColor = [UIColor whiteColor];
    titleButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    titleButton.titleLabel.adjustsFontSizeToFitWidth = NO;
    titleButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
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

- (void)discardChanges
{
    [self.post.original deleteRevision];
    
    if (self.editMode == EditPostViewControllerModeNewPost) {
        [self.post.original remove];
    }
}

- (void)discardChangesAndDismiss
{
    [self discardChanges];
    [self dismissEditView];
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
    
	[self savePostAndDismissVC];
}

/**
 *	@brief		Saves the post being edited and closes this VC.
 */
- (void)savePostAndDismissVC
{
	[self savePost];
    [self dismissEditView];
}

/**
 *	@brief		Saves the post being edited and uploads it.
 */
- (void)savePost
{
    DDLogMethod();
    [self logSavePostStats];

    [self.view endEditing:YES];
    
    [self.post.original applyRevision];
    [self.post.original deleteRevision];
    
	NSString *postTitle = self.post.original.postTitle;
	[self.post.original uploadWithSuccess:^{
		DDLogInfo(@"post uploaded: %@", postTitle);
	} failure:^(NSError *error) {
		DDLogError(@"post failed: %@", [error localizedDescription]);
	}];
	
    [self didSaveNewPost];
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
    NSAssert(_post != nil, @"The post should not be nil here.");
    NSAssert(!_post.isFault, @"The post should not be a fault here here.");
    NSAssert(_post.managedObjectContext != nil,
             @"The post's MOC should not be nil here.");
    
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
			[self savePostAndDismissVC];
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
    if ([actionSheet tag] == kWPPostViewControllerSaveOnExitActionSheetTag) {
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            [self actionSheetDiscardButtonPressed];
        } else if (buttonIndex == actionSheet.cancelButtonIndex) {
            [self actionSheetKeepEditingButtonPressed];
        } else if (buttonIndex == actionSheet.firstOtherButtonIndex) {
            [self actionSheetSaveDraftButtonPressed];
        }
    }
    
    _currentActionSheet = nil;
}

#pragma mark - UIActionSheet helper methods

- (void)actionSheetDiscardButtonPressed
{
    [self discardChangesAndDismiss];
    [WPAnalytics track:WPAnalyticsStatEditorDiscardedChanges];
}

- (void)actionSheetKeepEditingButtonPressed
{
    [self startEditing];
}

- (void)actionSheetSaveDraftButtonPressed
{
    if (![self.post hasRemote] && [self.post.status isEqualToString:@"publish"]) {
        self.post.status = @"draft";
    }
    DDLogInfo(@"Saving post as a draft after user initially attempted to cancel");
    [self savePostAndDismissVC];
}

#pragma mark - WPEditorViewControllerDelegate delegate

- (void)editorDidBeginEditing:(WPEditorViewController *)editorController
{
	if ([self shouldHideStatusBarWhileTyping])
	{
		[[UIApplication sharedApplication] setStatusBarHidden:YES
												withAnimation:UIStatusBarAnimationSlide];
	}
    
    [self refreshNavigationBarButtons:YES];
}

- (void)editorDidEndEditing:(WPEditorViewController *)editorController
{
	[[UIApplication sharedApplication] setStatusBarHidden:NO
											withAnimation:UIStatusBarAnimationSlide];
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

#pragma mark - CTAssetsPickerController delegate

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets
{
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
    
    // Need to refresh the post object. If we didn't, self.post.media would appear
    // to be unchanged causing the Media State Methods to fail.
    [self.post.managedObjectContext refreshObject:self.post mergeChanges:YES];
}

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldSelectAsset:(ALAsset *)asset
{
    if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypePhoto) {
        return picker.selectedAssets.count < MaximumNumberOfPictures;
    } else {
        return YES;
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:_mediaUploadQueue]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshNavigationBar:NO];
        });
    }
}

@end
