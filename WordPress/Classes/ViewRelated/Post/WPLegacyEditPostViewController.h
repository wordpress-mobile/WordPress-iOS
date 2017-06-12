#import <UIKit/UIKit.h>
#import <WordPressEditor/WPLegacyEditorViewController.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, EditPostViewControllerMode) {
    EditPostViewControllerModeNewPost,
    EditPostViewControllerModeEditPost
};


@class AbstractPost;

@interface WPLegacyEditPostViewController : WPLegacyEditorViewController
<UINavigationControllerDelegate, WPLegacyEditorViewControllerDelegate, UIViewControllerRestoration>

/*
 EditPostViewController instance will execute the onClose callback, if provided, whenever the UI is dismissed.
 */
typedef void (^WPLegacyEditPostCompletionHandler)(BOOL changesSaved);
@property (nullable, nonatomic, copy, readwrite) WPLegacyEditPostCompletionHandler onClose;
@property (nonatomic, strong, readonly) AbstractPost *post;
@property (nonatomic, assign, readonly) EditPostViewControllerMode editMode;
/*
 Initialize the editor with the specified post.
 @param post The post to edit.
 */
- (id)initWithPost:(AbstractPost *)post;

/*
 Compose a new post with the last used blog.
 */
- (id)initWithDraftForLastUsedBlog;

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
- (id)initWithTitle:(nullable NSString *)title
         andContent:(nullable NSString *)content
            andTags:(nullable NSString *)tags
           andImage:(nullable NSString *)image;


@end

NS_ASSUME_NONNULL_END
