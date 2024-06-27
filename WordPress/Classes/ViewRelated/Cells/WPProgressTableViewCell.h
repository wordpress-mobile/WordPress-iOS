@import UIKit;
@import WordPressSharedObjC;

@class WPTableViewCell;

/**
 The corresponding value is an UIImage instance representing the work being done
 */
extern NSProgressUserInfoKey const WPProgressImageThumbnailKey;

@interface WPProgressTableViewCell : WPTableViewCell

- (void) setProgress:(NSProgress *)progress;

@end
