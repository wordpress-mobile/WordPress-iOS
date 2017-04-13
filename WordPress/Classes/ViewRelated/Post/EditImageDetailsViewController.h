#import <UIKit/UIKit.h>

@class WPImageMeta;
@class AbstractPost;
@class Media;

@protocol EditImageDetailsViewControllerDelegate;

@interface EditImageDetailsViewController : UITableViewController

@property (nonatomic) WPImageMeta *imageDetails;
@property (nonatomic) AbstractPost *post;
@property (nonatomic, weak) id<EditImageDetailsViewControllerDelegate>delegate;

+ (instancetype)controllerForDetails:(WPImageMeta *)details
                               media:(Media *)media
                             forPost:(AbstractPost *)post;

@end

@protocol EditImageDetailsViewControllerDelegate <NSObject>
- (void)editImageDetailsViewController:(EditImageDetailsViewController *)controller didFinishEditingImageDetails:(WPImageMeta *)imageMeta;
@end
