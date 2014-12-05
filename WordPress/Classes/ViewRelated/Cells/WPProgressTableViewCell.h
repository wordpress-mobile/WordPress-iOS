#import "WPTableViewCell.h"

/**
 The corresponding value is an UIImage instance representing the work being done
 */
extern NSString * const WPProgressImageThumbnailKey;

@interface WPProgressTableViewCell : WPTableViewCell

- (void) setProgress:(NSProgress *)progress;

@end
