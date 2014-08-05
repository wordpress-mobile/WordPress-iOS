#import "WPRichTextVideoControl.h"

@interface WPRichTextVideoControl()
@property (nonatomic, strong) UIImageView *playView;
@end

@implementation WPRichTextVideoControl

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        _playView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"video_play"]];
        _playView.contentMode = UIViewContentModeCenter;
        [self addSubview:_playView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _playView.center = CGPointMake(round(CGRectGetMidX(self.bounds)), round(CGRectGetMidY(self.bounds)));
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (highlighted) {
        self.alpha = 0.8;
    } else {
        self.alpha = 1.0;
    }
}

@end
