#import "RestorePostTableViewCell.h"
#import "WPStyleGuide+Posts.h"

@interface RestorePostTableViewCell()

@property (nonatomic, strong) IBOutlet UIView *innerContentView;
@property (nonatomic, strong) IBOutlet UIView *shadowView;
@property (nonatomic, strong) IBOutlet UIView *postContentView;
@property (nonatomic, strong) IBOutlet UILabel *restoreLabel;
@property (nonatomic, strong) IBOutlet UIButton *restoreButton;
@property (nonatomic, weak) id<WPPostContentViewProvider> contentProvider;

@end

@implementation RestorePostTableViewCell

@synthesize delegate;

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

#pragma mark - Accessors

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    self.innerContentView.backgroundColor = backgroundColor;
}


#pragma mark - Configuration

- (void)applyStyles
{
    [WPStyleGuide applyPostCardStyle:self];
    [WPStyleGuide applyRestorePostLabelStyle:self.restoreLabel];
    [WPStyleGuide applyRestorePostButtonStyle:self.restoreButton];
    self.shadowView.backgroundColor = [WPStyleGuide postCardBorderColor];
}

- (void)configureView
{
    self.restoreLabel.text = NSLocalizedString(@"Post moved to trash.", @"A short message explaining that a post was moved to the trash bin.");
    NSString *buttonTitle = NSLocalizedString(@"Undo", @"The title of an 'undo' button. Tapping the button moves a trashed post out of the trash folder.");
    [self.restoreButton setTitle:buttonTitle forState:UIControlStateNormal];
}

- (void)configureCell:(id<WPPostContentViewProvider>)contentProvider
{
    self.contentProvider = contentProvider;
}

- (void)configureCell:(id<WPPostContentViewProvider>)contentProvider layoutOnly:(BOOL)layoutOnly
{
    [self configureCell:contentProvider];
}


#pragma mark - Actions

- (IBAction)restorePostAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(cell:receivedRestoreActionForProvider:)]) {
        [self.delegate cell:self receivedRestoreActionForProvider:self.contentProvider];
    }
}

@end
