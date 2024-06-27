@import UIKit;
@import WordPressShared;

@interface WPTableViewActivityCell : WPTableViewCell {}

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) IBOutlet UIView *viewForBackground;

@end
