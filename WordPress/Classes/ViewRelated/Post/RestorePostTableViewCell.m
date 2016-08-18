#import "RestorePostTableViewCell.h"
#import "InteractivePostViewDelegate.h"
#import "WordPress-Swift.h"
#import "WPStyleGuide+Posts.h"

@interface RestorePostTableViewCell()

@property (nonatomic, weak) id<InteractivePostViewDelegate> delegate;
@property (nonatomic, strong) IBOutlet UIView *postContentView;
@property (nonatomic, strong) IBOutlet UILabel *restoreLabel;
@property (nonatomic, strong) IBOutlet UIButton *restoreButton;
@property (nonatomic, strong) AbstractPost *post;

@end

@implementation RestorePostTableViewCell

#pragma mark - Life Cycle

- (void)awakeFromNib {
    [super awakeFromNib];

    [self configureView];
    [self applyStyles];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    // Don't respond to taps in margins.
    if (!CGRectContainsPoint(self.postContentView.frame, point)) {
        return nil;
    }
    return [super hitTest:point withEvent:event];
}

#pragma mark - Configuration

- (void)applyStyles
{
    [WPStyleGuide applyPostCardStyle:self];
    [WPStyleGuide applyRestorePostLabelStyle:self.restoreLabel];
    [WPStyleGuide applyRestorePostButtonStyle:self.restoreButton];

    self.postContentView.layer.borderColor = [[WPStyleGuide postCardBorderColor] CGColor];
    self.postContentView.layer.borderWidth = 1.0;
}

- (void)configureView
{
    self.restoreLabel.text = NSLocalizedString(@"Post moved to trash.", @"A short message explaining that a post was moved to the trash bin.");
    NSString *buttonTitle = NSLocalizedString(@"Undo", @"The title of an 'undo' button. Tapping the button moves a trashed post out of the trash folder.");
    [self.restoreButton setTitle:buttonTitle forState:UIControlStateNormal];
}

#pragma mark - ConfigurablePostView

- (void)configureWithPost:(Post *)post
{
    self.post = post;
}

#pragma mark - InteractivePostView

- (void)setInteractionDelegate:(id<InteractivePostViewDelegate>)delegate
{
    self.delegate = delegate;
}


#pragma mark - Actions

- (IBAction)restorePostAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(cell:handleRestorePost:)]) {
        [self.delegate cell:self handleRestorePost:self.post];
    }
}

@end
