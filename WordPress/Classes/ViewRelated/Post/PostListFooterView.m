#import "PostListFooterView.h"
#import <WordPress-iOS-Shared/WPStyleGuide.h>

@interface PostListFooterView()

@property (nonatomic, strong) IBOutlet UIView *bannerView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityView;

@end

@implementation PostListFooterView

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.backgroundColor = [WPStyleGuide greyLighten30];
    self.bannerView.backgroundColor = [WPStyleGuide greyLighten30];
}

- (void)showSpinner:(BOOL)show
{
    if (show) {
        [self.activityView startAnimating];
    } else {
        [self.activityView stopAnimating];
    }
    self.bannerView.hidden = show;
}

@end
