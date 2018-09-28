#import "PostListFooterView.h"
#import <WordPressShared/WPStyleGuide.h>

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
