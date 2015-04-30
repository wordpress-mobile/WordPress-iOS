
/**
 Borrowed from WPMediaPicker project -- anticipating unification once it replaces CTAssetsPickerController
 */

@import UIKit;

@class Blog;
@class Media;

@protocol WPBlogMediaPickerViewControllerDelegate;

@interface WPBlogMediaPickerViewController : UIViewController

@property (nonatomic, weak) id<WPBlogMediaPickerViewControllerDelegate> delegate;

/**
 The blog whose media library images will be displayed
 */
@property (nonatomic, weak) Blog *blog;

/**
 If set the picker will show the most recent items on the top left. If not set it will show on the bottom right. Either way it will always scroll to the most recent item when showing the picker.
 */
@property (nonatomic, assign) BOOL showMostRecentFirst;

@end

/**
 *  The `WPBlogMediaPickerViewControllerDelegate` protocol defines methods that allow you to to interact with the media picker interface
 *  and manage the selection and highlighting of media in the picker.
 *
 *  The methods of this protocol notify your delegate when the user selects, finish picking media, or cancels the picker operation.
 *
 *  The delegate methods are responsible for dismissing the picker when the operation completes.
 *  To dismiss the picker, call the `dismissViewControllerAnimated:completion:` method of the presenting controller
 *  responsible for displaying `WPBlogMediaPickerController` object.
 *
 */
@protocol WPBlogMediaPickerViewControllerDelegate <NSObject>


/**
 *  @name Closing the Picker
 */

/**
 *  Tells the delegate that the user finish picking photos or videos.
 *
 *  @param picker The controller object managing the media picker interface.
 *  @param media An array containing picked Media objects.
 *
 */
- (void)blogMediaPickerController:(WPBlogMediaPickerViewController *)picker didFinishPickingMedia:(NSArray *)media;

@optional

/**
 *  Tells the delegate that the user cancelled the pick operation.
 *
 *  @param picker The controller object managing the media picker interface.
 *
 */
- (void)blogMediaPickerControllerDidCancel:(WPBlogMediaPickerViewController *)picker;

/**
 *  @name Managing the Selected Media
 */

/**
 *  Asks the delegate if the specified media should be selected.
 *
 *  @param picker The controller object managing the media picker interface.
 *  @param media  The media to be selected.
 *
 *  @return `YES` if the media should be selected or `NO` if it should not.
 *
 */
- (BOOL)blogMediaPickerController:(WPBlogMediaPickerViewController *)picker shouldSelectMedia:(Media *)media;

/**
 *  Tells the delegate that the media was selected.
 *
 *  @param picker The controller object managing the media picker interface.
 *  @param media  The media that was selected.
 *
 */
- (void)blogMediaPickerController:(WPBlogMediaPickerViewController *)picker didSelectMedia:(Media *)media;

/**
 *  Asks the delegate if the specified media should be deselected.
 *
 *  @param picker The controller object managing the media picker interface.
 *  @param media  The media to be deselected.
 *
 *  @return `YES` if the media should be deselected or `NO` if it should not.
 *
 *  @see blogMediaPickerController:shouldSelectMedia:
 */
- (BOOL)blogMediaPickerController:(WPBlogMediaPickerViewController *)picker shouldDeselectMedia:(Media *)media;

/**
 *  Tells the delegate that the item at the specified path was deselected.
 *
 *  @param picker The controller object managing the media picker interface.
 *  @param media  The media that was deselected.
 *
 */
- (void)blogMediaPickerController:(WPBlogMediaPickerViewController *)picker didDeselectMedia:(Media *)media;

@end