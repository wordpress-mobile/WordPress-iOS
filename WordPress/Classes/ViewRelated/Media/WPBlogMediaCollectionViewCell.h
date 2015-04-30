
/**
    Borrowed from WPMediaPicker project -- anticipating unification once it replaces CTAssetsPickerController
 */

@import UIKit;

@interface WPBlogMediaCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImage * image;
@property (nonatomic, assign) NSInteger position;

- (void)setCaption:(NSString *) caption;

@end
