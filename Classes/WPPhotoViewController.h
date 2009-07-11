#import <UIKit/UIKit.h>

@class WPPhotosListViewController;

@interface WPPhotoViewController : UIViewController {
    IBOutlet UIImageView *imageView;
    IBOutlet UIBarButtonItem *previousImageButtonItem;
    IBOutlet UIBarButtonItem *nextImageButtonItem;
    IBOutlet UIBarButtonItem *trashImageButtonItem;
    IBOutlet UIBarButtonItem *titleButtonItem;

    WPPhotosListViewController *photosListViewController;
    int currentPhotoIndex;
}

@property (nonatomic, assign) int currentPhotoIndex;
@property (nonatomic, assign) WPPhotosListViewController *photosListViewController;

- (IBAction)previousImage:(id)sender;
- (IBAction)nextImage:(id)sender;
- (IBAction)deleteImage:(id)sender;
- (IBAction)cancel:(id)sender;

@end
