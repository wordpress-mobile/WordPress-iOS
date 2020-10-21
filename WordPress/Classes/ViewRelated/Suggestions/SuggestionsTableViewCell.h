#import <UIKit/UIKit.h>

extern NSInteger const SuggestionsTableViewCellIconSize;

@interface SuggestionsTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, assign) NSInteger imageDownloadHash;

@end
