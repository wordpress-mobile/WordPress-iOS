#import "PostListFooterView.h"
#import "WordPress-Swift.h"

@import WordPressShared;

@interface PostListFooterView()

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityView;

@end

@implementation PostListFooterView

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.backgroundColor = [UIColor clearColor];
}

- (void)showSpinner:(BOOL)show
{
    if (show) {
        [self.activityView startAnimating];
    } else {
        [self.activityView stopAnimating];
    }
}

@end
