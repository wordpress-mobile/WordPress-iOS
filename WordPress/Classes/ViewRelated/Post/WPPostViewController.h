#import <UIKit/UIKit.h>
#import <WordPress-iOS-Editor/WPEditorViewController.h>
#import "CTAssetsPickerController.h"

@class AbstractPost;

typedef enum
{
	kWPPostViewControllerModePreview = kWPEditorViewControllerModePreview,
	kWPPostViewControllerModeEdit = kWPEditorViewControllerModeEdit,
}
WPPostViewControllerMode;

extern NSString *const WPEditorNavigationRestorationID;
extern NSString *const kUserDefaultsNewEditorEnabled;

@interface WPPostViewController : WPEditorViewController <UINavigationControllerDelegate, CTAssetsPickerControllerDelegate, WPEditorViewControllerDelegate>

/*
 EditPostViewController instance will execute the onClose callback, if provided, whenever the UI is dismissed.
 */
typedef void (^EditPostCompletionHandler)(void);
@property (nonatomic, copy, readwrite) EditPostCompletionHandler onClose;

#pragma mark - Initializers

/*
 Compose a new post with the last used blog.
 */
- (id)initWithDraftForLastUsedBlog;

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


@end
