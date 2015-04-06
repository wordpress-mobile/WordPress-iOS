
/**
 Borrowed from WPMediaPicker project -- anticipating unification once it replaces CTAssetsPickerController
 */

@import UIKit;

@class Blog;

@interface WPBlogMediaCollectionViewController : UICollectionViewController

/**
 If set the picker will show the most recent items on the top left. If not set it will show on the bottom right. Either way it will always scroll to the most recent item when showing the picker.
 */
@property (nonatomic, assign) BOOL showMostRecentFirst;

/**
 The blog whose media library images will be displayed
 */
@property (nonatomic, weak) Blog *blog;

/**
 Displayed as picker title and as option along with "Local Media" when post editor image insertion tapped
 */
+ (NSString *)title;

@end


