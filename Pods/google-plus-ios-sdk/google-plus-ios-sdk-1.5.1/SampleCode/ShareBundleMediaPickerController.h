#import <UIKit/UIKit.h>

// Protocol for delegates of the |ShareBundleMediaPickerController| class.
@protocol ShareBundleMediaPickerControllerDelegate

// This delegate method is called if an image is chosen.
- (void)selectedImage:(UIImage *)image;

// This delegate method is called if a video is chosen.
- (void)selectedVideo:(NSURL *)videoURL;

@end

// Table view that allows a user to select a media element from a small list of resources
// bundled with the application.
@interface ShareBundleMediaPickerController : UITableViewController

// Delegate receives a method call when the picker finishes selecting a media element.
@property(nonatomic, weak) id<ShareBundleMediaPickerControllerDelegate> delegate;

@end
