#import <UIKit/UIKit.h>
#import <WordPress-iOS-Editor/WPEditorViewController.h>

@class AbstractPost;
@class Blog;
@class PostSettingsViewController;

typedef enum
{
	kWPPostViewControllerModePreview = kWPEditorViewControllerModePreview,
	kWPPostViewControllerModeEdit = kWPEditorViewControllerModeEdit,
}
WPPostViewControllerMode;

extern const CGRect NavigationBarButtonRect;

extern NSString* const WPEditorNavigationRestorationID;
extern NSString* const kUserDefaultsNewEditorEnabled;

// Secret URL config parameters
extern NSString* const kWPEditorConfigURLParamAvailable;
extern NSString* const kWPEditorConfigURLParamEnabled;

@interface WPPostViewController : WPEditorViewController <UINavigationControllerDelegate, WPEditorViewControllerDelegate>

/*
 EditPostViewController instance will execute the onClose callback, if provided, whenever the UI is dismissed.
 */
typedef void (^EditPostCompletionHandler)(void);
@property (nonatomic, copy, readwrite) EditPostCompletionHandler onClose;

#pragma mark - Properties: Post

/**
 *  @brief      Wether this VC owns the post or not.
 *  @details    This is set to YES when this VC is initialized with one of the draft post creation
 *              initializers.  It means this VC will delete the post objects if changes are
 *              discarded by the user.
 */
@property (nonatomic, assign, readonly) BOOL ownsPost;

/**
 *  @brief      The post that's being displayed by this VC.
 */
@property (nonatomic, strong) AbstractPost *post;

#pragma mark - Properties: Misc

@property (nonatomic, strong) PostSettingsViewController *postSettingsViewController;
@property (readonly) BOOL hasChanges;

@property (nonatomic, strong) UIActionSheet *currentActionSheet;
@property (nonatomic, strong) UIAlertView *failedMediaAlertView;

#pragma mark - Initializers

/*
 Compose a new post with the last used blog.
 */
- (id)initWithDraftForLastUsedBlog;

/**
 *  @brief      Initializes the editor with a new draft for the specified blog.
 *
 *  @param      blog    The blog to create the new draft for.  Cannot be nil.
 *
 *  @returns    The initialized object.
 */
- (instancetype)initWithDraftForBlog:(Blog*)blog;

/*
 Initialize the editor with the specified post and default to preview mode.
 
 @param		post		The post to edit.  Cannot be nil.
 
 @returns	The initialized object.
 */
- (id)initWithPost:(AbstractPost *)post;

/*
 Initialize the editor with the specified post.
 
 @param		post		The post to edit.  Cannot be nil.
 @param		mode		The mode this VC will open in.
 
 @returns	The initialized object.
 */
- (id)initWithPost:(AbstractPost *)post
			  mode:(WPPostViewControllerMode)mode;

/*
 Compose a new post with the specified properties.
 The new post will belong to the last edited blog.
 
 @param title The title of the post
 @param content The post body.
 @param tags A comma separated list of tags.
 @param image A string that is either a URL path, or a base64 encoded image. If a URL path, 
 the image will appear at the top of the post with a link pointing to the image at its original location.
 If a valid base64 encoded image is provided, the image will be treated like other media items in the app. 
 */
- (id)initWithTitle:(NSString *)title
         andContent:(NSString *)content
            andTags:(NSString *)tags
           andImage:(NSString *)image;


#pragma mark - Visual editor in settings

/**
 *	@brief		Check if the new editor is available in the app settings.
 *
 *	@return		YES if the new editor is available in the app settings, NO otherwise.
 */
+ (BOOL)isNewEditorAvailable;

/**
 *	@brief		Check if the new editor is enabled.
 *
 *	@return		YES if the new editor is enabled, NO otherwise.
 */
+ (BOOL)isNewEditorEnabled;

/**
 *  @brief      Makes sure the new editor is available.
 *
 *  @returns    YES if the editor was made available, NO otherwise.
 */
+ (BOOL)makeNewEditorAvailable;

/**
 *	@brief		Makes the new editor available in the app settings.
 *	@details	This is set to NO by default.
 *
 *	@param		isAvailable		YES means the new editor will be available in the app settings.
 */
+ (void)setNewEditorAvailable:(BOOL)isAvailable;

/**
 *	@brief		Enables the new editor.
 *	@details	This is set to NO by default.
 *
 *	@param		isAvailable		YES means the new editor will be enabled.
 */
+ (void)setNewEditorEnabled:(BOOL)isEnabled;

#pragma mark - Misc methods

- (void)didSaveNewPost;

@end
