#import "PostListFooterView.h"
#import <WordPressShared/WPStyleGuide.h>
#import "WordPress-Swift.h"

@interface PostListFooterView()

@property (nonatomic, strong) IBOutlet UIView *bannerView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityView;

@end

@implementation PostListFooterView

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.backgroundColor = [UIColor clearColor];
    self.bannerView.backgroundColor = [UIColor murielNeutral0];
    self.bannerView.hidden = YES;
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
