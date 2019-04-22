#import <UIKit/UIKit.h>

@class AbstractPost;

NS_ASSUME_NONNULL_BEGIN

@interface PostPreviewViewController : UIViewController <UIWebViewDelegate>

/*
 EditPostViewController instance will execute the onClose callback, if provided, whenever the UI is dismissed.
 */
typedef void (^PostPreviewViewCompletionHandler)(void);
@property (nonatomic, copy, readwrite, nullable) PostPreviewViewCompletionHandler onClose;
@property (nonatomic, strong, readonly) AbstractPost *apost;

- (instancetype)initWithPost:(AbstractPost *)aPost;
- (instancetype)initWithPost:(AbstractPost *)aPost previewURL:(NSString *)previewURLString;

@end

NS_ASSUME_NONNULL_END
