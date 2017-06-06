#import <UIKit/UIKit.h>
#import <WordPressEditor/WPEditorViewController.h>

NS_ASSUME_NONNULL_BEGIN

@class AbstractPost;
@class Blog;
@class PostSettingsViewController;

typedef NS_ENUM(NSInteger, WPPostViewControllerMode)
{
	kWPPostViewControllerModePreview = kWPEditorViewControllerModePreview,
	kWPPostViewControllerModeEdit = kWPEditorViewControllerModeEdit,
};

extern NSString* const kUserDefaultsNewEditorEnabled;

extern NSString* const WPPostViewControllerOptionOpenMediaPicker;
extern NSString* const WPPostViewControllerOptionNotAnimated;

// Secret URL config parameters
extern NSString* const kWPEditorConfigURLParamAvailable;
extern NSString* const kWPEditorConfigURLParamEnabled;

@interface WPPostViewController : WPEditorViewController <UINavigationControllerDelegate, WPEditorViewControllerDelegate, UIViewControllerRestoration>

/*
 EditPostViewController instance will execute the onClose callback, if provided, whenever the UI is dismissed.
 */
typedef void (^WPPostViewCompletionHandler)(BOOL saved);
@property (nullable, nonatomic, copy, readwrite) WPPostViewCompletionHandler onClose;

#pragma mark - Properties: Post

/**
 *  @brief      Whether this VC owns the post or not.
 *  @details    This is set to YES when this VC is initialized with one of the draft post creation
 *              initializers.  It means this VC will delete the post objects if changes are
 *              discarded by the user.
 */
@property (nonatomic, assign, readonly) BOOL ownsPost;

/**
 *  @brief      The post that's being displayed by this VC.
 */
@property (nonatomic, strong) AbstractPost *post;

/**
 *  @brief      Whether the editor should open directly to the media picker.
 */
@property (nonatomic) BOOL isOpenedDirectlyForPhotoPost;

#pragma mark - Properties: Misc

@property (readonly) BOOL hasChanges;

#pragma mark - Initializers

- (instancetype)initWithDraftForLastUsedBlogAndPhotoPost;

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

#pragma mark - Misc methods

- (void)didSaveNewPost;

@end

NS_ASSUME_NONNULL_END
