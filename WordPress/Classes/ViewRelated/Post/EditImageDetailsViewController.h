#import <UIKit/UIKit.h>

@class WPImageMeta;
@class AbstractPost;
@protocol EditImageDetailsViewControllerDelegate;

@interface EditImageDetailsViewController : UITableViewController

@property (nonatomic) WPImageMeta *imageDetails;
@property (nonatomic) AbstractPost *post;
@property (nonatomic, weak) id<EditImageDetailsViewControllerDelegate>delegate;

+ (instancetype)controllerForDetails:(WPImageMeta *)details forPost:(AbstractPost *)post;

@end

@protocol EditImageDetailsViewControllerDelegate <NSObject>
- (void)editImageDetailsViewController:(EditImageDetailsViewController *)controller didFinishEditingImageDetails:(WPImageMeta *)imageMeta;
@end